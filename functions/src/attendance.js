const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { Timestamp, FieldValue, FieldPath } = require("firebase-admin/firestore");
const A = require("./access");
const attendanceType = (t) =>
  ({ attendance_khedma: "khedma", attendance_qoddas: "qoddas" })[t];
function taskDay(task) {
  const day = A.day(task.dueDate);
  if (task.attendanceDay && task.attendanceDay !== day)
    A.fail(
      "failed-precondition",
      "Task attendance day disagrees with stored instant",
    );
  return task.attendanceDay || day;
}
function taskAccess(actor, actorUid, task, grade, date, type) {
  if (
    !task ||
    task.isCompleted === true ||
    ["cancelled", "inactive"].includes(task.status) ||
    !attendanceType(task.type) ||
    attendanceType(task.type) !== type ||
    task.grade !== grade ||
    !task.dueDate ||
    taskDay(task) !== A.day(date)
  )
    A.fail(
      "permission-denied",
      "Active attendance task, scope and date must match",
    );
  if (
    !A.authorize(actor, "finalizeAttendance", { grade }) &&
    !(
      actor.role === "servant" &&
      (task.assignedKhademId || task.assignedToId) === actorUid &&
      (grade === "all" || actor.grade === grade)
    )
  )
    A.fail("permission-denied", "Attendance task access denied");
}
function validateSession(session, grade, date, type, taskId) {
  if (!session) return;
  if (
    session.grade !== grade ||
    A.day(session.date) !== A.day(date) ||
    session.type !== type ||
    (session.taskId && taskId && session.taskId !== taskId)
  )
    A.fail("invalid-argument", "Session metadata mismatch");
  if (session.status === "finalized")
    A.fail("failed-precondition", "Finalized attendance is immutable");
}
// Stored root/grade metadata is authoritative when a caller omits taskId.
function effectiveTaskId(
  requestedId,
  sessions,
  mismatchCode = "invalid-argument",
) {
  const storedIds = [
    ...new Set(
      sessions
        .filter(Boolean)
        .map((s) => s.taskId)
        .filter(Boolean),
    ),
  ];
  if (storedIds.length > 1)
    A.fail(
      "failed-precondition",
      "Stored attendance task attachments disagree",
    );
  const storedId = storedIds[0] || null;
  if (requestedId && storedId && requestedId !== storedId)
    A.fail(mismatchCode, "Task does not own this session");
  return requestedId || storedId;
}
// Establish task ownership before Firestore listeners read missing cross-grade parts.
// This is also the recovery path for tasks created before this contract existed.
const initializeAttendance = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    taskId = A.id(data?.taskId),
    sessionId = A.id(data.sessionId),
    grade = data.grade;
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid);
    const taskSnap = await tx.get(db.doc("tasks/" + taskId));
    const task = taskSnap.exists ? taskSnap.data() : null;
    if (
      !task?.dueDate ||
      !attendanceType(task.type) ||
      task.grade !== grade ||
      ["cancelled", "inactive"].includes(task.status)
    )
      A.fail("permission-denied", "Attendance task required");
    const type = attendanceType(task.type),
      day = taskDay(task);
    if (sessionId !== day + "_" + type + "_" + grade)
      A.fail("invalid-argument", "Session must match trusted task day and scope");
    const rootRef = db.doc("attendance/" + sessionId),
      root = await tx.get(rootRef),
      refs = (grade === "all" ? A.GRADES : [grade]).map((g) =>
        rootRef.collection("grades").doc(g),
      );
    const parts = [];
    for (const ref of refs) parts.push(await tx.get(ref));
    const sessions = [
      root.exists ? root.data() : null,
      ...parts.map((p) => (p.exists ? p.data() : null)),
    ];
    effectiveTaskId(taskId, sessions);
    for (let i = 0; i < sessions.length; i++) {
      const session = sessions[i];
      if (
        session &&
        (session.grade !== (i === 0 ? grade : refs[i - 1].id) ||
          session.type !== type ||
          A.day(session.date) !== day)
      )
        A.fail("invalid-argument", "Stored session metadata mismatch");
    }
    if (task.isCompleted || task.status === "completed") {
      if (
        !A.authorize(actor, "finalizeAttendance", { grade }) ||
        sessions.some((s) => !s || s.status !== "finalized")
      )
        A.fail(
          "permission-denied",
          "Completed attendance requires existing finalized scope and administrator",
        );
      return { success: true, sessionId, status: "finalized" };
    }
    taskAccess(actor, actorUid, task, grade, task.dueDate, type);
    if (sessions.some((s) => s?.status === "finalized"))
      A.fail("failed-precondition", "Finalized session cannot be initialized as draft");
    const base = {
      sessionId,
      date: Timestamp.fromDate(new Date(day + "T00:00:00Z")),
      type,
      status: "draft",
      taskId,
      updatedAt: A.stamp(),
    };
    for (let i = 0; i < refs.length; i++) {
      if (!parts[i].exists)
        tx.create(refs[i], { ...base, grade: refs[i].id, attendedMakhdomIds: [] });
      else if (!parts[i].data().taskId) tx.update(refs[i], { taskId });
    }
    if (!root.exists)
      tx.create(rootRef, {
        ...base,
        grade,
        attendedMakhdomIds: [
          ...new Set(parts.flatMap((p) =>
            p.exists ? p.data().attendedMakhdomIds || [] : [],
          )),
        ].sort(),
      });
    else if (!root.data().taskId) tx.update(rootRef, { taskId });
    return { success: true, sessionId, status: "draft" };
  });
});
const setAttendancePresence = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    sessionId = A.id(data?.sessionId),
    childId = A.id(data.makhdomId),
    grade = data.grade,
    type = data.type,
    date = A.date(data.date);
  if (
    ![...A.GRADES, "all"].includes(grade) ||
    !["khedma", "qoddas"].includes(type) ||
    (grade === "all" && type !== "qoddas") ||
    typeof data.isPresent !== "boolean"
  )
    A.fail("invalid-argument", "Invalid presence fields");
  if (sessionId !== A.day(date) + "_" + type + "_" + grade)
    A.fail("invalid-argument", "Session ID must match date, type and scope");
  const opRef = A.operation(
    db,
    actorUid,
    "setAttendancePresence",
    data.operationId || db.collection("operations").doc().id,
  );
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid),
      childSnap = await tx.get(db.doc("makhdomeen/" + childId));
    if (!childSnap.exists) A.fail("not-found", "Child not found");
    const child = childSnap.data();
    if (
      child.active === false ||
      !A.GRADES.includes(child.grade) ||
      (grade !== "all" && child.grade !== grade)
    )
      A.fail("permission-denied", "Child grade or active status mismatch");

    const rootRef = db.doc("attendance/" + sessionId),
      root = await tx.get(rootRef),
      partRefs = (grade === "all" ? A.GRADES : [grade]).map((g) =>
        rootRef.collection("grades").doc(g),
      ),
      parts = [];
    for (const ref of partRefs) parts.push(await tx.get(ref));
    const attachedId = effectiveTaskId(data.taskId, [
      root.exists ? root.data() : null,
      ...parts.map((p) => (p.exists ? p.data() : null)),
    ]);
    validateSession(
      root.exists ? root.data() : null,
      grade,
      date,
      type,
      attachedId,
    );
    for (let i = 0; i < parts.length; i++)
      validateSession(
        parts[i].exists ? parts[i].data() : null,
        partRefs[i].id,
        date,
        type,
        attachedId,
      );
    const taskSnap = attachedId
      ? await tx.get(db.doc("tasks/" + A.id(attachedId)))
      : null;
    const task = taskSnap?.exists ? taskSnap.data() : null;
    if (attachedId) taskAccess(actor, actorUid, task, grade, date, type);
    else if (!A.authorize(actor, "finalizeAttendance", { grade }))
      A.fail(
        "permission-denied",
        "Administrative scope or assigned task required",
      );
    const op = await tx.get(opRef);
    if (op.exists) return { ...op.data().result, idempotent: true };
    const base = {
      sessionId,
      date: Timestamp.fromDate(new Date(A.day(date) + "T00:00:00Z")),
      type,
      status: "draft",
      taskId: attachedId || null,
      updatedAt: A.stamp(),
    };
    const byGrade = {};
    for (let i = 0; i < parts.length; i++) {
      const g = partRefs[i].id,
        ids = new Set(
          parts[i].exists ? parts[i].data().attendedMakhdomIds || [] : [],
        );
      if (g === child.grade) {
        if (data.isPresent) ids.add(childId);
        else ids.delete(childId);
      }
      byGrade[g] = [...ids].sort();
    }
    for (let i = 0; i < partRefs.length; i++)
      tx.set(
        partRefs[i],
        {
          ...base,
          grade: partRefs[i].id,
          attendedMakhdomIds: byGrade[partRefs[i].id],
        },
        { merge: true },
      );
    tx.set(
      rootRef,
      {
        ...base,
        grade,
        attendedMakhdomIds: Object.values(byGrade).flat().sort(),
      },
      { merge: true },
    );
    const result = {
      success: true,
      sessionId,
      grade: child.grade,
      isPresent: data.isPresent,
    };
    tx.create(opRef, { result, createdAt: A.stamp() });
    return result;
  });
});
async function executeFinalizeAttendance({
  db,
  actorUid,
  sessionId,
  grade,
  taskId,
}) {
  A.id(sessionId, "sessionId");
  if (![...A.GRADES, "all"].includes(grade))
    A.fail("invalid-argument", "Valid grade required");
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid),
      rootRef = db.doc("attendance/" + sessionId),
      root = await tx.get(rootRef),
      refs = (grade === "all" ? A.GRADES : [grade]).map((g) =>
        rootRef.collection("grades").doc(g),
      ),
      parts = [];
    for (const ref of refs) parts.push(await tx.get(ref));
    let session = root.exists
      ? root.data()
      : parts.find((p) => p.exists)?.data();
    const attachedId = effectiveTaskId(
      taskId,
      [
        root.exists ? root.data() : null,
        ...parts.map((p) => (p.exists ? p.data() : null)),
      ],
      "permission-denied",
    );
    const taskRef = attachedId ? db.doc("tasks/" + A.id(attachedId)) : null;
    const taskSnap = taskRef ? await tx.get(taskRef) : null;
    const task = taskSnap?.exists ? taskSnap.data() : null;
    if (!session) {
      if (!attachedId) A.fail("not-found", "Session not found");
      if (!task?.dueDate || !attendanceType(task.type))
        A.fail("permission-denied", "Active attendance task required");
      const type = attendanceType(task.type);
      taskAccess(actor, actorUid, task, grade, task.dueDate, type);
      if (sessionId !== taskDay(task) + "_" + type + "_" + grade)
        A.fail(
          "invalid-argument",
          "Session ID must match trusted task date, type and scope",
        );
      // No draft/presence is required to finalize a legitimate zero-attendee task.
      session = {
        sessionId,
        grade,
        date: Timestamp.fromDate(new Date(taskDay(task) + "T00:00:00Z")),
        type,
        taskId: attachedId,
        status: "draft",
      };
    }
    if (session.grade !== grade)
      A.fail("invalid-argument", "Session scope mismatch");
    if (session.status === "finalized") {
      if (
        !A.authorize(actor, "finalizeAttendance", { grade }) &&
        !(
          actor.role === "servant" &&
          task &&
          (task.assignedKhademId || task.assignedToId) === actorUid &&
          task.grade === grade &&
          attendanceType(task.type) === session.type
        )
      )
        A.fail("permission-denied", "Session access denied");
      return {
        success: true,
        sessionId,
        grade,
        status: "finalized",
        idempotent: true,
      };
    }
    if (attachedId)
      taskAccess(actor, actorUid, task, grade, session.date, session.type);
    else if (!A.authorize(actor, "finalizeAttendance", { grade }))
      A.fail(
        "permission-denied",
        "Administrative scope or assigned task required",
      );
    const final = {
      status: "finalized",
      finalizedAt: A.stamp(),
      finalizedByKhademId: actorUid,
    };
    const ids = [];
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i].exists
        ? parts[i].data()
        : {
            sessionId,
            date: session.date,
            type: session.type,
            grade: refs[i].id,
            attendedMakhdomIds: [],
            taskId: attachedId || null,
          };
      if (
        part.grade !== refs[i].id ||
        part.type !== session.type ||
        A.day(part.date) !== A.day(session.date)
      )
        A.fail("invalid-argument", "Grade session metadata mismatch");
      ids.push(...(part.attendedMakhdomIds || []));
    }
    for (let i = 0; i < parts.length; i++)
      tx.set(
        refs[i],
        {
          sessionId,
          date: session.date,
          type: session.type,
          grade: refs[i].id,
          taskId: attachedId || null,
          attendedMakhdomIds: parts[i].exists
            ? parts[i].data().attendedMakhdomIds || []
            : [],
          ...final,
        },
        { merge: true },
      );
    tx.set(
      rootRef,
      {
        sessionId,
        date: session.date,
        type: session.type,
        grade,
        taskId: attachedId || null,
        attendedMakhdomIds: [...new Set(ids)].sort(),
        ...final,
      },
      { merge: true },
    );
    if (taskRef)
      tx.update(taskRef, {
        isCompleted: true,
        status: "completed",
        completedAt: A.stamp(),
        completedById: actorUid,
      });
    return { success: true, sessionId, grade, status: "finalized" };
  });
}
const finalizeAttendance = functions.https.onCall(async (data, context) =>
  executeFinalizeAttendance({
    db: admin.firestore(),
    actorUid: A.uid(context, data?.expectedUid),
    sessionId: data?.sessionId,
    grade: data?.grade,
    taskId: data?.taskId,
  }),
);
// A session is reopened as one stored scope. An all-grade root requires a
// stage administrator; grade administrators cannot reopen an isolated part.
const reopenAttendance = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    sessionId = A.id(data?.sessionId, "sessionId"),
    grade = data.grade,
    operationId = A.id(data.operationId, "operationId");
  if (
    ![...A.GRADES, "all"].includes(grade) ||
    typeof data.reason !== "string" ||
    !data.reason.trim() ||
    data.reason.trim().length > 500
  )
    A.fail("invalid-argument", "Valid grade and reason required");
  const reason = data.reason.trim(),
    opRef = A.operation(db, actorUid, "reopenAttendance", operationId);
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid),
      rootRef = db.doc("attendance/" + sessionId),
      rootSnap = await tx.get(rootRef);
    if (!rootSnap.exists) A.fail("not-found", "Session not found");
    const root = rootSnap.data();
    if (
      root.grade !== grade ||
      !A.authorize(actor, "finalizeAttendance", { grade: root.grade })
    )
      A.fail("permission-denied", "Administrative stored scope required");
    const op = await tx.get(opRef);
    if (op.exists) {
      if (
        op.data().sessionId !== sessionId ||
        op.data().grade !== grade ||
        op.data().reason !== reason
      )
        A.fail("invalid-argument", "Operation payload changed");
      if (op.data().taskId !== (root.taskId || null))
        A.fail("failed-precondition", "Stored session task link changed");
      return { ...op.data().result, idempotent: true };
    }
    if (
      root.status !== "finalized" ||
      !["khedma", "qoddas"].includes(root.type) ||
      (grade === "all" && root.type !== "qoddas") ||
      sessionId !== A.day(root.date) + "_" + root.type + "_" + grade
    )
      A.fail("failed-precondition", "Canonical finalized session required");
    const refs = (grade === "all" ? A.GRADES : [grade]).map((g) =>
      rootRef.collection("grades").doc(g),
    );
    const parts = [];
    for (const ref of refs) {
      const snap = await tx.get(ref),
        part = snap.exists ? snap.data() : null;
      if (
        !part ||
        part.status !== "finalized" ||
        part.grade !== ref.id ||
        part.type !== root.type ||
        A.day(part.date) !== A.day(root.date) ||
        part.sessionId !== sessionId ||
        (part.taskId || null) !== (root.taskId || null)
      )
        A.fail("failed-precondition", "Finalized grade parts must match stored scope");
      parts.push(part);
    }
    const taskRef = root.taskId ? db.doc("tasks/" + A.id(root.taskId)) : null,
      taskSnap = taskRef ? await tx.get(taskRef) : null,
      task = taskSnap?.exists ? taskSnap.data() : null;
    if (
      taskRef &&
      (!task ||
        !task.isCompleted ||
        task.status !== "completed" ||
        task.grade !== grade ||
        attendanceType(task.type) !== root.type ||
        taskDay(task) !== A.day(root.date))
    )
      A.fail("failed-precondition", "Linked completed task must match session");
    const auditRef = rootRef.collection("audit").doc(opRef.id);
    tx.create(auditRef, {
      actorUid, createdAt: A.stamp(), reason, operationId, sessionId, grade,
      previousRoot: root, previousParts: parts, previousTask: task,
    });
    const draft = {
      status: "draft", updatedAt: A.stamp(),
      finalizedAt: FieldValue.delete(), finalizedByKhademId: FieldValue.delete(),
    };
    tx.update(rootRef, draft);
    for (const ref of refs) tx.update(ref, draft);
    if (taskRef)
      tx.update(taskRef, {
        isCompleted: false, status: "active",
        completedAt: FieldValue.delete(), completedById: FieldValue.delete(),
      });
    const result = { success: true, sessionId, grade, status: "draft", auditId: auditRef.id };
    tx.create(opRef, {
      sessionId, grade, reason, taskId: root.taskId || null, result, createdAt: A.stamp(),
    });
    return result;
  });
});
const getAttendanceRoster = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    taskId = A.id(data?.taskId),
    limit = data.limit === undefined ? 200 : data.limit;
  if (!Number.isInteger(limit) || limit < 1 || limit > 500)
    A.fail("invalid-argument", "limit must be 1 to 500");
  if (data.cursor) A.id(data.cursor, "cursor");
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid),
      taskSnap = await tx.get(db.doc("tasks/" + taskId)),
      task = taskSnap.exists ? taskSnap.data() : null;
    if (!task || !task.dueDate)
      A.fail("permission-denied", "Active attendance task required");
    taskAccess(
      actor,
      actorUid,
      task,
      task.grade,
      task.dueDate,
      attendanceType(task.type),
    );
    let query = db.collection("attendance_roster").where("active", "==", true);
    if (task.grade !== "all") query = query.where("grade", "==", task.grade);
    query = query.orderBy(FieldPath.documentId());
    if (data.cursor) query = query.startAfter(data.cursor);
    const snap = await tx.get(query.limit(limit + 1));
    const selected = snap.docs.slice(0, limit),
      rows = selected.map((s) => A.roster(s.id, s.data()));
    return {
      success: true,
      rows,
      nextCursor: snap.size > limit ? selected.at(-1).id : null,
    };
  });
});
module.exports = {
  initializeAttendance,
  setAttendancePresence,
  finalizeAttendance,
  reopenAttendance,
  executeFinalizeAttendance,
  getAttendanceRoster,
};
