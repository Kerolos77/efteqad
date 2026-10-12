const { describe, it, before, after } = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
describe(
  "Legacy notification trigger integration",
  { skip: !process.env.FIRESTORE_EMULATOR_HOST },
  () => {
    let db, trigger, messaging, original;
    before(() => {
      process.env.GCLOUD_PROJECT = "demo-efteqad-legacy";
      trigger = require("../index").sendPushNotificationOnNewNotification;
      db = admin.firestore();
      messaging = admin.messaging();
      original = messaging.send;
    });
    after(async () => {
      messaging.send = original;
      await db.terminate();
      await admin.app().delete();
    });
    it("outbox-linked notifications never send through legacy trigger", async () => {
      let sends = 0;
      messaging.send = async () => {
        sends++;
        return "id";
      };
      await db
        .doc("notifications/linked")
        .set({
          outboxId: "o",
          recipientId: "s",
          title: "private",
          data: { taskId: "t" },
        });
      await db.doc("khodam/s").set({ fcmToken: "token", locale: "en" });
      await trigger.run(await db.doc("notifications/linked").get(), {
        params: { notificationId: "linked" },
      });
      assert.equal(sends, 0);
    });
    it("legacy task push uses generic localized lockscreen text", async () => {
      let payload;
      messaging.send = async (p) => {
        payload = p;
        return "id";
      };
      await db
        .doc("notifications/legacy")
        .set({
          recipientId: "s",
          title: "PRIVATE STUDENT",
          body: "PRIVATE PHONE",
          type: "general",
          data: { taskId: "t" },
        });
      await db.doc("khodam/s").set({ fcmToken: "token", locale: "en" });
      await trigger.run(await db.doc("notifications/legacy").get(), {
        params: { notificationId: "legacy" },
      });
      assert.ok(payload);
      assert.ok(!payload.notification.title.includes("PRIVATE"));
      assert.ok(!payload.notification.body.includes("PRIVATE"));
      assert.equal(payload.notification.title, "New task");
    });
  },
);
