const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { Timestamp, FieldValue } = require("firebase-admin/firestore");
const A = require("./access");
function comparable(value) {
  if (!value) return 0;
  return value.toMillis ? value.toMillis() : A.date(value).getTime();
}
function isVisitNewest({
  newVisitDate,
  currentLastVisitDate,
  newCreatedAt,
  currentCreatedAt,
  newId,
  currentId,
}) {
  if (!currentLastVisitDate) return true;
  const delta = comparable(newVisitDate) - comparable(currentLastVisitDate);
  if (delta) return delta > 0;
  const created = comparable(newCreatedAt) - comparable(currentCreatedAt);
  if (created) return created > 0;
  return !currentId || (newId || "") >= currentId;
}
function computeVisitMakhdomUpdates({
  isNewest,
  parsedVisitDate,
  visitId,
  cleanNotes,
}) {
  const updates = { visitCount: FieldValue.increment(1) };
  if (isNewest)
    Object.assign(updates, {
      lastVisitDate: Timestamp.fromDate(parsedVisitDate),
      lastVisitId: visitId,
      lastVisitNotes: cleanNotes || null,
    });
  return updates;
}
const recordVisit = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    makhdomId = A.id(data?.makhdomId, "makhdomId"),
    parsedVisitDate = A.date(data?.visitDate, "visitDate");
  const cleanNotes = typeof data.notes === "string" ? data.notes.trim() : null,
    visitRef = db.collection("visits").doc();
  const opRef = A.operation(
      db,
      actorUid,
      "recordVisit",
      data.operationId || visitRef.id,
    ),
    createdAt = Timestamp.now();
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid),
      childRef = db.doc("makhdomeen/" + makhdomId),
      childSnap = await tx.get(childRef);
    if (!childSnap.exists) A.fail("not-found", "Child not found");
    const child = childSnap.data();
    if (!A.childAccess(actor, actorUid, child) || child.active === false)
      A.fail("permission-denied", "Child access denied");
    const op = await tx.get(opRef);
    if (op.exists) return { ...op.data().result, idempotent: true };
    let currentCreatedAt = child.lastVisitCreatedAt;
    if (!currentCreatedAt && child.lastVisitId) {
      const latest = await tx.get(db.doc("visits/" + child.lastVisitId));
      currentCreatedAt = latest.exists ? latest.data().createdAt : null;
    }
    const newest = isVisitNewest({
      newVisitDate: parsedVisitDate,
      currentLastVisitDate: child.lastVisitDate,
      newCreatedAt: createdAt,
      currentCreatedAt,
      newId: visitRef.id,
      currentId: child.lastVisitId,
    });
    const updates = computeVisitMakhdomUpdates({
      isNewest: newest,
      parsedVisitDate,
      visitId: visitRef.id,
      cleanNotes,
    });
    if (newest) updates.lastVisitCreatedAt = createdAt;
    tx.create(visitRef, {
      makhdomId,
      makhdomName: child.fullName || "",
      grade: child.grade,
      khademId: actorUid,
      servantId: actorUid,
      khademName: actor.name || "",
      servantName: actor.name || "",
      visitDate: Timestamp.fromDate(parsedVisitDate),
      visitType: data.visitType || "home",
      notes: cleanNotes || null,
      description: cleanNotes || null,
      createdAt,
    });
    tx.update(childRef, updates);
    const result = { success: true, visitId: visitRef.id };
    tx.create(opRef, { result, createdAt: A.stamp() });
    return result;
  });
});
const updateVisitNotes = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    visitId = A.id(data?.visitId, "visitId"),
    cleanNotes = typeof data.notes === "string" ? data.notes.trim() : "";
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid),
      ref = db.doc("visits/" + visitId),
      snap = await tx.get(ref);
    if (!snap.exists) A.fail("not-found", "Visit not found");
    const visit = snap.data();
    const childRef = db.doc("makhdomeen/" + A.id(visit.makhdomId)),
      childSnap = await tx.get(childRef),
      child = childSnap.exists ? childSnap.data() : null;
    if (
      !child ||
      !A.childAccess(actor, actorUid, child) ||
      !(
        A.isStageAdmin(actor) ||
        A.isGradeAdmin(actor, child.grade) ||
        (visit.khademId || visit.servantId) === actorUid
      )
    )
      A.fail("permission-denied", "Visit access denied");
    tx.update(ref, {
      notes: cleanNotes || null,
      description: cleanNotes || null,
    });
    if (child.lastVisitId === visitId)
      tx.update(childRef, { lastVisitNotes: cleanNotes || null });
    return { success: true, visitId };
  });
});
module.exports = {
  recordVisit,
  updateVisitNotes,
  isVisitNewest,
  computeVisitMakhdomUpdates,
};
