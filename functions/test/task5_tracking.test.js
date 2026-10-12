const {describe,it,before,after}=require('node:test');
const assert=require('node:assert/strict');
const admin=require('firebase-admin');
const assignments=require('../src/assignments');
const imports=require('../src/imports');
it('import preserves custom secondary label and derives explicit tracking provenance',()=>{
 const result=imports.validateImportRow({fullName:'Child',phone:'010',secondaryType:'other',secondaryTypeCustomLabel:'User school',trackingStartDate:'2026-10-09'},1);
 assert.equal(result.valid,true);assert.equal(result.data.secondaryTypeCustomLabel,'User school');assert.equal(result.data.trackingStartEstimated,false);
});
describe('Task 5 trusted tracking origin',{skip:!process.env.FIRESTORE_EMULATOR_HOST},()=>{
 let db;
 before(async()=>{if(!admin.apps.length)admin.initializeApp({projectId:'demo-efteqad-task5'});db=admin.firestore();await db.doc('khodam/a').set({role:'gradeAdmin',status:'active',grade:'1st',name:'Admin'});await db.doc('makhdomeen/m').set({fullName:'Child',grade:'1st',active:true,trackingStartEstimated:true,createdAtKnown:false});});
 after(async()=>{await db.terminate();await admin.app().delete();});
 it('trusted explicit tracking date clears estimate while preserving unknown createdAt provenance',async()=>{
  await assignments.saveMakhdomProfile.run({makhdomId:'m',operationId:'explicit-date',patch:{trackingStartDate:'2026-10-09',secondaryTypeCustomLabel:'User school'}},{auth:{uid:'a'}});
  const child=(await db.doc('makhdomeen/m').get()).data();assert.equal(child.trackingStartEstimated,false);assert.equal(child.createdAtKnown,false);assert.equal(child.secondaryTypeCustomLabel,'User school');
 });
 it('client cannot override provenance or protected assignment and counters',async()=>{
  for(const key of ['trackingStartEstimated','createdAtKnown','visitCount','assignedKhademId'])await assert.rejects(assignments.saveMakhdomProfile.run({makhdomId:'m',operationId:'spoof-'+key,patch:{[key]:true}},{auth:{uid:'a'}}),e=>e.code==='invalid-argument');
 });
});
