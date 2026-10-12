const { describe, it, before, after } = require("node:test");
const assert = require("node:assert/strict");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const fs = require("node:fs");
describe(
  "Trusted Rules boundaries",
  { skip: !process.env.FIRESTORE_EMULATOR_HOST },
  () => {
    let env;
    before(async () => {
      env = await initializeTestEnvironment({
        projectId: "demo-efteqad-rules",
        firestore: {
          rules: fs.readFileSync(
            require("node:path").resolve(__dirname, "../../firestore.rules"),
            "utf8",
          ),
        },
      });
      await env.clearFirestore();
      await env.withSecurityRulesDisabled(async (c) => {
        const db = c.firestore();
        await Promise.all([
          db
            .doc("khodam/a")
            .set({ role: "gradeAdmin", status: "active", grade: "1st" }),
          db
            .doc("khodam/s")
            .set({ role: "servant", status: "active", grade: "1st" }),
          db.doc("khodam/p").set({ role: "pending", status: "pending" }),
          db
            .doc("khodam/inactive")
            .set({ role: "servant", status: "deleting", grade: "1st" }),
          db.doc("khodam/stage").set({ role: "stageAdmin", status: "active" }),
          db.doc("makhdomeen/m").set({
            fullName: "Assigned",
            grade: "1st",
            active: true,
            assignedKhademId: "s",
          }),
          db.doc("makhdomeen/unassigned").set({
            fullName: "Private",
            grade: "1st",
            active: true,
            assignedKhademId: "other",
          }),
          db.doc("tasks/t").set({
            grade: "1st",
            assignedKhademId: "s",
            type: "attendance_khedma",
            isCompleted: false,
          }),
          db.doc("tasks/other").set({
            grade: "2nd",
            assignedKhademId: "other",
            type: "general",
            isCompleted: false,
          }),
          db.doc("attendance/session/grades/1st").set({
            grade: "1st",
            status: "finalized",
            attendedMakhdomIds: ["m"],
          }),
          db
            .doc("attendance_roster/m")
            .set({ id: "m", grade: "1st", fullName: "Assigned", active: true }),
          db
            .doc("visits/v")
            .set({ makhdomId: "m", grade: "1st", khademId: "s" }),
          db.doc("notifications/n").set({ recipientId: "s", isRead: false }),
        ]);
      });
    });
    after(async () => env?.cleanup());
    const db = (uid) => env.authenticatedContext(uid).firestore();
    it("servant reads only assigned child even in own grade", async () => {
      await assertSucceeds(db("s").doc("makhdomeen/m").get());
      await assertFails(db("s").doc("makhdomeen/unassigned").get());
    });
    it("query contract limits servant children to assignment and tasks to assigned ID", async () => {
      await assertSucceeds(
        db("s")
          .collection("makhdomeen")
          .where("assignedKhademId", "==", "s")
          .get(),
      );
      await assertFails(
        db("s").collection("makhdomeen").where("grade", "==", "1st").get(),
      );
      await assertSucceeds(
        db("s").collection("tasks").where("assignedKhademId", "==", "s").get(),
      );
      await assertFails(db("s").collection("tasks").get());
      await assertSucceeds(
        db("a").collection("tasks").where("grade", "==", "1st").get(),
      );
    });
    it("pending and deleting actors have no business read/write", async () => {
      for (const uid of ["p", "inactive"]) {
        await assertFails(db(uid).doc("visits/v").get());
        await assertFails(db(uid).doc("tasks/t").update({ isCompleted: true }));
        await assertFails(
          db(uid)
            .doc("attendance/session/grades/1st")
            .update({ attendedMakhdomIds: [] }),
        );
      }
    });
    it("client cannot change finalized attendance or create attendance", async () => {
      for (const uid of ["s", "a", "stage"]) {
        await assertFails(
          db(uid)
            .doc("attendance/session/grades/1st")
            .update({ attendedMakhdomIds: [] }),
        );
        await assertFails(
          db(uid)
            .doc("attendance/new/grades/1st")
            .set({ grade: "1st", status: "draft" }),
        );
      }
    });
    it("client cannot mutate outbox, counters, assignment or general notes", async () => {
      for (const uid of ["s", "a", "stage"]) {
        await assertFails(
          db(uid).doc("notification_outbox/hack").set({ recipientId: "s" }),
        );
        await assertFails(
          db(uid).doc("khodam/s").update({ assignedCount: 100 }),
        );
        await assertFails(
          db(uid).doc("makhdomeen/m").update({ assignedKhademId: "other" }),
        );
        await assertFails(
          db(uid).doc("makhdomeen/m").update({ notes: "overwrite" }),
        );
      }
    });
    it("self profile field and devices allowlists exclude role and arbitrary fields", async () => {
      await assertSucceeds(
        db("s")
          .doc("khodam/s")
          .update({ name: "Name", phone: "1", locale: "en" }),
      );
      await assertFails(db("s").doc("khodam/s").update({ fcmToken: "old" }));
      await assertSucceeds(
        db("p").doc("khodam/p").update({ name: "Pending name" }),
      );
      await assertSucceeds(
        db("s")
          .doc("khodam/s/devices/device")
          .set({ token: "tok", locale: "ar", platform: "android" }),
      );
      await assertFails(
        db("s").doc("khodam/s/devices/device").update({ ownerId: "other" }),
      );
    });
    it("roster only allows admin direct read and never client writes", async () => {
      await assertSucceeds(
        db("a")
          .collection("attendance_roster")
          .where("grade", "==", "1st")
          .get(),
      );
      await assertFails(db("s").doc("attendance_roster/m").get());
      await assertFails(
        db("stage").doc("attendance_roster/m").update({ active: false }),
      );
    });
    it("visits writes use backend; query author access requires active", async () => {
      await assertSucceeds(
        db("s").collection("visits").where("khademId", "==", "s").get(),
      );
      await assertFails(
        db("s")
          .doc("visits/new")
          .set({ khademId: "s", makhdomId: "unassigned" }),
      );
      await assertFails(db("s").doc("visits/v").update({ notes: "bypass" }));
    });
    it("attendance completion must use backend; general assigned task completion is field limited", async () => {
      await assertFails(db("s").doc("tasks/t").update({ isCompleted: true }));
      await env.withSecurityRulesDisabled(async (c) =>
        c.firestore().doc("tasks/general").set({
          assignedKhademId: "s",
          grade: "1st",
          type: "general",
          isCompleted: false,
        }),
      );
      await assertSucceeds(
        db("s").doc("tasks/general").update({ isCompleted: true }),
      );
      await assertFails(
        db("s").doc("tasks/general").update({ title: "spoofed" }),
      );
    });
    it("legacy servantId query can read author visits when canonical field is null", async () => {
      await env.withSecurityRulesDisabled(async (c) =>
        c
          .firestore()
          .doc("visits/legacy")
          .set({
            makhdomId: "unassigned",
            grade: "1st",
            khademId: null,
            servantId: "s",
          }),
      );
      await assertSucceeds(
        db("s").collection("visits").where("servantId", "==", "s").get(),
      );
    });
    it("notification recipient may read/mark read, no client creation", async () => {
      await assertSucceeds(
        db("s").doc("notifications/n").update({ isRead: true }),
      );
      await assertFails(
        db("stage").doc("notifications/new").set({ recipientId: "s" }),
      );
    });
  },
);
