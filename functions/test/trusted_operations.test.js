const { describe, it, before, after, beforeEach } = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const tasks = require("../src/tasks");
const visits = require("../src/visits");
const assignments = require("../src/assignments");
const imports = require("../src/imports");
const attendance = require("../src/attendance");
const adminOps = require("../src/admin_operations");

describe(
  "Trusted callable operations with real Firestore transactions",
  { skip: !process.env.FIRESTORE_EMULATOR_HOST },
  () => {
    let db;
    const call = (fn, data, uid = "a") =>
      fn.run(data, { auth: { uid, token: { name: "SPOOFED" } } });
    const put = (path, data) => db.doc(path).set(data);
    const read = async (path) => (await db.doc(path).get()).data();
    const denied = (promise, code = "permission-denied") =>
      assert.rejects(promise, (e) => e.code === code);
    before(() => {
      if (!admin.apps.length)
        admin.initializeApp({ projectId: "demo-efteqad-trusted" });
      db = admin.firestore();
    });
    after(async () => {
      await db.terminate();
      await admin.app().delete();
    });
    beforeEach(async () => {
      const cs = await db.listCollections();
      for (const c of cs) await db.recursiveDelete(c);
      await Promise.all([
        put("khodam/a", {
          role: "gradeAdmin",
          status: "active",
          grade: "1st",
          name: "Admin",
        }),
        put("khodam/s", {
          role: "servant",
          status: "active",
          grade: "1st",
          name: "Servant",
          assignedCount: 1,
        }),
        put("khodam/t", {
          role: "servant",
          status: "active",
          grade: "1st",
          name: "Target",
          assignedCount: 0,
        }),
        put("khodam/other", {
          role: "servant",
          status: "active",
          grade: "2nd",
          name: "Other",
        }),
        put("khodam/p", { role: "pending", status: "pending" }),
        put("khodam/stage", {
          role: "stageAdmin",
          status: "active",
          name: "Stage",
        }),
        put("makhdomeen/m", {
          grade: "1st",
          fullName: "Child",
          active: true,
          assignedKhademId: "s",
          notes: "General",
          visitCount: 0,
        }),
        put("makhdomeen/m2", {
          grade: "2nd",
          fullName: "Other child",
          active: true,
          assignedKhademId: "other",
          visitCount: 0,
        }),
      ]);
    });
    const taskData = {
      title: "Attendance",
      grade: "1st",
      assignedKhademId: "s",
      type: "attendance_khedma",
      dueDate: "2026-10-09",
    };
    // Missing trusted profile enforcement allows pending users to act through Admin SDK.
    it("rejects pending and servant task creation", async () => {
      await denied(
        call(tasks.createTask, { operationId: "p-create", taskData }, "p"),
      );
      await denied(
        call(tasks.createTask, { operationId: "s-create", taskData }, "s"),
      );
    });
    it("task retry keeps one task, trusted names, notification and localized outbox", async () => {
      const data = {
        operationId: "task-create",
        taskData: {
          ...taskData,
          createdByName: "Fake",
          assignedKhademName: "Fake",
        },
      };
      const [one, two] = await Promise.all([
        call(tasks.createTask, data),
        call(tasks.createTask, data),
      ]);
      assert.equal(one.taskId, two.taskId);
      assert.equal((await db.collection("tasks").get()).size, 1);
      const task = await read("tasks/" + one.taskId);
      assert.equal(task.createdByName, "Admin");
      assert.equal(task.assignedKhademName, "Servant");
      const out = await read("notification_outbox/" + one.outboxId);
      assert.equal(out.templateKey, "attendance_khedma");
      assert.equal(out.templateArgs.createdByName, "Admin");
      assert.equal(out.state, "pending");
      assert.equal((await db.collection("notifications").get()).size, 1);
    });
    it("task rejects cross-grade target, invalid type/date and inactive target", async () => {
      await denied(
        call(tasks.createTask, {
          operationId: "wrong-target",
          taskData: { ...taskData, assignedKhademId: "other" },
        }),
      );
      await denied(
        call(tasks.createTask, {
          operationId: "wrong-type",
          taskData: { ...taskData, type: "made-up" },
        }),
        "invalid-argument",
      );
      await denied(
        call(tasks.createTask, {
          operationId: "wrong-date",
          taskData: { ...taskData, dueDate: "bad" },
        }),
        "invalid-argument",
      );
      await put("khodam/s", {
        role: "servant",
        grade: "1st",
        status: "deleting",
      });
      await denied(
        call(tasks.createTask, { operationId: "inactive", taskData }),
      );
    });
    it("visits deny pending and unassigned child access", async () => {
      await denied(
        call(
          visits.recordVisit,
          { makhdomId: "m", visitDate: "2026-10-09", operationId: "p-visit" },
          "p",
        ),
      );
      await denied(
        call(
          visits.recordVisit,
          { makhdomId: "m2", visitDate: "2026-10-09", operationId: "s-visit" },
          "s",
        ),
      );
    });
    it("concurrent visit retry stores one canonical visit and clears latest empty report", async () => {
      await db.doc("makhdomeen/m").update({ lastVisitNotes: "Old report" });
      const data = {
        makhdomId: "m",
        visitDate: "2026-10-09",
        notes: "",
        operationId: "same-visit",
      };
      const [one, two] = await Promise.all([
        call(visits.recordVisit, data, "s"),
        call(visits.recordVisit, data, "s"),
      ]);
      assert.equal(one.visitId, two.visitId);
      assert.equal((await db.collection("visits").get()).size, 1);
      const m = await read("makhdomeen/m");
      assert.equal(m.visitCount, 1);
      assert.equal(m.lastVisitNotes, null);
      assert.equal(m.notes, "General");
      const v = await read("visits/" + one.visitId);
      assert.equal(v.khademId, "s");
      assert.equal(v.grade, "1st");
      assert.equal(v.makhdomName, "Child");
    });
    it("visit equal date uses comparable createdAt before id; old edits preserve latest", async () => {
      const date = admin.firestore.Timestamp.fromDate(new Date("2026-10-09"));
      assert.equal(
        visits.isVisitNewest({
          newVisitDate: date,
          currentLastVisitDate: date,
          newCreatedAt: admin.firestore.Timestamp.fromMillis(200),
          currentCreatedAt: admin.firestore.Timestamp.fromMillis(100),
          newId: "a",
          currentId: "z",
        }),
        true,
      );
      const old = await call(
        visits.recordVisit,
        {
          makhdomId: "m",
          visitDate: "2026-10-01",
          notes: "Old",
          operationId: "old",
        },
        "s",
      );
      const latest = await call(
        visits.recordVisit,
        {
          makhdomId: "m",
          visitDate: "2026-10-09",
          notes: "Latest",
          operationId: "latest",
        },
        "s",
      );
      await call(
        visits.updateVisitNotes,
        { visitId: old.visitId, notes: "Changed" },
        "s",
      );
      assert.equal((await read("makhdomeen/m")).lastVisitNotes, "Latest");
      await call(
        visits.updateVisitNotes,
        { visitId: latest.visitId, notes: "" },
        "s",
      );
      assert.equal((await read("makhdomeen/m")).lastVisitNotes, null);
      await db.doc("khodam/s").update({ status: "deleting" });
      await denied(
        call(
          visits.updateVisitNotes,
          { visitId: latest.visitId, notes: "No" },
          "s",
        ),
      );
    });
    it("visit malformed date produces an invalid argument without writing", async () => {
      await denied(
        call(
          visits.recordVisit,
          { makhdomId: "m", visitDate: "bad", operationId: "bad" },
          "s",
        ),
        "invalid-argument",
      );
      assert.equal((await db.collection("visits").get()).size, 0);
    });
    it("assignment deduplicates ids and returns item results with correct counters", async () => {
      const data = {
        ids: ["m", "m", "missing"],
        targetKhademId: "t",
        expectedAssignments: { m: "s", missing: null },
        operationId: "assign",
      };
      const result = await call(assignments.assignMakhdoms, data);
      assert.equal(result.assignedCount, 1);
      assert.equal(result.results.length, 2);
      assert.equal(
        result.results.find((x) => x.id === "missing").status,
        "not-found",
      );
      assert.equal((await read("khodam/s")).assignedCount, 0);
      assert.equal((await read("khodam/t")).assignedCount, 1);
      assert.deepEqual(Object.keys(await read("attendance_roster/m")).sort(), [
        "active",
        "fullName",
        "grade",
        "id",
      ]);
      await call(assignments.assignMakhdoms, data);
      assert.equal((await read("khodam/t")).assignedCount, 1);
    });
    it("assignment rejects omitted expectations and inactive/cross-grade target", async () => {
      await denied(
        call(assignments.assignMakhdoms, {
          ids: ["m"],
          targetKhademId: "t",
          operationId: "no-expect",
        }),
        "invalid-argument",
      );
      await denied(
        call(assignments.assignMakhdoms, {
          ids: ["m"],
          targetKhademId: "other",
          expectedAssignments: { m: "s" },
          operationId: "cross",
        }),
      );
      await db.doc("khodam/t").update({ status: "deleting" });
      await denied(
        call(assignments.assignMakhdoms, {
          ids: ["m"],
          targetKhademId: "t",
          expectedAssignments: { m: "s" },
          operationId: "inactive",
        }),
      );
    });
    it("archive is idempotent and decrements assignment once with inactive roster", async () => {
      assert.equal(typeof assignments.archiveMakhdom, "function");
      await call(assignments.archiveMakhdom, {
        makhdomId: "m",
        operationId: "archive",
      });
      await call(assignments.archiveMakhdom, {
        makhdomId: "m",
        operationId: "archive",
      });
      assert.equal((await read("khodam/s")).assignedCount, 0);
      assert.equal((await read("makhdomeen/m")).active, false);
      assert.equal((await read("attendance_roster/m")).active, false);
    });
    it("import own grade resumes ledger without overwriting later edits", async () => {
      const data = {
        importId: "fixed-import",
        grade: "1st",
        rows: [
          { fullName: "Imported", phone: "0123" },
          { fullName: "", phone: "1" },
        ],
      };
      const first = await call(imports.importRows, data);
      assert.equal(first.imported, 1);
      assert.equal(first.rejected, 1);
      const snap = await db
        .collection("makhdomeen")
        .where("importId", "==", "fixed-import")
        .get();
      const id = snap.docs[0].id;
      await db
        .doc("makhdomeen/" + id)
        .update({ fullName: "Edited", visitCount: 7, assignedKhademId: "s" });
      await call(imports.importRows, data);
      assert.equal((await read("makhdomeen/" + id)).fullName, "Edited");
      assert.equal((await read("makhdomeen/" + id)).visitCount, 7);
      assert.equal((await db.collection("imports").get()).size, 1);
      assert.equal(
        (
          await db
            .collection("imports")
            .doc("a_fixed-import")
            .collection("rows")
            .get()
        ).size,
        2,
      );
      assert.equal(
        (await read("attendance_roster/" + id)).fullName,
        "Imported",
      );
    });
    it("import rejects other grade and unsafe dates", async () => {
      await denied(
        call(imports.importRows, {
          importId: "cross",
          grade: "2nd",
          rows: [{ fullName: "Name", phone: "1" }],
        }),
      );
      const result = await call(imports.importRows, {
        importId: "bad-date",
        grade: "1st",
        rows: [{ fullName: "Name", phone: "1", birthDate: "bad" }],
      });
      assert.equal(result.rejected, 1);
    });
    it("presence concurrent first saves keeps both ids and finalize locks later mutation", async () => {
      assert.equal(typeof attendance.setAttendancePresence, "function");
      await put("makhdomeen/n", {
        grade: "1st",
        fullName: "Second",
        active: true,
        assignedKhademId: "t",
      });
      const t = await call(tasks.createTask, {
        taskData,
        operationId: "attendance-task",
      });
      const base = {
        sessionId: "2026-10-09_khedma_1st",
        grade: "1st",
        taskId: t.taskId,
        date: "2026-10-09",
        type: "khedma",
        isPresent: true,
      };
      await Promise.all([
        call(
          attendance.setAttendancePresence,
          { ...base, makhdomId: "m", operationId: "presence-m" },
          "s",
        ),
        call(
          attendance.setAttendancePresence,
          { ...base, makhdomId: "n", operationId: "presence-n" },
          "s",
        ),
      ]);
      assert.deepEqual(
        (
          await read("attendance/" + base.sessionId + "/grades/1st")
        ).attendedMakhdomIds.sort(),
        ["m", "n"],
      );
      await call(
        attendance.finalizeAttendance,
        { sessionId: base.sessionId, grade: "1st", taskId: t.taskId },
        "s",
      );
      assert.equal((await read("tasks/" + t.taskId)).isCompleted, true);
      await denied(
        call(
          attendance.setAttendancePresence,
          {
            ...base,
            makhdomId: "m",
            isPresent: false,
            operationId: "after-finalize",
          },
          "s",
        ),
        "failed-precondition",
      );
    });
    it("presence verifies actual child grade, task scope and date", async () => {
      assert.equal(typeof attendance.setAttendancePresence, "function");
      const t = await call(tasks.createTask, {
        taskData,
        operationId: "attendance-task",
      });
      const base = {
        sessionId: "2026-10-09_khedma_1st",
        grade: "1st",
        taskId: t.taskId,
        date: "2026-10-09",
        type: "khedma",
        isPresent: true,
        makhdomId: "m2",
      };
      await denied(
        call(
          attendance.setAttendancePresence,
          { ...base, operationId: "wrong-child" },
          "s",
        ),
      );
      await denied(
        call(
          attendance.setAttendancePresence,
          {
            ...base,
            sessionId: "2026-10-10_khedma_1st",
            makhdomId: "m",
            date: "2026-10-10",
            operationId: "wrong-date",
          },
          "s",
        ),
      );
    });
    it("finalize refuses arbitrary task completion and pending actors", async () => {
      await put("attendance/session/grades/1st", {
        grade: "1st",
        type: "khedma",
        date: admin.firestore.Timestamp.fromDate(new Date("2026-10-09")),
        status: "draft",
        attendedMakhdomIds: [],
      });
      await put("tasks/unrelated", {
        type: "general",
        grade: "1st",
        assignedKhademId: "s",
        isCompleted: false,
      });
      await denied(
        call(attendance.finalizeAttendance, {
          sessionId: "session",
          grade: "1st",
          taskId: "unrelated",
        }),
      );
      assert.equal((await read("tasks/unrelated")).isCompleted, false);
      await denied(
        call(
          attendance.finalizeAttendance,
          { sessionId: "session", grade: "1st" },
          "p",
        ),
      );
    });
    it("all mass scope reads minimal roster and splits coherent finalized grade parts", async () => {
      assert.equal(typeof attendance.getAttendanceRoster, "function");
      assert.equal(typeof attendance.setAttendancePresence, "function");
      const t = await call(
        tasks.createTask,
        {
          operationId: "mass-task",
          taskData: { ...taskData, grade: "all", type: "attendance_qoddas" },
        },
        "stage",
      );
      await put("attendance_roster/m", {
        id: "m",
        fullName: "Child",
        grade: "1st",
        active: true,
      });
      await put("attendance_roster/m2", {
        id: "m2",
        fullName: "Other child",
        grade: "2nd",
        active: true,
      });
      const roster = await call(
        attendance.getAttendanceRoster,
        { taskId: t.taskId },
        "s",
      );
      assert.equal(roster.rows.length, 2);
      assert.deepEqual(Object.keys(roster.rows[0]).sort(), [
        "active",
        "fullName",
        "grade",
        "id",
      ]);
      await denied(
        call(attendance.getAttendanceRoster, { taskId: t.taskId }, "other"),
      );
      const base = {
        sessionId: "2026-10-09_qoddas_all",
        grade: "all",
        taskId: t.taskId,
        date: "2026-10-09",
        type: "qoddas",
        isPresent: true,
      };
      await call(
        attendance.setAttendancePresence,
        { ...base, makhdomId: "m2", operationId: "mass-presence" },
        "s",
      );
      await call(
        attendance.finalizeAttendance,
        { sessionId: base.sessionId, grade: "all", taskId: t.taskId },
        "s",
      );
      const root = await read("attendance/" + base.sessionId);
      assert.equal(root.status, "finalized");
      assert.deepEqual(root.attendedMakhdomIds, ["m2"]);
      for (const grade of ["1st", "2nd", "3rd"]) {
        const part = await read(
          "attendance/" + base.sessionId + "/grades/" + grade,
        );
        assert.equal(part.status, "finalized");
        assert.equal(part.grade, grade);
      }
    });
    it("save profile preserves counters and maintains minimal roster", async () => {
      assert.equal(typeof assignments.saveMakhdomProfile, "function");
      await call(
        assignments.saveMakhdomProfile,
        {
          makhdomId: "m",
          patch: { phone: "new", photoUrl: null },
          operationId: "profile",
        },
        "s",
      );
      const m = await read("makhdomeen/m");
      assert.equal(m.phone, "new");
      assert.equal(m.visitCount, 0);
      assert.equal(m.assignedKhademId, "s");
      assert.equal(m.photoUrl, undefined);
      assert.deepEqual(await read("attendance_roster/m"), {
        id: "m",
        fullName: "Child",
        grade: "1st",
        active: true,
      });
      await denied(
        call(
          assignments.saveMakhdomProfile,
          { makhdomId: "m", patch: { visitCount: 10 } },
          "s",
        ),
        "invalid-argument",
      );
      await denied(
        call(
          assignments.saveMakhdomProfile,
          { makhdomId: "m2", patch: { phone: "hack" } },
          "s",
        ),
      );
      const one = await call(assignments.saveMakhdomProfile, {
        patch: { fullName: "New", grade: "1st", phone: "1" },
        operationId: "create-child",
      });
      const two = await call(assignments.saveMakhdomProfile, {
        patch: { fullName: "New", grade: "1st", phone: "1" },
        operationId: "create-child",
      });
      assert.equal(one.makhdomId, two.makhdomId);
    });
    it("administrative roles never reactivate deleting targets or demote stage administrators", async () => {
      await db.doc("khodam/s").update({ status: "deleting" });
      await denied(
        call(adminOps.setKhademGrade, { khademId: "s", grade: "2nd" }, "stage"),
      );
      await denied(
        call(
          adminOps.setGradeAdmin,
          { khademId: "stage", grade: "1st" },
          "stage",
        ),
      );
    });
    for (const scope of [
      {
        grade: "1st",
        type: "khedma",
        taskType: "attendance_khedma",
        adminUid: "a",
      },
      {
        grade: "all",
        type: "qoddas",
        taskType: "attendance_qoddas",
        adminUid: "stage",
      },
    ]) {
      it(`presence without taskId preserves ${scope.grade} attachment and finalization completes task`, async () => {
        const task = await call(
          tasks.createTask,
          {
            operationId: "attachment-task",
            taskData: { ...taskData, grade: scope.grade, type: scope.taskType },
          },
          scope.adminUid,
        );
        const base = {
          sessionId: `2026-10-09_${scope.type}_${scope.grade}`,
          grade: scope.grade,
          date: "2026-10-09",
          type: scope.type,
          makhdomId: "m",
          isPresent: true,
        };
        await call(
          attendance.setAttendancePresence,
          { ...base, taskId: task.taskId, operationId: "initial-presence" },
          "s",
        );
        await call(
          attendance.setAttendancePresence,
          { ...base, isPresent: false, operationId: "admin-edit" },
          scope.adminUid,
        );
        assert.equal(
          (await read("attendance/" + base.sessionId)).taskId,
          task.taskId,
        );
        for (const grade of scope.grade === "all"
          ? ["1st", "2nd", "3rd"]
          : ["1st"])
          assert.equal(
            (await read("attendance/" + base.sessionId + "/grades/" + grade))
              .taskId,
            task.taskId,
          );
        await call(
          attendance.finalizeAttendance,
          { sessionId: base.sessionId, grade: scope.grade },
          "s",
        );
        assert.equal((await read("tasks/" + task.taskId)).isCompleted, true);
      });
      it(`presence cannot replace ${scope.grade} attachment after omitted-ID edit`, async () => {
        const make = (operationId) =>
          call(
            tasks.createTask,
            {
              operationId,
              taskData: {
                ...taskData,
                grade: scope.grade,
                type: scope.taskType,
              },
            },
            scope.adminUid,
          );
        const one = await make("task-one"),
          two = await make("task-two");
        const base = {
          sessionId: `2026-10-09_${scope.type}_${scope.grade}`,
          grade: scope.grade,
          date: "2026-10-09",
          type: scope.type,
          makhdomId: "m",
          isPresent: true,
        };
        await call(
          attendance.setAttendancePresence,
          { ...base, taskId: one.taskId, operationId: "with-one" },
          "s",
        );
        await call(
          attendance.setAttendancePresence,
          { ...base, operationId: "without-id" },
          scope.adminUid,
        );
        await denied(
          call(
            attendance.setAttendancePresence,
            { ...base, taskId: two.taskId, operationId: "replace" },
            scope.adminUid,
          ),
          "invalid-argument",
        );
        assert.equal(
          (await read("attendance/" + base.sessionId)).taskId,
          one.taskId,
        );
        assert.equal((await read("tasks/" + two.taskId)).isCompleted, false);
      });
      for (const emptyRoster of [false, true]) {
        it(`zero-attendee ${scope.grade} task finalizes with ${emptyRoster ? "empty" : "populated"} roster`, async () => {
          const task = await call(
            tasks.createTask,
            {
              operationId: "zero-task",
              taskData: {
                ...taskData,
                grade: scope.grade,
                type: scope.taskType,
              },
            },
            scope.adminUid,
          );
          if (emptyRoster) {
            await db.recursiveDelete(db.collection("makhdomeen"));
          } else
            await put("attendance_roster/m", {
              id: "m",
              fullName: "Child",
              grade: "1st",
              active: true,
            });
          const payload = {
            sessionId: `2026-10-09_${scope.type}_${scope.grade}`,
            grade: scope.grade,
            taskId: task.taskId,
          };
          const result = await call(
            attendance.finalizeAttendance,
            payload,
            "s",
          );
          assert.equal(result.status, "finalized");
          const root = await read("attendance/" + payload.sessionId);
          assert.equal(root.taskId, task.taskId);
          assert.deepEqual(root.attendedMakhdomIds, []);
          assert.equal(root.status, "finalized");
          assert.equal(root.type, scope.type);
          for (const grade of scope.grade === "all"
            ? ["1st", "2nd", "3rd"]
            : ["1st"]) {
            const part = await read(
              "attendance/" + payload.sessionId + "/grades/" + grade,
            );
            assert.equal(part.status, "finalized");
            assert.equal(part.grade, grade);
            assert.deepEqual(part.attendedMakhdomIds, []);
            assert.equal(part.taskId, task.taskId);
          }
          assert.equal((await read("tasks/" + task.taskId)).isCompleted, true);
          assert.equal(
            (await call(attendance.finalizeAttendance, payload, "s"))
              .idempotent,
            true,
          );
        });
      }
    }
    it("empty-session finalization rejects arbitrary dates, task types and unassigned actor", async () => {
      const task = await call(tasks.createTask, {
        operationId: "empty-valid-task",
        taskData,
      });
      await denied(
        call(
          attendance.finalizeAttendance,
          {
            sessionId: "2026-10-10_khedma_1st",
            grade: "1st",
            taskId: task.taskId,
          },
          "s",
        ),
        "invalid-argument",
      );
      await denied(
        call(
          attendance.finalizeAttendance,
          {
            sessionId: "2026-10-09_khedma_1st",
            grade: "1st",
            taskId: task.taskId,
          },
          "t",
        ),
      );
      const general = await call(tasks.createTask, {
        operationId: "general-task",
        taskData: { ...taskData, type: "general" },
      });
      await denied(
        call(
          attendance.finalizeAttendance,
          {
            sessionId: "2026-10-09_khedma_1st",
            grade: "1st",
            taskId: general.taskId,
          },
          "s",
        ),
      );
      assert.equal((await db.collection("attendance").get()).size, 0);
      assert.equal((await read("tasks/" + task.taskId)).isCompleted, false);
    });
    it("inactive stage administrators cannot change roles", async () => {
      await db.doc("khodam/stage").update({ status: "deleting" });
      await denied(
        call(adminOps.setKhademGrade, { khademId: "s", grade: "2nd" }, "stage"),
      );
    });
  },
);
