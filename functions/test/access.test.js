const { describe, it } = require('node:test');
const assert = require('node:assert');
const { isStageAdmin, isGradeAdmin, isServantInGrade, authorize } = require('../src/access');

describe('Access and Authorization Matrix Tests', () => {
  const stageAdmin = {
    role: 'stageAdmin',
    status: 'active',
    grade: null,
  };

  const gradeAdmin1st = {
    role: 'gradeAdmin',
    status: 'active',
    grade: '1st',
  };

  const servant2nd = {
    role: 'servant',
    status: 'active',
    grade: '2nd',
  };

  const pendingServant = {
    role: 'pending',
    status: 'pending',
    grade: null,
  };

  it('correctly identifies stageAdmin', () => {
    assert.strictEqual(isStageAdmin(stageAdmin), true);
    assert.strictEqual(isStageAdmin(gradeAdmin1st), false);
    assert.strictEqual(isStageAdmin(pendingServant), false);
    assert.strictEqual(isStageAdmin(null), false);
  });

  it('correctly identifies gradeAdmin for specific grade and denies cross-grade', () => {
    assert.strictEqual(isGradeAdmin(gradeAdmin1st, '1st'), true);
    assert.strictEqual(isGradeAdmin(gradeAdmin1st, '2nd'), false);
    assert.strictEqual(isGradeAdmin(servant2nd, '2nd'), false);
    assert.strictEqual(isGradeAdmin(pendingServant, '1st'), false);
  });

  it('correctly identifies active servant in grade', () => {
    assert.strictEqual(isServantInGrade(servant2nd, '2nd'), true);
    assert.strictEqual(isServantInGrade(servant2nd, '1st'), false);
    assert.strictEqual(isServantInGrade(pendingServant, '1st'), false);
  });

  it('authorizes stageAdmin for all admin operations', () => {
    assert.strictEqual(authorize(stageAdmin, 'setKhademGrade'), true);
    assert.strictEqual(authorize(stageAdmin, 'setGradeAdmin'), true);
    assert.strictEqual(authorize(stageAdmin, 'assignMakhdom', { grade: '1st' }), true);
  });

  it('denies non-stageAdmin from assigning grades or appointing gradeAdmins', () => {
    assert.strictEqual(authorize(gradeAdmin1st, 'setKhademGrade'), false);
    assert.strictEqual(authorize(gradeAdmin1st, 'setGradeAdmin'), false);
    assert.strictEqual(authorize(servant2nd, 'setKhademGrade'), false);
    assert.strictEqual(authorize(pendingServant, 'setKhademGrade'), false);
  });

  it('allows gradeAdmin to manage their own grade only, denies cross-grade', () => {
    assert.strictEqual(authorize(gradeAdmin1st, 'assignMakhdom', { grade: '1st' }), true);
    assert.strictEqual(authorize(gradeAdmin1st, 'assignMakhdom', { grade: '2nd' }), false);
    assert.strictEqual(authorize(gradeAdmin1st, 'assignMakhdom', { grade: '3rd' }), false);
  });

  it('denies pending servants from performing any privileged operations', () => {
    assert.strictEqual(authorize(pendingServant, 'assignMakhdom', { grade: '1st' }), false);
    assert.strictEqual(authorize(pendingServant, 'setKhademGrade'), false);
    assert.strictEqual(authorize(null, 'setKhademGrade'), false);
  });
});
