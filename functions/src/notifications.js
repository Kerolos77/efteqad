const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { Timestamp, FieldValue } = require("firebase-admin/firestore");
const { randomUUID, createHash } = require("node:crypto");
const { renderNotificationTemplate } = require("./notification_templates");
const TERMINAL = new Set([
  "sent",
  "no_devices",
  "all_tokens_invalid",
  "failed",
  "cancelled",
]);
function isInvalidTokenError(error) {
  const code = error?.code || error?.errorInfo?.code || "";
  return [
    "messaging/registration-token-not-registered",
    "messaging/invalid-registration-token",
  ].includes(code);
}
function pushText(job, locale) {
  // Task titles and descriptions are private in-app content, including legacy outbox payloads.
  if (
    job.taskId ||
    job.type?.startsWith("attendance") ||
    job.templateKey === "task_assigned"
  ) {
    return locale?.startsWith("en")
      ? { title: "New task", body: "Open Efteqad to view your assignment." }
      : { title: "مهمة جديدة", body: "افتح تطبيق افتقاد لعرض التكليف." };
  }
  return job.templateKey
    ? renderNotificationTemplate(
        job.templateKey,
        job.templateArgs || {},
        locale || "ar",
      )
    : { title: job.title || "تنبيه جديد", body: job.body || "" };
}
async function updateDelivery(db, ref, leaseId, patch) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || snap.data().leaseId !== leaseId) return false;
    const notices = await tx.get(
      db.collection("notifications").where("outboxId", "==", ref.id),
    );
    tx.update(ref, patch);
    if (patch.state)
      for (const notice of notices.docs)
        tx.update(notice.ref, {
          deliveryState: patch.state,
          deliveredDeviceCount: patch.deliveredDeviceCount || 0,
        });
    return true;
  });
}
async function processOutboxNotification({
  db,
  messaging,
  outboxId,
  now = Date.now(),
}) {
  const ref = db.collection("notification_outbox").doc(outboxId);
  const leaseId = randomUUID();
  const job = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const data = snap.data();
    if (TERMINAL.has(data.state || data.status)) return null;
    if (
      data.leaseExpiresAt?.toMillis() > now ||
      data.nextAttemptAt?.toMillis() > now
    )
      return null;
    if ((data.attempts || 0) >= 3) {
      const notices = await tx.get(
        db.collection("notifications").where("outboxId", "==", outboxId),
      );
      const deliveredDeviceCount = Object.values(
        data.deviceResults || {},
      ).filter((r) => r.state === "delivered").length;
      tx.update(ref, {
        state: "failed",
        status: "failed",
        deliveredDeviceCount,
        lastError: "Delivery attempt limit reached",
        nextAttemptAt: FieldValue.delete(),
        leaseId: FieldValue.delete(),
        leaseExpiresAt: FieldValue.delete(),
      });
      for (const notice of notices.docs)
        tx.update(notice.ref, {
          deliveryState: "failed",
          deliveredDeviceCount,
        });
      return null;
    }
    const leaseExpiresAt = Timestamp.fromMillis(now + 300000);
    tx.update(ref, {
      state: "processing",
      status: "processing",
      leaseId,
      leaseExpiresAt,
      nextAttemptAt: leaseExpiresAt,
      attempts: (data.attempts || 0) + 1,
    });
    return { ...data, attempts: (data.attempts || 0) + 1 };
  });
  if (!job) return { success: true, alreadySent: true };
  const results = { ...(job.deviceResults || {}) };
  let lastError = null;
  try {
    if (!job.recipientId) throw Error("Missing recipientId");
    const devices = await db
      .collection("khodam")
      .doc(job.recipientId)
      .collection("devices")
      .get();
    const installed = new Set(devices.docs.map((d) => d.id));
    for (const [id, outcome] of Object.entries(results))
      if (!installed.has(id) && ["retry", "failed"].includes(outcome.state))
        delete results[id];
    for (const device of devices.docs) {
      const data = device.data();
      const tokenIdentity = createHash("sha256")
        .update(data.token || "")
        .digest("hex");
      const previous = results[device.id];
      if (
        previous?.state === "delivered" ||
        (["invalid", "failed"].includes(previous?.state) &&
          previous.tokenIdentity === tokenIdentity)
      )
        continue;
      const owner = await ref.get();
      if (
        owner.data()?.leaseId !== leaseId ||
        owner.data()?.state !== "processing"
      )
        return { success: false, state: owner.data()?.state || "lease_lost" };
      let outcome;
      try {
        if (!data.token) {
          outcome = { state: "invalid" };
        } else {
          const messageId = await messaging.send({
            token: data.token,
            notification: pushText(job, data.locale),
            data: {
              outboxId,
              taskId: job.taskId || "",
              makhdomId: job.makhdomId || "",
              grade: job.grade || "",
              type: job.type || "task",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
              priority: "high",
              notification: {
                channelId: "efteqad_high_importance_channel",
                sound: "default",
              },
            },
          });
          outcome = { state: "delivered", messageId };
        }
      } catch (error) {
        lastError = error.message || String(error);
        outcome = {
          state: isInvalidTokenError(error)
            ? "invalid"
            : job.attempts >= 3
              ? "failed"
              : "retry",
          error: lastError,
        };
      }
      if (outcome.state !== "delivered") outcome.tokenIdentity = tokenIdentity;
      results[device.id] = outcome;
      // Persist each FCM result immediately; a process crash after send and before this write can still duplicate a push.
      if (!(await updateDelivery(db, ref, leaseId, { deviceResults: results })))
        return { success: false, state: "lease_lost" };
      if (outcome.state === "invalid") {
        const replacementExists = await db.runTransaction(async (tx) => {
          const fresh = await tx.get(device.ref);
          if (fresh.exists && fresh.data().token === data.token) {
            tx.delete(device.ref);
            return false;
          }
          return fresh.exists && !!fresh.data().token;
        });
        if (replacementExists) {
          results[device.id] = {
            ...outcome,
            state: job.attempts >= 3 ? "failed" : "retry",
            error: "Token rotated during invalid-token cleanup",
          };
          if (
            !(await updateDelivery(db, ref, leaseId, {
              deviceResults: results,
            }))
          )
            return { success: false, state: "lease_lost" };
        }
      }
    }
    const outcomes = Object.values(results);
    const delivered = outcomes.filter((r) => r.state === "delivered").length;
    const invalid = outcomes.filter((r) => r.state === "invalid").length;
    const retry = outcomes.some((r) => r.state === "retry");
    const failures = outcomes.some((r) => r.state === "failed");
    const state = retry
      ? "retryable_failure"
      : failures
        ? "failed"
        : delivered
          ? "sent"
          : invalid
            ? "all_tokens_invalid"
            : "no_devices";
    await updateDelivery(db, ref, leaseId, {
      state,
      status: state,
      deviceResults: results,
      deliveredDeviceCount: delivered,
      removedStaleDeviceCount: invalid,
      lastError,
      nextAttemptAt: retry
        ? Timestamp.fromMillis(
            now + 60000 * 2 ** (job.attempts - 1),
          )
        : FieldValue.delete(),
      leaseId: FieldValue.delete(),
      leaseExpiresAt: FieldValue.delete(),
      ...(TERMINAL.has(state)
        ? { completedAt: FieldValue.serverTimestamp() }
        : {}),
    });
    return {
      success: ["sent", "no_devices"].includes(state),
      state,
      deliveredDeviceCount: delivered,
      removedStaleDeviceCount: invalid,
    };
  } catch (error) {
    const state = job.attempts >= 3 ? "failed" : "retryable_failure";
    await updateDelivery(db, ref, leaseId, {
      state,
      status: state,
      lastError: error.message,
      nextAttemptAt:
        state === "failed"
          ? FieldValue.delete()
          : Timestamp.fromMillis(
              now + 60000 * 2 ** (job.attempts - 1),
            ),
      leaseId: FieldValue.delete(),
      leaseExpiresAt: FieldValue.delete(),
    });
    return { success: false, state, error: error.message };
  }
}
async function processDueOutboxNotifications({
  db,
  messaging,
  now = Date.now(),
}) {
  const due = await db
    .collection("notification_outbox")
    .where("nextAttemptAt", "<=", Timestamp.fromMillis(now))
    .limit(100)
    .get();
  const expired = await db
    .collection("notification_outbox")
    .where("leaseExpiresAt", "<=", Timestamp.fromMillis(now))
    .limit(100)
    .get();
  const pending = await db
    .collection("notification_outbox")
    .where("state", "==", "pending")
    .limit(100)
    .get();
  for (const id of new Set(
    [...due.docs, ...pending.docs, ...expired.docs].map((d) => d.id),
  ))
    await processOutboxNotification({ db, messaging, outboxId: id, now });
}
const sendPushOnOutboxCreated = functions.firestore
  .document("notification_outbox/{outboxId}")
  .onCreate((snap, context) =>
    process.env.FUNCTIONS_EMULATOR === "true"
      ? null
      : processOutboxNotification({
          db: admin.firestore(),
          messaging: admin.messaging(),
          outboxId: context.params.outboxId,
        }),
  );
const retryNotificationOutbox = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(() =>
    process.env.FUNCTIONS_EMULATOR === "true"
      ? null
      : processDueOutboxNotifications({
          db: admin.firestore(),
          messaging: admin.messaging(),
        }),
  );
module.exports = {
  isInvalidTokenError,
  processOutboxNotification,
  processDueOutboxNotifications,
  sendPushOnOutboxCreated,
  retryNotificationOutbox,
};
