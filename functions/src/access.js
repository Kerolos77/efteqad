const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const crypto = require("node:crypto");
const GRADES = ["1st", "2nd", "3rd"];
const fail = (code, message) => {
  throw new functions.https.HttpsError(code, message);
};
function isStageAdmin(p) {
  return Boolean(p && p.role === "stageAdmin" && p.status === "active");
}
function isGradeAdmin(p, grade) {
  return Boolean(
    p && p.role === "gradeAdmin" && p.status === "active" && p.grade === grade,
  );
}
function isServantInGrade(p, grade) {
  return Boolean(
    p && p.role === "servant" && p.status === "active" && p.grade === grade,
  );
}
function authorize(actor, operation, resource = {}) {
  if (isStageAdmin(actor)) return true;
  return (
    [
      "assignMakhdom",
      "updateGradeMakhdomeen",
      "manage_makhdomeen",
      "createTask",
      "finalizeAttendance",
    ].includes(operation) && isGradeAdmin(actor, resource.grade)
  );
}
function active(p) {
  if (
    !p ||
    p.status !== "active" ||
    !["stageAdmin", "gradeAdmin", "servant"].includes(p.role) ||
    (p.role !== "stageAdmin" && !GRADES.includes(p.grade))
  )
    fail("permission-denied", "Active profile required.");
  return p;
}
function uid(context, expectedUid) {
  if (!context?.auth?.uid) fail("unauthenticated", "Authentication required.");
  if (expectedUid !== undefined && expectedUid !== context.auth.uid)
    fail("permission-denied", "The initiating account changed.");
  return context.auth.uid;
}
async function actorIn(tx, db, actorUid) {
  const snap = await tx.get(db.doc("khodam/" + actorUid));
  return active(snap.exists ? snap.data() : null);
}
function id(value, name = "id") {
  if (
    typeof value !== "string" ||
    !value.trim() ||
    value.includes("/") ||
    value.length > 200
  )
    fail("invalid-argument", name + " must be a document identifier.");
  return value;
}
function date(value, name = "date") {
  const d = value?.toDate
    ? value.toDate()
    : value instanceof Date
      ? value
      : typeof value === "string"
        ? new Date(value)
        : null;
  if (!d || !Number.isFinite(d.getTime()))
    fail("invalid-argument", name + " is invalid.");
  if (
    typeof value === "string" &&
    /^\d{4}-\d{2}-\d{2}/.test(value) &&
    d.toISOString().slice(0, 10) !== value.slice(0, 10)
  )
    fail("invalid-argument", name + " is invalid.");
  return d;
}
function day(value) {
  return date(value).toISOString().slice(0, 10);
}
function childAccess(p, actorUid, child) {
  return (
    isStageAdmin(p) ||
    isGradeAdmin(p, child.grade) ||
    (p.role === "servant" &&
      child.assignedKhademId === actorUid &&
      p.grade === child.grade)
  );
}
function roster(id, child) {
  return {
    id,
    fullName: child.fullName || "",
    grade: child.grade,
    active: child.active !== false,
  };
}
function operation(db, actorUid, kind, operationId) {
  id(operationId, "operationId");
  return db.doc(
    "operations/" +
      crypto
        .createHash("sha256")
        .update(actorUid + "|" + kind + "|" + operationId)
        .digest("hex"),
  );
}
const stamp = () => FieldValue.serverTimestamp();
module.exports = {
  GRADES,
  fail,
  isStageAdmin,
  isGradeAdmin,
  isServantInGrade,
  authorize,
  active,
  uid,
  actorIn,
  id,
  date,
  day,
  childAccess,
  roster,
  operation,
  stamp,
};
