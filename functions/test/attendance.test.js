const { describe, it, before, after } = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const { executeFinalizeAttendance } = require("../src/attendance");
describe(
  "Attendance finalization uses trusted actor profile",
  { skip: !process.env.FIRESTORE_EMULATOR_HOST },
  () => {
    let app, db;
    before(async () => {
      app = admin.initializeApp(
        { projectId: "demo-efteqad-attendance" },
        "attendance-tests",
      );
      db = app.firestore();
      await db
        .doc("khodam/admin")
        .set({ role: "gradeAdmin", grade: "1st", status: "active" });
      await db
        .doc("khodam/servant")
        .set({ role: "servant", grade: "1st", status: "active" });
    });
    after(async () => {
      await db.terminate();
      await app.delete();
    });
    it("rejects forged administrative profile supplied to the business function", async () => {
      await db
        .doc("attendance/forged/grades/1st")
        .set({
          grade: "1st",
          date: "2026-10-09",
          type: "khedma",
          status: "draft",
        });
      await assert.rejects(
        executeFinalizeAttendance({
          db,
          actorUid: "servant",
          actorProfile: { role: "stageAdmin", status: "active" },
          sessionId: "forged",
          grade: "1st",
        }),
        (e) => e.code === "permission-denied",
      );
    });
    it("rejects missing session with trusted own grade administrator", async () => {
      await assert.rejects(
        executeFinalizeAttendance({
          db,
          actorUid: "admin",
          sessionId: "missing",
          grade: "1st",
        }),
        (e) => e.code === "not-found",
      );
    });
    it("rejects mismatched stored grade", async () => {
      await db
        .doc("attendance/wrong/grades/1st")
        .set({ grade: "2nd", status: "draft" });
      await assert.rejects(
        executeFinalizeAttendance({
          db,
          actorUid: "admin",
          sessionId: "wrong",
          grade: "1st",
        }),
        (e) => e.code === "invalid-argument",
      );
    });
    it("finalizes own grade without arbitrary task and mirrors aggregate", async () => {
      await db
        .doc("attendance/valid/grades/1st")
        .set({
          grade: "1st",
          date: "2026-10-09",
          type: "khedma",
          status: "draft",
          attendedMakhdomIds: ["m"],
        });
      await executeFinalizeAttendance({
        db,
        actorUid: "admin",
        sessionId: "valid",
        grade: "1st",
      });
      const root = (await db.doc("attendance/valid").get()).data();
      assert.equal(root.status, "finalized");
      assert.deepEqual(root.attendedMakhdomIds, ["m"]);
    });
  },
);
