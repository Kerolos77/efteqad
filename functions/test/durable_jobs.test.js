const { describe, it, before, after, beforeEach } = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const notifications = require("../src/notifications");
const deletion = require("../src/account_deletion");
describe(
  "Durable delivery and deletion jobs",
  { skip: !process.env.FIRESTORE_EMULATOR_HOST },
  () => {
    let db;
    before(() => {
      if (!admin.apps.length)
        admin.initializeApp({ projectId: "demo-efteqad-jobs" });
      db = admin.firestore();
    });
    after(async () => {
      await db.terminate();
      await admin.app().delete();
    });
    beforeEach(async () => {
      for (const c of await db.listCollections()) await db.recursiveDelete(c);
    });
    const read = async (p) => (await db.doc(p).get()).data();
    const put = (p, d) => db.doc(p).set(d);
    const seed = async () => {
      await put("notification_outbox/o", {
        state: "pending",
        status: "pending",
        recipientId: "s",
        taskId: "t",
        type: "task",
        templateKey: "task_assigned",
        templateArgs: { title: "PRIVATE CHILD DETAIL" },
      });
      await put("notifications/n", { outboxId: "o", deliveryState: "pending" });
      await put("khodam/s/devices/a", { token: "ok", locale: "en" });
      await put("khodam/s/devices/b", { token: "retry", locale: "ar" });
    };
    it("partial success schedules retry and never resends the accepted installation", async () => {
      await seed();
      const sent = [];
      let retryFails = true;
      const messaging = {
        send: async (p) => {
          sent.push(p);
          if (p.token === "retry" && retryFails) throw new Error("temporary");
          return "fcm-id";
        },
      };
      await notifications.processOutboxNotification({
        db,
        messaging,
        outboxId: "o",
        outboxData: { state: "pending", recipientId: "s" },
      });
      let job = await read("notification_outbox/o");
      assert.equal(job.state, "retryable_failure");
      assert.equal(job.status, job.state);
      assert.equal(job.deliveredDeviceCount, 1);
      assert.ok(job.nextAttemptAt);
      assert.equal(
        (await read("notifications/n")).deliveryState,
        "retryable_failure",
      );
      assert.ok(!sent[0].notification.title.includes("PRIVATE"));
      retryFails = false;
      await put("notification_outbox/o", {
        ...job,
        nextAttemptAt: admin.firestore.Timestamp.fromMillis(0),
      });
      await notifications.processDueOutboxNotifications({ db, messaging });
      job = await read("notification_outbox/o");
      assert.equal(job.state, "sent");
      assert.equal(job.deliveredDeviceCount, 2);
      assert.equal(sent.filter((p) => p.token === "ok").length, 1);
      assert.equal(sent.filter((p) => p.token === "retry").length, 2);
    });
    it("invalid installation token rotated between attempts is retried", async () => {
      await seed();
      const sent = [];
      let fail = true;
      const messaging = {
        send: async (p) => {
          sent.push(p.token);
          if (fail && p.token === "ok") {
            await db.doc("khodam/s/devices/a").update({ token: "replacement" });
            const e = Error("invalid old token");
            e.code = "messaging/registration-token-not-registered";
            throw e;
          }
          if (fail && p.token === "retry") throw Error("temporary");
          return "id";
        },
      };
      await notifications.processOutboxNotification({
        db,
        messaging,
        outboxId: "o",
      });
      assert.equal((await read("khodam/s/devices/a")).token, "replacement");
      fail = false;
      await db
        .doc("notification_outbox/o")
        .update({ nextAttemptAt: admin.firestore.Timestamp.fromMillis(0) });
      await notifications.processDueOutboxNotifications({ db, messaging });
      assert.deepEqual(sent, ["ok", "retry", "replacement", "retry"]);
      assert.equal(
        (await read("notification_outbox/o")).deliveredDeviceCount,
        2,
      );
    });
    it("removed unresolved installations do not leave remaining delivered job retrying", async () => {
      await seed();
      const sent = [];
      const messaging = {
        send: async (p) => {
          sent.push(p.token);
          if (p.token === "retry") throw Error("temporary");
          return "id";
        },
      };
      await notifications.processOutboxNotification({
        db,
        messaging,
        outboxId: "o",
      });
      await db.doc("khodam/s/devices/b").delete();
      await db
        .doc("notification_outbox/o")
        .update({ nextAttemptAt: admin.firestore.Timestamp.fromMillis(0) });
      await notifications.processDueOutboxNotifications({ db, messaging });
      assert.equal((await read("notification_outbox/o")).state, "sent");
      assert.equal((await read("notifications/n")).deliveryState, "sent");
      assert.deepEqual(sent, ["ok", "retry"]);
    });
    it("rotation preserved during invalid-token cleanup keeps its viable replacement pending", async () => {
      await seed();
      await db.doc("khodam/s/devices/b").delete();
      const sent = [];
      const messaging = {
        send: async (p) => {
          sent.push(p.token);
          if (p.token === "ok") {
            await db.doc("khodam/s/devices/a").update({ token: "replacement" });
            const e = Error("old token invalid");
            e.code = "messaging/registration-token-not-registered";
            throw e;
          }
          return "id";
        },
      };
      await notifications.processOutboxNotification({
        db,
        messaging,
        outboxId: "o",
      });
      assert.equal(
        (await read("notification_outbox/o")).state,
        "retryable_failure",
      );
      await db
        .doc("notification_outbox/o")
        .update({ nextAttemptAt: admin.firestore.Timestamp.fromMillis(0) });
      await notifications.processDueOutboxNotifications({ db, messaging });
      assert.deepEqual(sent, ["ok", "replacement"]);
      assert.equal((await read("notification_outbox/o")).state, "sent");
    });
    it("fresh lease excludes concurrent workers; expired lease resumes", async () => {
      await seed();
      await db.doc("khodam/s/devices/b").delete();
      let release;
      const gate = new Promise((r) => (release = r));
      let calls = 0;
      const messaging = {
        send: async () => {
          calls++;
          await gate;
          return "id";
        },
      };
      const first = notifications.processOutboxNotification({
        db,
        messaging,
        outboxId: "o",
        outboxData: { state: "pending", recipientId: "s" },
      });
      for (let i = 0; i < 200 && calls === 0; i++)
        await new Promise((r) => setTimeout(r, 5));
      const second = notifications.processOutboxNotification({
        db,
        messaging,
        outboxId: "o",
        outboxData: { state: "pending", recipientId: "s" },
      });
      await Promise.race([second, new Promise((r) => setTimeout(r, 150))]);
      release();
      await Promise.all([first, second]);
      assert.equal(calls, 1);
      await put("notification_outbox/expired", {
        state: "processing",
        status: "processing",
        recipientId: "s",
        leaseExpiresAt: admin.firestore.Timestamp.fromMillis(0),
      });
      await notifications.processDueOutboxNotifications({
        db,
        messaging: {
          send: async () => {
            calls++;
            return "id";
          },
        },
      });
      assert.equal((await read("notification_outbox/expired")).state, "sent");
    });
    it("no devices and invalid tokens are terminal and update in-app state", async () => {
      await seed();
      await db.doc("khodam/s/devices/a").delete();
      await db.doc("khodam/s/devices/b").delete();
      await notifications.processOutboxNotification({
        db,
        messaging: {
          send: async () => {
            throw Error("should not send");
          },
        },
        outboxId: "o",
        outboxData: { state: "pending", recipientId: "s" },
      });
      assert.equal((await read("notification_outbox/o")).state, "no_devices");
      assert.equal((await read("notifications/n")).deliveryState, "no_devices");
      await put("notification_outbox/invalid", {
        recipientId: "s",
        state: "pending",
      });
      await put("khodam/s/devices/a", { token: "stale" });
      await notifications.processOutboxNotification({
        db,
        outboxId: "invalid",
        outboxData: { state: "pending", recipientId: "s" },
        messaging: {
          send: async () => {
            const e = Error("stale");
            e.code = "messaging/registration-token-not-registered";
            throw e;
          },
        },
      });
      assert.equal((await db.doc("khodam/s/devices/a").get()).exists, false);
      assert.equal(
        (await read("notification_outbox/invalid")).state,
        "all_tokens_invalid",
      );
    });
    it("transient delivery failures stop after three scheduled attempts", async () => {
      await seed();
      const messaging = {
        send: async () => {
          throw Error("offline");
        },
      };
      for (let i = 0; i < 3; i++) {
        await db
          .doc("notification_outbox/o")
          .update({ nextAttemptAt: admin.firestore.Timestamp.fromMillis(0) });
        await notifications.processOutboxNotification({
          db,
          messaging,
          outboxId: "o",
          outboxData: { state: "pending", recipientId: "s" },
        });
      }
      const job = await read("notification_outbox/o");
      assert.equal(job.state, "failed");
      assert.equal(job.attempts, 3);
    });
    it("expired third delivery lease cannot cause a fourth FCM attempt", async () => {
      await put("notification_outbox/o", {
        state: "processing",
        status: "processing",
        recipientId: "s",
        attempts: 3,
        leaseExpiresAt: admin.firestore.Timestamp.fromMillis(0),
      });
      await put("khodam/s/devices/a", { token: "ok" });
      let sends = 0;
      await notifications.processDueOutboxNotifications({
        db,
        messaging: {
          send: async () => {
            sends++;
            return "id";
          },
        },
      });
      assert.equal(sends, 0);
      assert.equal((await read("notification_outbox/o")).state, "failed");
    });
    const context = (uid, authTime) => ({
      auth: {
        uid,
        token: authTime === undefined ? {} : { auth_time: authTime },
      },
    });
    it("deletion rejects a replacement authenticated account without any writes", async () => {
      const original = { role: "servant", status: "active", grade: "1st" };
      await put("khodam/initiator", original);
      await put("khodam/replacement", original);
      await assert.rejects(deletion.requestAccountDeletion.run(
        { operationId: "switch-intent", expectedUid: "initiator" },
        context("replacement", Math.floor(Date.now() / 1000))),
        (e) => e.code === "failed-precondition");
      assert.deepEqual(await read("khodam/initiator"), original);
      assert.deepEqual(await read("khodam/replacement"), original);
      assert.equal((await db.collection("account_deletions").get()).empty, true);
      assert.equal((await db.collection("lifecycle_guards").get()).empty, true);
    });
    it("deletion requires a present recent auth_time and active profile", async () => {
      await put("khodam/s", {
        role: "servant",
        status: "active",
        grade: "1st",
      });
      for (const time of [undefined, Math.floor(Date.now() / 1000) - 301])
        await assert.rejects(
          deletion.requestAccountDeletion.run(
            { operationId: "d", expectedUid: "s" },
            context("s", time),
          ),
          (e) => e.code === "failed-precondition",
        );
      await put("khodam/s", { role: "pending", status: "pending" });
      await assert.rejects(
        deletion.requestAccountDeletion.run(
          { operationId: "d", expectedUid: "s" },
          context("s", Math.floor(Date.now() / 1000)),
        ),
        (e) => e.code === "permission-denied",
      );
      assert.equal((await db.doc("account_deletions/s").get()).exists, false);
    });
    it("invalid active role cannot queue deletion", async () => {
      await put("khodam/s", { role: "pending", status: "active" });
      await assert.rejects(
        deletion.queueAccountDeletion({ db, uid: "s", operationId: "d" }),
        (e) => e.code === "permission-denied",
      );
      assert.equal((await db.doc("account_deletions/s").get()).exists, false);
    });
    it("deletion rejects an active servant profile with missing trusted grade", async () => {
      await put("khodam/s", { role: "servant", status: "active", grade: null });
      await assert.rejects(
        deletion.queueAccountDeletion({
          db,
          uid: "s",
          operationId: "missing-grade",
        }),
        (e) => e.code === "permission-denied",
      );
      assert.equal((await db.doc("account_deletions/s").get()).exists, false);
    });
    it("expired fifth deletion lease stops without a sixth Auth deletion attempt", async () => {
      await put("account_deletions/s", {
        uid: "s",
        operationId: "stable",
        status: "cleaning",
        phase: "auth",
        attempts: 5,
        leaseExpiresAt: admin.firestore.Timestamp.fromMillis(0),
        nextAttemptAt: admin.firestore.Timestamp.fromMillis(0),
      });
      let calls = 0;
      await deletion.processDueAccountDeletions({
        db,
        auth: {
          deleteUser: async () => {
            calls++;
          },
        },
      });
      assert.equal(calls, 0);
      const receipt = await read("account_deletions/s");
      assert.equal(receipt.status, "failed");
      assert.equal(receipt.authDeletedAt, undefined);
    });
    it("concurrent last administrators cannot both enter deleting state", async () => {
      for (const uid of ["a", "b"])
        await put("khodam/" + uid, { role: "stageAdmin", status: "active" });
      const results = await Promise.allSettled(
        ["a", "b"].map((uid) =>
          deletion.queueAccountDeletion({ db, uid, operationId: "d" }),
        ),
      );
      assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
      assert.equal(
        (await db.collection("khodam").where("status", "==", "active").get())
          .size,
        1,
      );
    });
    it("Auth failure keeps resumable checkpoint and scheduled consumer completes once", async () => {
      await put("khodam/s", {
        role: "servant",
        status: "active",
        grade: "1st",
      });
      await put("khodam/s/devices/a", { token: "t" });
      await put("makhdomeen/m", { assignedKhademId: "s", grade: "1st" });
      await deletion.queueAccountDeletion({
        db,
        uid: "s",
        operationId: "stable",
      });
      let attempts = 0;
      const auth = {
        deleteUser: async () => {
          attempts++;
          if (attempts === 1) throw Error("auth offline");
        },
      };
      await deletion.executeAccountDeletion({ db, auth, uid: "s" });
      let job = await read("account_deletions/s");
      assert.equal(job.status, "failedRetryable");
      assert.equal(job.phase, "auth");
      assert.equal(job.authDeletedAt, undefined);
      assert.equal((await read("khodam/s"))?.status, "deleting");
      assert.equal((await read("makhdomeen/m")).assignedKhademId, null);
      await db
        .doc("account_deletions/s")
        .update({ nextAttemptAt: admin.firestore.Timestamp.fromMillis(0) });
      await deletion.processDueAccountDeletions({ db, auth });
      job = await read("account_deletions/s");
      assert.equal(job.status, "completed");
      assert.ok(job.authDeletedAt);
      await deletion.executeAccountDeletion({ db, auth, uid: "s" });
      assert.equal(attempts, 2);
      assert.equal(job.operationId, "stable");
    });
  },
);
