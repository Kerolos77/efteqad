const { describe, it, before, after, beforeEach } = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const tasks = require("../src/tasks"),
  imports = require("../src/imports"),
  notifications = require("../src/notifications");
describe(
  "Approved Task2 contract extensions",
  { skip: !process.env.FIRESTORE_EMULATOR_HOST },
  () => {
    let db;
    before(() => {
      if (!admin.apps.length)
        admin.initializeApp({ projectId: "demo-efteqad-extensions" });
      db = admin.firestore();
    });
    after(async () => {
      await db.terminate();
      await admin.app().delete();
    });
    beforeEach(async () => {
      for (const c of await db.listCollections()) await db.recursiveDelete(c);
      await Promise.all([
        db.doc("khodam/a").set({
          role: "gradeAdmin",
          status: "active",
          grade: "1st",
          name: "Admin",
        }),
        db.doc("khodam/s").set({
          role: "servant",
          status: "active",
          grade: "1st",
          name: "Servant",
        }),
        db.doc("khodam/new").set({
          role: "servant",
          status: "active",
          grade: "1st",
          name: "New owner",
        }),
        db
          .doc("khodam/other")
          .set({ role: "gradeAdmin", status: "active", grade: "2nd" }),
        db.doc("makhdomeen/m").set({
          fullName: "PRIVATE CHILD",
          grade: "1st",
          active: true,
          assignedKhademId: "new",
        }),
      ]);
    });
    const call = (fn, data, uid = "a") =>
      fn.run(data, { auth: { uid, token: {} } });
    const read = async (p) => (await db.doc(p).get()).data();
    it("tracking import preserves nullable dates, rejects overflow/malformed strings and retries idempotently", async () => {
      const payload = {
        importId: "tracking",
        grade: "1st",
        rows: [
          {
            fullName: "Valid",
            phone: "01000000000",
            trackingStartDate: "2026-09-25",
          },
          { fullName: "Null", phone: "01000000001", trackingStartDate: null },
          {
            fullName: "Overflow",
            phone: "01000000002",
            trackingStartDate: "2026-02-31",
          },
          {
            fullName: "Invalid",
            phone: "01000000003",
            trackingStartDate: "garbage",
          },
        ],
      };
      const result = await call(imports.importRows, payload);
      assert.equal(result.imported, 2);
      assert.equal(result.rejected, 2);
      assert.equal(
        (
          await read("makhdomeen/" + result.results[0].makhdomId)
        ).trackingStartDate
          .toDate()
          .toISOString(),
        "2026-09-25T00:00:00.000Z",
      );
      assert.equal(
        (await read("makhdomeen/" + result.results[1].makhdomId))
          .trackingStartDate,
        null,
      );
      await call(imports.importRows, payload);
      assert.equal((await db.collection("makhdomeen").get()).size, 3);
    });
    const create = () =>
      call(tasks.createTask, {
        operationId: "create",
        taskData: {
          title: "Task",
          grade: "1st",
          assignedKhademId: "s",
          type: "attendance_khedma",
          dueDate: "2026-10-09",
        },
      });
    it("task deletion archives the receipt, preserves finalized attendance and cancels pending push idempotently", async () => {
      const created = await create();
      const sessionId = "2026-10-09_khedma_1st";
      await db.doc("attendance/" + sessionId).set({
        status: "finalized",
        grade: "1st",
        taskId: created.taskId,
        attendedMakhdomIds: ["m"],
      });
      await db
        .doc("tasks/" + created.taskId)
        .update({ isCompleted: true, status: "completed" });
      const result = await call(tasks.deleteTask, {
        taskId: created.taskId,
        operationId: "delete",
      });
      assert.equal(result.status, "cancelled");
      assert.equal((await read("tasks/" + created.taskId)).isCompleted, true);
      assert.equal((await read("attendance/" + sessionId)).status, "finalized");
      assert.deepEqual(
        (await read("attendance/" + sessionId)).attendedMakhdomIds,
        ["m"],
      );
      assert.equal(
        (await read("notification_outbox/" + created.outboxId)).state,
        "cancelled",
      );
      assert.equal(
        (await read("notifications/" + created.outboxId)).deliveryState,
        "cancelled",
      );
      let sends = 0;
      await notifications.processOutboxNotification({
        db,
        outboxId: created.outboxId,
        messaging: {
          send: async () => {
            sends++;
            return "id";
          },
        },
      });
      assert.equal(sends, 0);
      assert.equal(
        (
          await call(tasks.deleteTask, {
            taskId: created.taskId,
            operationId: "delete",
          })
        ).idempotent,
        true,
      );
    });
    it("started attendance must be finalized before task archival", async () => {
      const created = await create();
      await db
        .doc("attendance/2026-10-09_khedma_1st")
        .set({
          status: "draft",
          grade: "1st",
          taskId: created.taskId,
          attendedMakhdomIds: ["m"],
        });
      await assert.rejects(
        call(tasks.deleteTask, {
          taskId: created.taskId,
          operationId: "delete-draft",
        }),
        (e) => e.code === "failed-precondition",
      );
      assert.equal((await read("tasks/" + created.taskId)).status, "active");
      assert.equal(
        (await read("notification_outbox/" + created.outboxId)).state,
        "pending",
      );
    });
    it("task deletion denies servants and other-grade administrators", async () => {
      const created = await create();
      for (const uid of ["s", "other"])
        await assert.rejects(
          call(
            tasks.deleteTask,
            { taskId: created.taskId, operationId: "delete" },
            uid,
          ),
          (e) => e.code === "permission-denied",
        );
      assert.equal((await read("tasks/" + created.taskId)).status, "active");
    });
    it("child alert derives recipient and generic content atomically, ignoring caller-supplied names/details", async () => {
      const payload = {
        makhdomId: "m",
        kind: "absence",
        operationId: "alert",
        recipientId: "s",
        title: "SPOOF",
        body: "PRIVATE PHONE",
      };
      const result = await call(tasks.sendChildAlert, payload);
      assert.equal(result.recipientId, "new");
      const out = await read("notification_outbox/" + result.outboxId);
      const notice = await read("notifications/" + result.outboxId);
      assert.equal(out.recipientId, "new");
      assert.equal(notice.recipientId, "new");
      assert.equal(out.templateKey, "child_absence_alert");
      assert.equal(notice.outboxId, result.outboxId);
      assert.ok(!JSON.stringify(out).includes("PRIVATE"));
      assert.ok(!JSON.stringify(out).includes("SPOOF"));
      const again = await call(tasks.sendChildAlert, payload);
      assert.equal(again.outboxId, result.outboxId);
      assert.equal(again.idempotent, true);
      assert.equal((await db.collection("notifications").get()).size, 1);
      await db.doc("khodam/new/devices/en").set({ token: "en", locale: "en" });
      await db.doc("khodam/new/devices/ar").set({ token: "ar", locale: "ar" });
      const pushes = [];
      await notifications.processOutboxNotification({
        db,
        outboxId: result.outboxId,
        messaging: {
          send: async (p) => {
            pushes.push(p);
            return "id";
          },
        },
      });
      assert.equal(pushes.length, 2);
      assert.ok(pushes[0].notification.title !== pushes[1].notification.title);
      assert.ok(!JSON.stringify(pushes).includes("PRIVATE"));
    });
    it("child alerts deny other scope, servants, archived children, inactive or absent recipients", async () => {
      const payload = { makhdomId: "m", kind: "absence", operationId: "alert" };
      for (const uid of ["other", "s"])
        await assert.rejects(
          call(tasks.sendChildAlert, payload, uid),
          (e) => e.code === "permission-denied",
        );
      await db.doc("khodam/new").update({ status: "deleting" });
      await assert.rejects(
        call(tasks.sendChildAlert, payload),
        (e) => e.code === "permission-denied",
      );
      await db.doc("khodam/new").update({ status: "active" });
      await db.doc("makhdomeen/m").update({ assignedKhademId: null });
      await assert.rejects(
        call(tasks.sendChildAlert, payload),
        (e) => e.code === "failed-precondition",
      );
      await db
        .doc("makhdomeen/m")
        .update({ assignedKhademId: "new", active: false });
      await assert.rejects(
        call(tasks.sendChildAlert, payload),
        (e) => e.code === "failed-precondition",
      );
      assert.equal((await db.collection("notification_outbox").get()).size, 0);
    });
  },
);
