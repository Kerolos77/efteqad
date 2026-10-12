const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const A = require("./access");
const TYPES = [
  "attendance_khedma",
  "attendance_qoddas",
  "general",
  "visitation",
];
function buildTaskWithOutbox({
  taskId,
  operationId,
  taskData,
  authorUid,
  authorName,
}) {
  if (!taskData || typeof taskData !== "object")
    A.fail("invalid-argument", "taskData is required");
  const title = typeof taskData.title === "string" ? taskData.title.trim() : "";
  const assignedKhademId = A.id(taskData.assignedKhademId, "assignedKhademId");
  const grade = taskData.grade;
  if (!title) A.fail("invalid-argument", "Task title is required");
  if (![...A.GRADES, "all"].includes(grade))
    A.fail("invalid-argument", "grade is required and must be valid");
  const type = taskData.type || "general";
  if (
    !TYPES.includes(type) ||
    (grade === "all" && type !== "attendance_qoddas")
  )
    A.fail("invalid-argument", "Invalid task type or scope");
  const dueDate = taskData.dueDate ? A.date(taskData.dueDate, "dueDate") : null;
  if (type.startsWith("attendance_") && !dueDate)
    A.fail("invalid-argument", "Attendance date required");
  const taskDoc = {
    title,
    description:
      typeof taskData.description === "string"
        ? taskData.description.trim()
        : "",
    assignedKhademId,
    assignedKhademName: taskData.assignedKhademName || "",
    grade,
    createdById: authorUid,
    createdByName: authorName || "",
    type,
    dueDate,
    attendanceDay: dueDate ? A.day(dueDate) : null,
    isCompleted: false,
    status: "active",
  };
  const outboxId = operationId || "outbox_" + taskId;
  const outboxDoc = {
    outboxId,
    taskId,
    recipientId: assignedKhademId,
    recipientName: taskDoc.assignedKhademName,
    title: "مهمة جديدة: " + title + " 📋",
    body:
      taskDoc.description ||
      "قام " + taskDoc.createdByName + " بتكليفك بمهمة جديدة",
    type,
    state: "pending",
    status: "pending",
    templateKey: type.startsWith("attendance_") ? type : "task_assigned",
    templateArgs: { title, createdByName: taskDoc.createdByName, description: taskDoc.description },
    data: { taskId, type },
  };
  return { taskId, outboxId, taskDoc, outboxDoc };
}
const createTask = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    taskRef = db.collection("tasks").doc();
  const opRef = A.operation(
    db,
    actorUid,
    "createTask",
    data?.operationId || taskRef.id,
  );
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid);
    if (!A.authorize(actor, "createTask", { grade: data?.taskData?.grade }))
      A.fail("permission-denied", "Administrative scope required.");
    const op = await tx.get(opRef);
    if (op.exists) return { ...op.data().result, idempotent: true };
    const targetId = A.id(data?.taskData?.assignedKhademId, "assignedKhademId");
    const targetSnap = await tx.get(db.doc("khodam/" + targetId));
    const target = targetSnap.exists ? targetSnap.data() : null;
    A.active(target);
    if (data.taskData.grade !== "all" && target.grade !== data.taskData.grade)
      A.fail("permission-denied", "Target grade mismatch.");
    const built = buildTaskWithOutbox({
      taskId: taskRef.id,
      operationId: "task_" + taskRef.id,
      taskData: { ...data.taskData, assignedKhademName: target.name || "" },
      authorUid: actorUid,
      authorName: actor.name || "",
    });
    tx.create(taskRef, { ...built.taskDoc, createdAt: A.stamp() });
    tx.create(db.doc("notification_outbox/" + built.outboxId), {
      ...built.outboxDoc,
      createdAt: A.stamp(),
    });
    tx.create(db.doc("notifications/" + built.outboxId), {
      outboxId: built.outboxId,
      recipientId: targetId,
      senderId: actorUid,
      senderName: actor.name || "",
      grade: built.taskDoc.grade,
      taskId: taskRef.id,
      type: built.taskDoc.type,
      title: built.outboxDoc.title,
      body: built.outboxDoc.body,
      templateKey: built.outboxDoc.templateKey,
      templateArgs: built.outboxDoc.templateArgs,
      data: built.outboxDoc.data,
      isRead: false,
      deliveryState: "pending",
      createdAt: A.stamp(),
    });
    const result = {
      success: true,
      taskId: taskRef.id,
      outboxId: built.outboxId,
    };
    tx.create(opRef, { result, createdAt: A.stamp() });
    return result;
  });
});
function requireAdminScope(actor, grade) {
  if (!A.isStageAdmin(actor) && !A.isGradeAdmin(actor, grade))
    A.fail("permission-denied", "Administrative grade scope required.");
}
const deleteTask = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    taskId = A.id(data?.taskId, "taskId");
  const taskRef = db.doc("tasks/" + taskId),
    opRef = A.operation(
      db,
      actorUid,
      "deleteTask",
      A.id(data?.operationId, "operationId"),
    );
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid);
    const [taskSnap, operation] = await Promise.all([
      tx.get(taskRef),
      tx.get(opRef),
    ]);
    if (!taskSnap.exists) A.fail("not-found", "Task not found.");
    const task = taskSnap.data();
    requireAdminScope(actor, task.grade);
    if (operation.exists) {
      if (operation.data().result.taskId !== taskId)
        A.fail("failed-precondition", "Operation belongs to a different task.");
      return { ...operation.data().result, idempotent: true };
    }
    const attendanceKind = {
      attendance_khedma: "khedma",
      attendance_qoddas: "qoddas",
    }[task.type];
    if (attendanceKind) {
      const attached = await tx.get(
        db.collection("attendance").where("taskId", "==", taskId),
      );
      const sessions = [...attached.docs];
      if (task.dueDate) {
        const root = db.doc(
          "attendance/" +
            A.day(task.dueDate) +
            "_" +
            attendanceKind +
            "_" +
            task.grade,
        );
        const refs = [
          root,
          ...(task.grade === "all" ? A.GRADES : [task.grade]).map((grade) =>
            root.collection("grades").doc(grade),
          ),
        ];
        sessions.push(...(await Promise.all(refs.map((ref) => tx.get(ref)))));
      }
      if (
        sessions.some(
          (session) =>
            session.exists &&
            session.data().taskId === taskId &&
            session.data().status !== "finalized",
        )
      )
        A.fail(
          "failed-precondition",
          "Finalize started attendance before archiving its task.",
        );
    }
    const [outboxes, notices] = await Promise.all([
      tx.get(
        db.collection("notification_outbox").where("taskId", "==", taskId),
      ),
      tx.get(db.collection("notifications").where("taskId", "==", taskId)),
    ]);
    const cancelled = new Set();
    for (const outbox of outboxes.docs) {
      const state = outbox.data().state || outbox.data().status;
      if (
        !state ||
        ["pending", "retryable_failure", "retryable", "processing"].includes(
          state,
        )
      ) {
        cancelled.add(outbox.id);
        tx.update(outbox.ref, {
          state: "cancelled",
          status: "cancelled",
          cancelledAt: A.stamp(),
          nextAttemptAt: FieldValue.delete(),
          leaseId: FieldValue.delete(),
          leaseExpiresAt: FieldValue.delete(),
        });
      }
    }
    for (const notice of notices.docs)
      if (
        cancelled.has(notice.data().outboxId) ||
        notice.data().deliveryState === "pending"
      )
        tx.update(notice.ref, {
          deliveryState: "cancelled",
          cancelledAt: A.stamp(),
        });
    // Archival leaves the task receipt and attached attendance untouched. The attendance validator already denies cancelled tasks.
    if (task.status !== "cancelled")
      tx.update(taskRef, {
        status: "cancelled",
        archivedAt: A.stamp(),
        archivedById: actorUid,
      });
    const result = {
      success: true,
      taskId,
      status: "cancelled",
      archived: true,
    };
    tx.create(opRef, { result, createdAt: A.stamp() });
    return result;
  });
});
const sendChildAlert = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    makhdomId = A.id(data?.makhdomId, "makhdomId");
  if (data?.kind !== "absence")
    A.fail("invalid-argument", "Unsupported child alert kind.");
  const opRef = A.operation(
    db,
    actorUid,
    "sendChildAlert",
    A.id(data?.operationId, "operationId"),
  );
  return db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid);
    const [childSnap, operation] = await Promise.all([
      tx.get(db.doc("makhdomeen/" + makhdomId)),
      tx.get(opRef),
    ]);
    if (!childSnap.exists) A.fail("not-found", "Child not found.");
    const child = childSnap.data();
    requireAdminScope(actor, child.grade);
    if (operation.exists) {
      if (operation.data().result.makhdomId !== makhdomId)
        A.fail(
          "failed-precondition",
          "Operation belongs to a different child.",
        );
      return { ...operation.data().result, idempotent: true };
    }
    if (child.active === false)
      A.fail("failed-precondition", "Archived children cannot receive alerts.");
    if (!child.assignedKhademId)
      A.fail("failed-precondition", "An assigned recipient is required.");
    const recipientId = A.id(child.assignedKhademId, "assignedKhademId");
    const recipientSnap = await tx.get(db.doc("khodam/" + recipientId));
    const recipient = A.active(
      recipientSnap.exists ? recipientSnap.data() : null,
    );
    if (recipient.grade !== child.grade)
      A.fail("permission-denied", "Recipient grade mismatch.");
    const outboxId = "alert_" + opRef.id;
    const common = {
      recipientId,
      recipientName: recipient.name || "",
      senderId: actorUid,
      senderName: actor.name || "",
      makhdomId,
      grade: child.grade,
      type: "absence_alert",
      title: "تنبيه متابعة",
      body: "افتح تطبيق افتقاد لمتابعة أحد مخدوميك.",
      templateKey: "child_absence_alert",
      templateArgs: {},
      data: { makhdomId, grade: child.grade, type: "absence_alert" },
      createdAt: A.stamp(),
    };
    tx.create(db.doc("notification_outbox/" + outboxId), {
      ...common,
      outboxId,
      state: "pending",
      status: "pending",
    });
    tx.create(db.doc("notifications/" + outboxId), {
      ...common,
      outboxId,
      isRead: false,
      deliveryState: "pending",
    });
    const result = {
      success: true,
      makhdomId,
      kind: "absence",
      outboxId,
      notificationId: outboxId,
      recipientId,
      recipientName: recipient.name || "",
    };
    tx.create(opRef, { result, createdAt: A.stamp() });
    return result;
  });
});
module.exports = {
  buildTaskWithOutbox,
  createTask,
  deleteTask,
  sendChildAlert,
};
