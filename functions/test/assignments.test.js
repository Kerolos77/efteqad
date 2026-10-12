const { describe, it } = require('node:test');
const assert = require('node:assert');
const {
  calculateAssignmentDeltas,
  checkAssignmentConflicts,
} = require('../src/assignments');

describe('Assignment Delta & Conflict Logic Tests', () => {
  it('correctly calculates delta when reassigning between khodam', () => {
    const makhdomeen = [
      { id: 'm1', assignedKhademId: 'khademA' },
      { id: 'm2', assignedKhademId: 'khademA' },
      { id: 'm3', assignedKhademId: 'khademB' },
      { id: 'm4', assignedKhademId: null },
    ];

    const deltas = calculateAssignmentDeltas(makhdomeen, 'khademC');

    // khademA lost 2, khademB lost 1, khademC gained 4
    assert.strictEqual(deltas['khademA'], -2);
    assert.strictEqual(deltas['khademB'], -1);
    assert.strictEqual(deltas['khademC'], 4);
  });

  it('correctly calculates delta when unassigning', () => {
    const makhdomeen = [
      { id: 'm1', assignedKhademId: 'khademA' },
      { id: 'm2', assignedKhademId: 'khademA' },
    ];

    const deltas = calculateAssignmentDeltas(makhdomeen, null);

    assert.strictEqual(deltas['khademA'], -2);
    assert.strictEqual(deltas['khademC'], undefined);
  });

  it('detects conflict when current assignment differs from expected', () => {
    const expectedAssignments = {
      m1: 'khademA',
      m2: null,
    };

    const currentMakhdomeen = [
      { id: 'm1', assignedKhademId: 'khademB' }, // Changed concurrently!
      { id: 'm2', assignedKhademId: null },
    ];

    const conflict = checkAssignmentConflicts(currentMakhdomeen, expectedAssignments);

    assert.notStrictEqual(conflict, null);
    assert.strictEqual(conflict.id, 'm1');
    assert.strictEqual(conflict.expected, 'khademA');
    assert.strictEqual(conflict.current, 'khademB');
  });

  it('returns null when current assignments match expected', () => {
    const expectedAssignments = {
      m1: 'khademA',
      m2: null,
    };

    const currentMakhdomeen = [
      { id: 'm1', assignedKhademId: 'khademA' },
      { id: 'm2', assignedKhademId: null },
    ];

    const conflict = checkAssignmentConflicts(currentMakhdomeen, expectedAssignments);
    assert.strictEqual(conflict, null);
  });
});

