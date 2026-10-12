const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { Timestamp, FieldValue } = require("firebase-admin/firestore");
const A = require("./access");
function calculateAssignmentDeltas(children, target) {
  const deltas = {};
  for (const c of children) {
    const prev = c?.assignedKhademId;
    if (prev && prev !== target) deltas[prev] = (deltas[prev] || 0) - 1;
    if (target && target !== prev) deltas[target] = (deltas[target] || 0) + 1;
  }
  return deltas;
}
function checkAssignmentConflicts(children, expected) {
  if (!expected || typeof expected !== "object") return null;
  for (const c of children) {
    if (
      expected[c.id] !== undefined &&
      (c.assignedKhademId || null) !== expected[c.id]
    )
      return {
        id: c.id,
        expected: expected[c.id],
        current: c.assignedKhademId || null,
      };
  }
  return null;
}
const assignMakhdoms = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore();
  if (!Array.isArray(data?.ids) || !data.ids.length || data.ids.length > 200)
    A.fail("invalid-argument", "ids must contain 1 to 200 children");
  const ids = [...new Set(data.ids.map((x) => A.id(x)))],
    targetId = data.targetKhademId ? A.id(data.targetKhademId) : null;
  if (
    !data.expectedAssignments ||
    ids.some((x) => !Object.hasOwn(data.expectedAssignments, x))
  )
    A.fail(
      "invalid-argument",
      "expectedAssignments is required for every child",
    );
  const opRef = A.operation(
    db,
    actorUid,
    "assignMakhdoms",
    data.operationId || db.collection("operations").doc().id,
  );
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid),
      op = await tx.get(opRef);
    if (op.exists) return { ...op.data().result, idempotent: true };
    const targetSnap = targetId
        ? await tx.get(db.doc("khodam/" + targetId))
        : null,
      target = targetSnap?.exists ? targetSnap.data() : null;
    if (targetId) A.active(target);
    const snaps = [];
    for (const childId of ids)
      snaps.push(await tx.get(db.doc("makhdomeen/" + childId)));
    const results = [],
      changes = [];
    for (let i = 0; i < snaps.length; i++) {
      const snap = snaps[i],
        childId = ids[i];
      if (!snap.exists) {
        results.push({ id: childId, status: "not-found" });
        continue;
      }
      const child = snap.data();
      if (
        !A.authorize(actor, "assignMakhdom", { grade: child.grade }) ||
        child.active === false ||
        (target && target.grade !== child.grade)
      )
        A.fail("permission-denied", "Assignment scope or target mismatch");
      const current = child.assignedKhademId || null;
      if (current !== data.expectedAssignments[childId]) {
        results.push({ id: childId, status: "conflict", current });
        continue;
      }
      const changed = current !== targetId;
      results.push({ id: childId, status: changed ? "assigned" : "unchanged" });
      changes.push({ snap, child, changed });
    }
    const deltas = calculateAssignmentDeltas(
        changes.filter((x) => x.changed).map((x) => x.child),
        targetId,
      ),
      khodam = [];
    for (const khademId of Object.keys(deltas)) {
      const snap = await tx.get(db.doc("khodam/" + khademId));
      if (snap.exists) khodam.push({ snap, delta: deltas[khademId] });
    }
    for (const { snap, child, changed } of changes) {
      if (changed)
        tx.update(snap.ref, {
          assignedKhademId: targetId,
          assignedKhademName: target?.name || null,
        });
      tx.set(db.doc("attendance_roster/" + snap.id), A.roster(snap.id, child));
    }
    for (const { snap, delta } of khodam)
      tx.update(snap.ref, {
        assignedCount: Math.max(
          0,
          (Number(snap.data().assignedCount) || 0) + delta,
        ),
      });
    const result = {
      success: true,
      assignedCount: changes.filter((x) => x.changed).length,
      results,
    };
    tx.create(opRef, { result, createdAt: A.stamp() });
    return result;
  });
});
const archiveMakhdom = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    childId = A.id(data?.makhdomId),
    opRef = A.operation(
      db,
      actorUid,
      "archiveMakhdom",
      data.operationId || db.collection("operations").doc().id,
    );
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid),
      ref = db.doc("makhdomeen/" + childId),
      snap = await tx.get(ref);
    if (!snap.exists) A.fail("not-found", "Child not found");
    const child = snap.data();
    if (!A.authorize(actor, "assignMakhdom", { grade: child.grade }))
      A.fail("permission-denied", "Administrative scope required");
    const op = await tx.get(opRef);
    if (op.exists) return { ...op.data().result, idempotent: true };
    const owner =
      child.assignedKhademId && child.active !== false
        ? await tx.get(db.doc("khodam/" + child.assignedKhademId))
        : null;
    tx.update(ref, {
      active: false,
      assignedKhademId: null,
      assignedKhademName: null,
      archivedAt: A.stamp(),
    });
    tx.set(
      db.doc("attendance_roster/" + childId),
      A.roster(childId, { ...child, active: false }),
    );
    if (owner?.exists)
      tx.update(owner.ref, {
        assignedCount: Math.max(
          0,
          (Number(owner.data().assignedCount) || 0) - 1,
        ),
      });
    const result = { success: true, makhdomId: childId };
    tx.create(opRef, { result, createdAt: A.stamp() });
    return result;
  });
});
exports.assignMakhdoms = assignMakhdoms;
exports.archiveMakhdom = archiveMakhdom;
exports.calculateAssignmentDeltas = calculateAssignmentDeltas;
exports.checkAssignmentConflicts = checkAssignmentConflicts;

const PROFILE_FIELDS = [
  "fullName",
  "phone",
  "fatherPhone",
  "motherPhone",
  "address",
  "area",
  "school",
  "secondaryType",
  "secondaryTypeCustomLabel",
  "homeLocationUrl",
  "isBrethrenOfLord",
  "photoUrl",
  "birthDate",
  "notes",
  "grade",
  "trackingStartDate",
];
exports.saveMakhdomProfile = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    patch = data?.patch;
  if (
    !patch ||
    typeof patch !== "object" ||
    Array.isArray(patch) ||
    Object.keys(patch).some((k) => !PROFILE_FIELDS.includes(k))
  )
    A.fail("invalid-argument", "Only profile fields can be saved");
  const childRef = data.makhdomId
    ? db.doc("makhdomeen/" + A.id(data.makhdomId))
    : db.collection("makhdomeen").doc();
  const opRef = A.operation(
    db,
    actorUid,
    "saveMakhdomProfile",
    data.operationId || db.collection("operations").doc().id,
  );
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid),
      op = await tx.get(opRef);
    if (op.exists) return { ...op.data().result, idempotent: true };
    const snap = await tx.get(childRef),
      existing = snap.exists ? snap.data() : null;
    if (data.makhdomId && !existing) A.fail("not-found", "Child not found");
    if (
      existing
        ? !A.childAccess(actor, actorUid, existing)
        : !A.authorize(actor, "manage_makhdomeen", { grade: patch.grade })
    )
      A.fail("permission-denied", "Child profile access denied");
    if (existing && patch.grade && patch.grade !== existing.grade)
      A.fail(
        "invalid-argument",
        "Grade transfer requires a separate administrative operation",
      );
    if (
      (Object.hasOwn(patch, "notes") ||
        Object.hasOwn(patch, "trackingStartDate")) &&
      !A.authorize(actor, "manage_makhdomeen", {
        grade: existing?.grade || patch.grade,
      })
    )
      A.fail("permission-denied", "Administrative profile fields");
    const normalized = {};
    for (const [k, v] of Object.entries(patch)) {
      if (["birthDate", "trackingStartDate"].includes(k))
        normalized[k] =
          v === null ? null : Timestamp.fromDate(A.date(v, k));
      else if (k === "isBrethrenOfLord") {
        if (typeof v !== "boolean")
          A.fail("invalid-argument", "Boolean required");
        normalized[k] = v;
      } else {
        if (v !== null && typeof v !== "string")
          A.fail("invalid-argument", "Text required for " + k);
        normalized[k] = typeof v === "string" ? v.trim() : null;
      }
    }
    if (Object.hasOwn(normalized,"trackingStartDate")) normalized.trackingStartEstimated=normalized.trackingStartDate===null;
    const merged = { ...(existing || {}), ...normalized };
    if (!merged.fullName || !A.GRADES.includes(merged.grade))
      A.fail("invalid-argument", "Name and valid grade required");
    if (Object.hasOwn(normalized, "notes"))
      normalized.description = normalized.notes;
    if (existing) {
      if (Object.hasOwn(normalized, "photoUrl") && normalized.photoUrl === null)
        normalized.photoUrl = FieldValue.delete();
      tx.update(childRef, normalized);
    } else
      tx.create(childRef, {
        ...normalized,
        photoUrl: normalized.photoUrl || null,
        active: true,
        visitCount: 0,
        lastVisitDate: null,
        assignedKhademId: null,
        assignedKhademName: null,
        createdAt: A.stamp(),
        createdAtKnown: true,
        trackingStartEstimated: normalized.trackingStartDate == null,
      });
    tx.set(
      db.doc("attendance_roster/" + childRef.id),
      A.roster(childRef.id, merged),
    );
    const result = { success: true, makhdomId: childRef.id };
    tx.create(opRef, { result, createdAt: A.stamp() });
    return result;
  });
});
