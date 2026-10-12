const test = require("node:test");
const assert = require("node:assert/strict");
const { validateImportRow, processImportPayload } = require("../src/imports");

test("Excel Imports Business Logic Tests", async (t) => {
  await t.test("rejects rows with missing name or phone", () => {
    const invalidName = validateImportRow({ fullName: "", phone: "01012345678" }, 1);
    assert.equal(invalidName.valid, false);
    assert.match(invalidName.error, /fullName is required/);

    const invalidPhone = validateImportRow({ fullName: "مينا كمال", phone: "" }, 2);
    assert.equal(invalidPhone.valid, false);
    assert.match(invalidPhone.error, /phone is required/);
  });

  await t.test("accepts valid row and normalizes fields", () => {
    const valid = validateImportRow(
      {
        fullName: "  كيرلس رأفت  ",
        phone: "  01234567890  ",
        isBrethrenOfLord: true,
        address: "شبرا",
      },
      1
    );

    assert.equal(valid.valid, true);
    assert.equal(valid.data.fullName, "كيرلس رأفت");
    assert.equal(valid.data.phone, "01234567890");
    assert.equal(valid.data.isBrethrenOfLord, true);
    assert.equal(valid.data.address, "شبرا");
  });

  await t.test("processImportPayload attaches requested grade to all valid rows", () => {
    const rows = [
      { fullName: "طالب أول", phone: "01011111111" },
      { fullName: "طالب ثان", phone: "01022222222" },
      { fullName: "", phone: "01033333333" }, // invalid
    ];

    const result = processImportPayload({
      importId: "import_test_1",
      grade: "2nd",
      rows,
    });

    assert.equal(result.total, 3);
    assert.equal(result.successCount, 2);
    assert.equal(result.failureCount, 1);
    assert.equal(result.validRows[0].grade, "2nd");
    assert.equal(result.validRows[1].grade, "2nd");
    assert.equal(result.validRows[0].importRowIndex, 1);
    assert.equal(result.validRows[1].importRowIndex, 2);
  });

  await t.test("throws when grade is missing or rows are empty", () => {
    assert.throws(() => {
      processImportPayload({ grade: "", rows: [{ fullName: "a", phone: "1" }] });
    }, /grade is required/);

    assert.throws(() => {
      processImportPayload({ grade: "1st", rows: [] });
    }, /rows must be a non-empty array/);
  });
});
