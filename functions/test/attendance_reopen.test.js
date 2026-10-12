const { describe, it, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const attendance = require('../src/attendance');
describe('Administrative attendance reopen transaction', {skip: !process.env.FIRESTORE_EMULATOR_HOST}, () => {
  let db;
  const call = (name, data, uid = 'a') => attendance[name].run(data, {auth: {uid, token: {}}});
  const read = async path => (await db.doc(path).get()).data();
  const payload = {sessionId:'2026-10-09_khedma_1st',grade:'1st',reason:'Correct roster',operationId:'reopen-1'};
  before(() => {
    if (!admin.apps.length) admin.initializeApp({projectId:'demo-efteqad-reopen'});
    db = admin.firestore();
  });
  after(async () => {await db.terminate(); await admin.app().delete();});
  beforeEach(async () => {
    for (const c of await db.listCollections()) await db.recursiveDelete(c);
    for (const [id, role, grade, status] of [['a','gradeAdmin','1st','active'],['stage','stageAdmin',null,'active'],['other','gradeAdmin','2nd','active'],['s','servant','1st','active'],['p','pending',null,'pending'],['d','gradeAdmin','1st','deleting']]) {
      await db.doc('khodam/'+id).set({role,grade,status});
    }
    const date = admin.firestore.Timestamp.fromDate(new Date('2026-10-09'));
    await db.doc('tasks/t').set({grade:'1st',type:'attendance_khedma',dueDate:date,assignedKhademId:'s',status:'completed',isCompleted:true,completedById:'s',completedAt:date});
    const session = {sessionId:payload.sessionId,grade:'1st',date,type:'khedma',status:'finalized',taskId:'t',attendedMakhdomIds:['m'],finalizedAt:date,finalizedByKhademId:'s'};
    await db.doc('attendance/'+payload.sessionId).set(session);
    await db.doc('attendance/'+payload.sessionId+'/grades/1st').set(session);
  });
  it('reopens own scope, preserves presence and immutable prior finalization audit; retry does not reopen after finalize again', async () => {
    await call('reopenAttendance',payload);
    assert.equal((await read('attendance/'+payload.sessionId)).status,'draft');
    assert.equal((await read('attendance/'+payload.sessionId+'/grades/1st')).status,'draft');
    assert.deepEqual((await read('attendance/'+payload.sessionId)).attendedMakhdomIds,['m']);
    assert.equal((await read('tasks/t')).isCompleted,false);
    const audits = await db.collection('attendance/'+payload.sessionId+'/audit').get();
    assert.equal(audits.size,1);
    const audit = audits.docs[0].data();
    assert.equal(audit.actorUid,'a'); assert.equal(audit.reason,'Correct roster'); assert.equal(audit.operationId,'reopen-1');
    assert.ok(audit.createdAt instanceof admin.firestore.Timestamp);
    assert.equal(audit.previousRoot.finalizedByKhademId,'s');
    assert.ok(audit.previousRoot.finalizedAt instanceof admin.firestore.Timestamp);
    assert.equal(audit.previousParts[0].status,'finalized');
    assert.equal((await read('attendance/'+payload.sessionId)).finalizedAt,undefined);
    await call('finalizeAttendance',{sessionId:payload.sessionId,grade:'1st',taskId:'t'});
    const retry = await call('reopenAttendance',payload);
    assert.equal(retry.idempotent,true);
    assert.equal((await read('attendance/'+payload.sessionId)).status,'finalized');
    assert.equal((await db.collection('attendance/'+payload.sessionId+'/audit').get()).size,1);
    assert.deepEqual((await read('attendance/'+payload.sessionId)).attendedMakhdomIds,['m']);
    await assert.rejects(call('reopenAttendance',{...payload,reason:'Changed reason'}), e=>e.code==='invalid-argument');
  });
  it('denies servant, pending, deleting and cross-grade actors including retries', async () => {
    for (const uid of ['s','p','d','other']) await assert.rejects(call('reopenAttendance',payload,uid),e=>e.code==='permission-denied');
    await call('reopenAttendance',payload);
    await db.doc('khodam/a').update({grade:'2nd'});
    await assert.rejects(call('reopenAttendance',payload),e=>e.code==='permission-denied');
  });
  it('stage admin reopens all mass parts atomically; grade admin cannot reopen all root or one of its parts', async () => {
    const id='2026-10-09_qoddas_all', date=admin.firestore.Timestamp.fromDate(new Date('2026-10-09'));
    const root={sessionId:id,grade:'all',type:'qoddas',date,status:'finalized',taskId:'mass',attendedMakhdomIds:['m','n']};
    await db.doc('attendance/'+id).set(root);
    await db.doc('tasks/mass').set({grade:'all',type:'attendance_qoddas',dueDate:date,isCompleted:true,status:'completed'});
    for (const grade of ['1st','2nd','3rd']) await db.doc('attendance/'+id+'/grades/'+grade).set({...root,grade,attendedMakhdomIds:grade==='1st'?['m']:grade==='2nd'?['n']:[]});
    const p={...payload,sessionId:id,grade:'all'};
    await assert.rejects(call('reopenAttendance',p),e=>e.code==='permission-denied');
    await assert.rejects(call('reopenAttendance',{...p,grade:'1st'}),e=>e.code==='permission-denied');
    await call('reopenAttendance',p,'stage');
    for (const grade of ['1st','2nd','3rd']) assert.equal((await read('attendance/'+id+'/grades/'+grade)).status,'draft');
    assert.equal((await read('tasks/mass')).status,'active');
    await call('finalizeAttendance',{sessionId:id,grade:'all'},'stage');
    assert.deepEqual((await read('attendance/'+id)).attendedMakhdomIds,['m','n']);
  });
  it('rejects empty reason and contradictory linked task without partial transition', async () => {
    await assert.rejects(call('reopenAttendance',{...payload,reason:' '}),e=>e.code==='invalid-argument');
    await db.doc('tasks/t').update({grade:'2nd'});
    await assert.rejects(call('reopenAttendance',payload),e=>e.code==='failed-precondition');
    assert.equal((await read('attendance/'+payload.sessionId)).status,'finalized');
    assert.equal((await db.collection('attendance/'+payload.sessionId+'/audit').get()).size,0);
  });
  it('rejects cancelled task and inconsistent parts, and does not replay a changed session link', async () => {
    await db.doc('tasks/t').update({status:'cancelled'});
    await assert.rejects(call('reopenAttendance',payload),e=>e.code==='failed-precondition');
    await db.doc('tasks/t').update({status:'completed'});
    await db.doc('attendance/'+payload.sessionId+'/grades/1st').update({taskId:'wrong'});
    await assert.rejects(call('reopenAttendance',payload),e=>e.code==='failed-precondition');
    await db.doc('attendance/'+payload.sessionId+'/grades/1st').update({taskId:'t'});
    await Promise.all([call('reopenAttendance',payload),call('reopenAttendance',payload)]);
    assert.equal((await db.collection('attendance/'+payload.sessionId+'/audit').get()).size,1);
    await db.doc('attendance/'+payload.sessionId).update({taskId:'replacement'});
    await assert.rejects(call('reopenAttendance',payload),e=>e.code==='failed-precondition');
  });
});
