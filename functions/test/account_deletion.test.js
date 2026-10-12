const test = require("node:test");
const assert = require("node:assert/strict");
const { validateDeletionEligibility } = require("../src/account_deletion");
test("Deletion eligibility requires active profile and successor for stage administrators", () => {
  assert.equal(
    validateDeletionEligibility(
      { role: "servant", status: "active", grade: "1st" },
      0,
    ),
    true,
  );
  assert.throws(
    () =>
      validateDeletionEligibility({ role: "stageAdmin", status: "active" }, 0),
    (e) => e.reason === "STAGE_ADMIN_REQUIRES_SUCCESSOR",
  );
  assert.equal(
    validateDeletionEligibility({ role: "stageAdmin", status: "active" }, 1),
    true,
  );
  assert.throws(
    () =>
      validateDeletionEligibility({ role: "pending", status: "pending" }, 1),
    (e) => e.code === "permission-denied",
  );
});
