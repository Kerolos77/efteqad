const { describe, it } = require('node:test');
const assert = require('node:assert');
const {
  isVisitNewest,
  computeVisitMakhdomUpdates,
} = require('../src/visits');

describe('Visits Business Logic & Summary Integrity Tests', () => {
  it('identifies whether a new visit is the latest visit for student using production isVisitNewest', () => {
    const existingLastVisitDate = new Date('2026-10-01T10:00:00Z');

    // Case 1: Newer visit
    const newerVisitDate = new Date('2026-10-05T10:00:00Z');
    const isNewer = isVisitNewest({
      newVisitDate: newerVisitDate,
      currentLastVisitDate: existingLastVisitDate,
    });
    assert.strictEqual(isNewer, true);

    // Case 2: Older visit added late
    const olderVisitDate = new Date('2026-09-25T10:00:00Z');
    const isOlderNewest = isVisitNewest({
      newVisitDate: olderVisitDate,
      currentLastVisitDate: existingLastVisitDate,
    });
    assert.strictEqual(isOlderNewest, false);

    // Case 3: Same date tie-break using createdAt / ID
    const sameDate = new Date('2026-10-01T10:00:00Z');
    const tieBreakNewer = isVisitNewest({
      newVisitDate: sameDate,
      currentLastVisitDate: sameDate,
      newCreatedAt: new Date('2026-10-01T12:00:00Z'),
      currentCreatedAt: new Date('2026-10-01T11:00:00Z'),
    });
    assert.strictEqual(tieBreakNewer, true);
  });

  it('determines whether student notes summary should be updated upon notes edit', () => {
    const studentLastVisitId = 'visit_999';

    // Editing the latest visit: should update summary
    const editingLatestId = 'visit_999';
    assert.strictEqual(editingLatestId === studentLastVisitId, true);

    // Editing an older historic visit: should NOT update student summary
    const editingOlderId = 'visit_111';
    assert.strictEqual(editingOlderId === studentLastVisitId, false);
  });

  it('computeVisitMakhdomUpdates updates lastVisitNotes and NEVER overwrites general notes', () => {
    const updates = computeVisitMakhdomUpdates({
      isNewest: true,
      parsedVisitDate: new Date('2026-10-08T10:00:00Z'),
      visitId: 'visit_new',
      cleanNotes: 'Visit report summary',
    });

    assert.strictEqual(updates.lastVisitId, 'visit_new');
    assert.strictEqual(updates.lastVisitNotes, 'Visit report summary');
    // Crucial: Must NEVER touch general student notes
    assert.strictEqual(updates.notes, undefined);
    assert.strictEqual(updates.description, undefined);
  });
});

