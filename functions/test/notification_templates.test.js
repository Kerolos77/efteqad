const test = require("node:test");
const assert = require("node:assert/strict");
const { renderNotificationTemplate } = require("../src/notification_templates");

test("Notification Templates Localization Tests", async (t) => {
  await t.test("renders Arabic template accurately with arguments", () => {
    const result = renderNotificationTemplate(
      "task_assigned",
      { title: "افتقاد الغائبين", createdByName: "مينا" },
      "ar-EG"
    );

    assert.equal(result.title, "مهمة جديدة: افتقاد الغائبين 📋");
    assert.equal(result.body, "قام مينا بتكليفك بمهمة جديدة");
  });

  await t.test("renders English template accurately with arguments", () => {
    const result = renderNotificationTemplate(
      "task_assigned",
      { title: "Follow up absent", createdByName: "Mark" },
      "en-US"
    );

    assert.equal(result.title, "New Task: Follow up absent 📋");
    assert.equal(result.body, "Mark assigned you a new task");
  });

  await t.test("falls back to generic title and body when template is unknown", () => {
    const arFallback = renderNotificationTemplate("unknown_key", {}, "ar");
    assert.equal(arFallback.title, "تنبيه جديد 🔔");

    const enFallback = renderNotificationTemplate("unknown_key", {}, "en");
    assert.equal(enFallback.title, "New Notification 🔔");
  });
});
