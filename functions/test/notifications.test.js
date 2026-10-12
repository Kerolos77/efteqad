const test = require("node:test");
const assert = require("node:assert/strict");
const { isInvalidTokenError } = require("../src/notifications");
test("Only explicit invalid token errors may remove a device", () => {
  assert.equal(
    isInvalidTokenError({
      code: "messaging/registration-token-not-registered",
    }),
    true,
  );
  assert.equal(
    isInvalidTokenError({ code: "messaging/invalid-registration-token" }),
    true,
  );
  assert.equal(
    isInvalidTokenError({ code: "messaging/invalid-argument" }),
    false,
  );
  assert.equal(
    isInvalidTokenError({ code: "messaging/server-unavailable" }),
    false,
  );
});
