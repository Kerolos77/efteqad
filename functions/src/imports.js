const functions = require("firebase-functions");
const admin = require("firebase-admin");
const A = require("./access");
const crypto = require("node:crypto");
function validateImportRow(row, rowIndex) {
  if (!row || typeof row !== "object" || Array.isArray(row))
    return { valid: false, rowIndex, error: "Invalid row format" };
  const text = (k) => (typeof row[k] === "string" ? row[k].trim() : "");
  const fullName = text("fullName"),
    phone = text("phone");
  if (!fullName)
    return { valid: false, rowIndex, error: "fullName is required" };
  if (!phone) return { valid: false, rowIndex, error: "phone is required" };
  let birthDate = null;
  let trackingStartDate = null;
  if (row.trackingStartDate !== undefined && row.trackingStartDate !== null) {
    try {
      if (
        typeof row.trackingStartDate !== "string" ||
        !/^\d{4}-\d{2}-\d{2}(?:T.*)?$/.test(row.trackingStartDate)
      )
        throw Error("Invalid date format");
      trackingStartDate = A.date(row.trackingStartDate, "trackingStartDate");
    } catch (error) {
      return { valid: false, rowIndex, error: "trackingStartDate is invalid" };
    }
  }
  try {
    if (row.birthDate) birthDate = A.date(row.birthDate, "birthDate");
  } catch (e) {
    return { valid: false, rowIndex, error: "birthDate is invalid" };
  }
  return {
    valid: true,
    rowIndex,
    data: {
      fullName,
      phone,
      birthDate,
      trackingStartDate,
      trackingStartEstimated: trackingStartDate === null,
      createdAtKnown: true,
      fatherPhone: text("fatherPhone"),
      motherPhone: text("motherPhone"),
      address: text("address"),
      area: text("area"),
      school: text("school"),
      secondaryType: text("secondaryType"),
      secondaryTypeCustomLabel: text("secondaryTypeCustomLabel") || null,
      homeLocationUrl: text("homeLocationUrl") || null,
      isBrethrenOfLord: row.isBrethrenOfLord === true,
      photoUrl: text("photoUrl") || null,
      notes: text("notes") || null,
    },
  };
}
function processImportPayload({ importId, grade, rows }) {
  if (!A.GRADES.includes(grade))
    throw new Error("grade is required and must be valid");
  if (!Array.isArray(rows) || !rows.length)
    throw new Error("rows must be a non-empty array");
  const validRows = [],
    rejectedRows = [];
  rows.forEach((row, idx) => {
    const v = validateImportRow(row, idx + 1);
    if (v.valid)
      validRows.push({
        ...v.data,
        grade,
        importId: importId || null,
        importRowIndex: idx + 1,
        active: true,
        visitCount: 0,
        lastVisitDate: null,
      });
    else rejectedRows.push(v);
  });
  return {
    validRows,
    rejectedRows,
    total: rows.length,
    successCount: validRows.length,
    failureCount: rejectedRows.length,
  };
}
const importRows = functions.https.onCall(async (data, context) => {
  const actorUid = A.uid(context, data?.expectedUid),
    db = admin.firestore(),
    importId = A.id(data?.importId, "importId"),
    grade = data.grade;
  if (
    !A.GRADES.includes(grade) ||
    !Array.isArray(data.rows) ||
    !data.rows.length ||
    data.rows.length > 5000
  )
    A.fail("invalid-argument", "Valid grade and 1 to 5000 rows required");
  const rootRef = db.doc("imports/" + actorUid + "_" + importId),
    fingerprint = crypto
      .createHash("sha256")
      .update(JSON.stringify({ grade, rows: data.rows }))
      .digest("hex");
  await db.runTransaction(async (tx) => {
    const actor = await A.actorIn(tx, db, actorUid);
    if (!A.authorize(actor, "manage_makhdomeen", { grade }))
      A.fail("permission-denied", "Import scope denied");
    const snap = await tx.get(rootRef);
    if (snap.exists && snap.data().fingerprint !== fingerprint)
      A.fail("failed-precondition", "Import ID belongs to a different payload");
    if (!snap.exists)
      tx.create(rootRef, {
        actorUid,
        grade,
        importId,
        fingerprint,
        total: data.rows.length,
        status: "running",
        createdAt: A.stamp(),
      });
  });
  const results = [];
  for (let index = 0; index < data.rows.length; index++) {
    const rowIndex = index + 1,
      row = validateImportRow(data.rows[index], rowIndex),
      ledger = rootRef.collection("rows").doc(String(rowIndex));
    const childId = crypto
        .createHash("sha256")
        .update(actorUid + "|" + importId + "|" + rowIndex)
        .digest("hex"),
      childRef = db.doc("makhdomeen/" + childId);
    results.push(
      await db.runTransaction(async (tx) => {
        const actor = await A.actorIn(tx, db, actorUid);
        if (!A.authorize(actor, "manage_makhdomeen", { grade }))
          A.fail("permission-denied", "Import scope denied");
        const seen = await tx.get(ledger);
        if (seen.exists) return { ...seen.data().result, resumed: true };
        const existing = row.valid ? await tx.get(childRef) : null;
        const result = row.valid
          ? {
              rowIndex,
              status: existing?.exists ? "existing" : "imported",
              makhdomId: childId,
            }
          : { rowIndex, status: "rejected", error: row.error };
        if (row.valid && !existing.exists) {
          const child = {
            ...row.data,
            grade,
            importId,
            importRowIndex: rowIndex,
            active: true,
            visitCount: 0,
            lastVisitDate: null,
            assignedKhademId: null,
            assignedKhademName: null,
            createdAt: A.stamp(),
          };
          tx.create(childRef, child);
          tx.set(
            db.doc("attendance_roster/" + childId),
            A.roster(childId, child),
          );
        }
        tx.create(ledger, { result, createdAt: A.stamp() });
        return result;
      }),
    );
  }
  await rootRef.update({ status: "complete", completedAt: A.stamp() });
  const rejectedDetails = results.filter((x) => x.status === "rejected");
  return {
    success: true,
    importId,
    total: results.length,
    imported: results.length - rejectedDetails.length,
    rejected: rejectedDetails.length,
    rejectedDetails,
    results,
  };
});
module.exports = { validateImportRow, processImportPayload, importRows };
