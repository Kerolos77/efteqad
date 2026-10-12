const functions = require("firebase-functions");
const admin = require("firebase-admin");
const A = require("./access");
function setRole(role) {
  return functions.https.onCall(async (data, context) => {
    const actorUid = A.uid(context, data?.expectedUid),
      db = admin.firestore(),
      targetId = A.id(data?.khademId, "khademId"),
      grade = data.grade;
    if (!A.GRADES.includes(grade))
      A.fail("invalid-argument", "Valid grade required");
    return db.runTransaction(async (tx) => {
      const actor = await A.actorIn(tx, db, actorUid);
      if (!A.isStageAdmin(actor))
        A.fail("permission-denied", "Stage administrator required");
      const targetRef = db.doc("khodam/" + targetId),
        targetSnap = await tx.get(targetRef);
      if (!targetSnap.exists) A.fail("not-found", "Target profile not found");
      const target = targetSnap.data();
      if (target.status === "deleting" || target.role === "stageAdmin")
        A.fail(
          "permission-denied",
          "Cannot change deleting or stage administrator profile",
        );
      if (
        target.grade &&
        target.grade !== grade &&
        Number(target.assignedCount) > 0
      )
        A.fail(
          "failed-precondition",
          "Unassign children before grade transfer",
        );
      let existing = [];
      if (role === "gradeAdmin") {
        const current = await tx.get(
          db
            .collection("khodam")
            .where("role", "==", "gradeAdmin")
            .where("grade", "==", grade),
        );
        existing = current.docs;
      }
      for (const current of existing)
        if (current.id !== targetId)
          tx.update(current.ref, { role: "servant" });
      tx.update(targetRef, { role, grade, status: "active" });
      return role === "gradeAdmin"
        ? { success: true, newAdminId: targetId, grade }
        : { success: true, khademId: targetId, grade };
    });
  });
}
exports.setKhademGrade = setRole("servant");
exports.setGradeAdmin = setRole("gradeAdmin");
