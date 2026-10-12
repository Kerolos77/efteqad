const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { Timestamp, FieldValue } = require("firebase-admin/firestore");
const { randomUUID } = require("node:crypto");
const A = require("./access");
function validateDeletionEligibility(actor, otherCount) {
  A.active(actor);
  if (actor.role === "stageAdmin" && otherCount <= 0) {
    const error = new functions.https.HttpsError(
      "failed-precondition",
      "Assign an active stage administrator before deleting this account.",
    );
    error.reason = "STAGE_ADMIN_REQUIRES_SUCCESSOR";
    throw error;
  }
  return true;
}
async function queueAccountDeletion({ db, uid, operationId }) {
  if (typeof operationId !== "string" || !operationId.trim())
    throw new functions.https.HttpsError(
      "invalid-argument",
      "operationId is required.",
    );
  return db.runTransaction(async (tx) => {
    const ref = db.doc("account_deletions/" + uid),
      profile = db.doc("khodam/" + uid);
    const [receipt, actorSnap] = await Promise.all([
      tx.get(ref),
      tx.get(profile),
    ]);
    if (receipt.exists)
      return {
        success: true,
        deletionId: uid,
        status: receipt.data().status,
        idempotent: true,
      };
    const actor = actorSnap.exists ? actorSnap.data() : null;
    const admins = await tx.get(
      db
        .collection("khodam")
        .where("role", "==", "stageAdmin")
        .where("status", "==", "active"),
    );
    validateDeletionEligibility(
      actor,
      admins.docs.filter((d) => d.id !== uid).length,
    );
    // Every deletion writes this guard, and reads active administrator documents in the same transaction.
    const guard = db.doc("admin_lifecycle/deletions");
    await tx.get(guard);
    tx.set(guard, { updatedAt: FieldValue.serverTimestamp() });
    tx.update(profile, {
      status: "deleting",
      deletingAt: FieldValue.serverTimestamp(),
    });
    tx.create(ref, {
      uid,
      operationId,
      status: "queued",
      phase: "devices",
      attempts: 0,
      nextAttemptAt: Timestamp.now(),
      createdAt: FieldValue.serverTimestamp(),
    });
    return { success: true, deletionId: uid, status: "queued" };
  });
}
async function executeAccountDeletion({ db, auth, uid, now = Date.now() }) {
  const ref = db.doc("account_deletions/" + uid),
    leaseId = randomUUID();
  const job = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const data = snap.data();
    if (
      ["completed", "failed"].includes(data.status) ||
      data.leaseExpiresAt?.toMillis() > now ||
      data.nextAttemptAt?.toMillis() > now
    )
      return null;
    if ((data.attempts || 0) >= 5) {
      if (!data.authDeletedAt)
        tx.set(
          db.doc("khodam/" + uid),
          { status: "deleting" },
          { merge: true },
        );
      tx.update(ref, {
        status: "failed",
        lastError: "Deletion attempt limit reached",
        nextAttemptAt: FieldValue.delete(),
        leaseId: FieldValue.delete(),
        leaseExpiresAt: FieldValue.delete(),
      });
      return { ...data, status: "failed", skip: true };
    }
    const expiry = Timestamp.fromMillis(now + 300000);
    tx.update(ref, {
      status: "cleaning",
      leaseId,
      leaseExpiresAt: expiry,
      nextAttemptAt: expiry,
      attempts: (data.attempts || 0) + 1,
    });
    return { ...data, attempts: (data.attempts || 0) + 1 };
  });
  if (!job) return { success: true, deletionId: uid, idempotent: true };
  if (job.skip) return { success: false, deletionId: uid, status: job.status };
  const checkpoint = async (patch) =>
    db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.data()?.leaseId !== leaseId) throw Error("Deletion lease lost");
      tx.update(ref, patch);
    });
  let phase = job.phase || "devices";
  try {
    if (phase === "devices") {
      // Devices are denied registration by Rules as soon as queueAccountDeletion marks the profile deleting.
      while (true) {
        const devices = await db
          .doc("khodam/" + uid)
          .collection("devices")
          .limit(400)
          .get();
        if (devices.empty) break;
        const batch = db.batch();
        for (const d of devices.docs) batch.delete(d.ref);
        await batch.commit();
      }
      phase = "unassignments";
      await checkpoint({ phase });
    }
    if (phase === "unassignments") {
      while (true) {
        const children = await db
          .collection("makhdomeen")
          .where("assignedKhademId", "==", uid)
          .limit(200)
          .get();
        if (children.empty) break;
        for (const child of children.docs)
          await db.runTransaction(async (tx) => {
            const fresh = await tx.get(child.ref);
            if (fresh.exists && fresh.data().assignedKhademId === uid)
              tx.update(child.ref, {
                assignedKhademId: null,
                assignedKhademName: null,
                unassignedReason: "servant_deleted",
                unassignedAt: FieldValue.serverTimestamp(),
              });
          });
      }
      phase = "profile";
      await checkpoint({ phase });
    }
    if (phase === "profile") {
      // Keep the deleting profile as the Rules barrier until Auth removal is confirmed.
      phase = "auth";
      await checkpoint({ phase });
    }
    if (phase === "auth") {
      if (!auth?.deleteUser) throw Error("Auth deletion dependency missing");
      // Restore the barrier for receipts queued by older workers that removed the profile first.
      await db
        .doc("khodam/" + uid)
        .set({ status: "deleting", assignedCount: 0 }, { merge: true });
      try {
        await auth.deleteUser(uid);
      } catch (e) {
        if (e.code !== "auth/user-not-found") throw e;
      }
      phase = "profileRemoval";
      await checkpoint({
        phase,
        authDeletedAt: FieldValue.serverTimestamp(),
      });
    }
    if (phase === "profileRemoval") {
      await db.doc("khodam/" + uid).delete();
      await checkpoint({
        phase: "completed",
        status: "completed",
        completedAt: FieldValue.serverTimestamp(),
        nextAttemptAt: FieldValue.delete(),
        leaseId: FieldValue.delete(),
        leaseExpiresAt: FieldValue.delete(),
      });
    }
    return { success: true, deletionId: uid, status: "completed" };
  } catch (error) {
    const status = job.attempts >= 5 ? "failed" : "failedRetryable";
    await checkpoint({
      phase,
      status,
      lastError: error.message,
      nextAttemptAt:
        status === "failed"
          ? FieldValue.delete()
          : Timestamp.fromMillis(
              now + 60000 * 2 ** (job.attempts - 1),
            ),
      leaseId: FieldValue.delete(),
      leaseExpiresAt: FieldValue.delete(),
    });
    return { success: false, deletionId: uid, status };
  }
}
async function processDueAccountDeletions({ db, auth, now = Date.now() }) {
  const due = await db
    .collection("account_deletions")
    .where("nextAttemptAt", "<=", Timestamp.fromMillis(now))
    .limit(100)
    .get();
  for (const job of due.docs)
    await executeAccountDeletion({ db, auth, uid: job.id, now });
}
const requestAccountDeletion = functions.https.onCall(async (data, context) => {
  if (!context.auth)
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required.",
    );
  if (typeof data?.expectedUid !== "string" || data.expectedUid !== context.auth.uid)
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The authenticated account changed during deletion.",
    );
  const authTime = context.auth.token?.auth_time;
  const age = Math.floor(Date.now() / 1000) - authTime;
  if (!Number.isFinite(authTime) || age < 0 || age > 300)
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Recent reauthentication is required.",
    );
  return queueAccountDeletion({
    db: admin.firestore(),
    uid: context.auth.uid,
    operationId: data?.operationId,
  });
});
const retryAccountDeletions = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(() =>
    processDueAccountDeletions({ db: admin.firestore(), auth: admin.auth() }),
  );
module.exports = {
  validateDeletionEligibility,
  queueAccountDeletion,
  executeAccountDeletion,
  processDueAccountDeletions,
  requestAccountDeletion,
  retryAccountDeletions,
};
