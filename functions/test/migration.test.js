const {test, describe, before, after, beforeEach} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const admin = require('firebase-admin');
const M = require('../scripts/migrate_v2');
const B = require('../scripts/bootstrap_admin');
const project = 'demo-efteqad-rules';
test('CLI requires project and rejects conflicting modes and unknown options', () => {
 assert.throws(() => M.parseArgs([]), /project/);
 assert.equal(M.parseArgs(['--project='+project]).dryRun, true);
 assert.throws(() => M.parseArgs(['--project='+project,'--apply','--dry-run']), /mode/);
 assert.throws(() => M.parseArgs(['--project='+project,'--wat']), /Unknown/);
 const result=spawnSync(process.execPath,[path.join(__dirname,'../scripts/migrate_v2.js')],{encoding:'utf8'});assert.notEqual(result.status,0);
});
test('tracking unknown stays unknown, known fallback estimated and explicit date trusted',()=>{
 assert.equal(M.auditStudentVisits({},[]).patch.trackingStartDate,undefined);
 assert.equal(M.auditStudentVisits({},[]).patch.createdAtKnown,false);
 assert.equal(M.auditStudentVisits({createdAt:new Date('2025-01-01')},[]).patch.trackingStartEstimated,true);
 assert.equal(M.auditStudentVisits({trackingStartDate:new Date('2025-01-01')},[]).patch.trackingStartEstimated,false);
});
test('token identity never includes token prefix',()=>{
 const device=M.auditServantDevices({fcmToken:'PRIVATE_TOKEN_VALUE'}).devicesToCreate[0];assert.match(device.installationId,/^legacy_device_[a-f0-9]{64}$/);assert.equal(device.token,'PRIVATE_TOKEN_VALUE');
});
describe('Migration real transactional engine', {skip:!process.env.FIRESTORE_EMULATOR_HOST},()=>{
 let db,app,dir;
 // The Rules suite uses this demo project's default database concurrently.
 // A named emulator database keeps destructive fixture cleanup isolated.
 before(()=>{app=admin.initializeApp({projectId:project},'migration');db=require('firebase-admin/firestore').getFirestore(app,'migration-tests');dir=fs.mkdtempSync(path.join(os.tmpdir(),'efteqad-migration-'));});
 after(async()=>{await db.terminate();await app.delete();fs.rmSync(dir,{recursive:true,force:true});});
 beforeEach(async()=>{for(const c of await db.listCollections())await db.recursiveDelete(c);});
 const options=()=>({project,dryRun:false,checkpointPath:path.join(dir,'checkpoint.json')});
 const put=(p,d)=>db.doc(p).set(d);
 const read=async p=>(await db.doc(p).get()).data();
 async function seed(){
  await put('makhdomeen/m',{fullName:'Private Child',grade:'2nd',visitCount:8,notes:'general note',lastVisitNotes:'mixed',secondaryType:'my custom school',createdAt:admin.firestore.Timestamp.fromDate(new Date('2025-01-01')),assignedKhademId:'s'});
  await put('khodam/s',{role:'servant',status:'active',grade:'2nd',assignedCount:99,fcmToken:'SECRET_TOKEN',email:'private@example.com'});
  await put('visits/a',{makhdomId:'m',servantId:'s',visitDate:'2026-10-09',createdAt:'2026-10-09T10:00:00Z',visitType:'مكالمة هاتفية',notes:'visit'});
  await put('visits/b',{makhdomId:'m',visitDate:'2026-10-09',createdAt:'2026-10-09T11:00:00Z',visitType:'home-ish private label'});
 }
 test('default dry-run changes zero documents and no checkpoint report redacts private values',async()=>{
  await seed();const before=await M.backupFixture(db,{project});const cp=path.join(dir,'dry-checkpoint.json');const report=await M.runMigration(db,{project,checkpointPath:cp});
  assert.equal(report.dryRun,true);assert.deepEqual(await M.backupFixture(db,{project}),before);assert.equal(fs.existsSync(cp),false);
  for(const secret of ['SECRET_TOKEN','private@example.com','Private Child','general note','my custom school'])assert.equal(JSON.stringify(report).includes(secret),false);
 });
 test('apply normalizes aliases counters tuple notes labels roster and hashed device',async()=>{
  await seed();await M.runMigration(db,options());const c=await read('makhdomeen/m');assert.equal(c.visitCount,2);assert.equal(c.lastVisitId,'b');assert.equal(c.notes,'general note');assert.equal(c.legacyNotes,'general note');assert.equal(c.secondaryType,'other');assert.equal(c.secondaryTypeCustomLabel,'my custom school');assert.equal(c.trackingStartEstimated,true);
  const v=await read('visits/a');assert.equal(v.visitType,'phone');assert.equal(v.khademId,'s');assert.equal(v.grade,'2nd');assert.equal(v.visitDate.toDate().toISOString(),'2026-10-09T00:00:00.000Z');assert.equal((await read('visits/b')).legacyVisitType,'home-ish private label');assert.equal((await read('visits/b')).visitType,'home-ish private label');
  assert.equal((await read('khodam/s')).assignedCount,1);assert.deepEqual(Object.keys(await read('attendance_roster/m')).sort(),['active','fullName','grade','id']);const devices=await db.collection('khodam/s/devices').get();assert.equal(devices.size,1);assert.equal(devices.docs[0].data().token,'SECRET_TOKEN');
 });
 test('commit before lost checkpoint resumes without overwriting subsequent edits',async()=>{
  await seed();const opts=options();fs.rmSync(opts.checkpointPath,{force:true});const original=db.runTransaction.bind(db);let crash=true;db.runTransaction=async fn=>{const value=await original(fn);if(crash){crash=false;throw new Error('crash-after-commit');}return value;};
  try{await assert.rejects(M.runMigration(db,opts),/crash-after-commit/);}finally{db.runTransaction=original;}
  await db.doc('visits/a').update({servantId:'fresh-author',khademId:'fresh-author',visitType:'church',notes:'new edit'});await M.runMigration(db,{...opts,resume:true});assert.equal((await read('visits/a')).notes,'new edit');assert.equal((await read('visits/a')).khademId,'fresh-author');
  await db.doc('makhdomeen/m').update({assignedKhademId:'fresh-owner',notes:'fresh notes',visitCount:12});await M.runMigration(db,opts);const c=await read('makhdomeen/m');assert.equal(c.assignedKhademId,'fresh-owner');assert.equal(c.notes,'fresh notes');assert.equal(c.visitCount,12);
 });
 test('checkpoint rejects wrong project version fingerprint invalid cursor before writes',async()=>{
  await seed();await M.runMigration(db,options());const original=fs.readFileSync(options().checkpointPath,'utf8');
  for(const patch of [{project:'another'},{planVersion:999},{fingerprint:'bad'},{lastCursor:'invalid/path/path'},{completedUnits:['malformed']}]){fs.writeFileSync(options().checkpointPath,JSON.stringify({...JSON.parse(original),...patch}));await assert.rejects(M.runMigration(db,{...options(),resume:true}),/checkpoint/i);}
  await assert.rejects(M.runMigration(db,{project:'other',dryRun:false}),/project/i);
 });
 test('trusted historic grades create canonical parts current child grade never fills unknown history',async()=>{
  await put('makhdomeen/m',{grade:'3rd',fullName:'Child'});await put('attendance/legacy',{date:'2025-10-10',type:'khedma',grade:'1st',status:'finalized',attendedMakhdomIds:['m'],taskId:'old-task'});await put('attendance/unknown',{date:'2025-10-17',type:'khedma',attendedMakhdomIds:['m']});
  const report=await M.runMigration(db,options());const p=await read('attendance/2025-10-10_khedma_1st/grades/1st');assert.equal(p.status,'finalized');assert.equal(p.grade,'1st');assert.equal(p.date.toDate().toISOString(),'2025-10-10T00:00:00.000Z');assert.equal(p.taskId,'old-task');assert.equal(p.sessionId,'2025-10-10_khedma_1st');assert.equal((await read('attendance/unknown')).status,'legacyUnknown');assert.equal((await db.doc('attendance/2025-10-17_khedma_3rd').get()).exists,false);assert.ok(report.issues.some(x=>x.id==='unknown'));
 });
 test('conflicting attendance roots reported without silently merging',async()=>{
  for(const [id,ids]of[['one',['m']],['two',['n']]])await put('attendance/'+id,{date:'2025-10-10',type:'khedma',grade:'1st',status:'finalized',attendedMakhdomIds:ids});const report=await M.runMigration(db,options());assert.ok(report.issues.some(x=>x.reason==='conflicting-attendance-target'));assert.equal((await db.doc('attendance/2025-10-10_khedma_1st').get()).exists,false);
 });
 test('archive assignments cleared inactive ignored missing tracking remains unknown',async()=>{
  await put('makhdomeen/arch',{grade:'1st',active:false,assignedKhademId:'s',assignedKhademName:'Owner'});await put('khodam/s',{assignedCount:8});await M.runMigration(db,options());const c=await read('makhdomeen/arch');assert.equal(c.assignedKhademId,null);assert.equal(c.createdAtKnown,false);assert.equal(c.trackingStartDate,undefined);assert.equal((await read('khodam/s')).assignedCount,0);
 });
 test('task attendance alias needs explicit service evidence preserves inactive/history',async()=>{
  await put('tasks/known',{type:'attendance',attendanceType:'khedma',dueDate:'2026-10-09',status:'inactive'});await put('tasks/ambiguous',{type:'attendance',dueDate:'2026-10-09'});const report=await M.runMigration(db,options());assert.equal((await read('tasks/known')).type,'attendance_khedma');assert.equal((await read('tasks/known')).status,'inactive');assert.equal((await read('tasks/ambiguous')).type,'attendance');assert.ok(report.issues.some(x=>x.id==='ambiguous'));
 });
 test('fixture backup restore restores meaningful fields including nested private records',async()=>{
  await seed();await put('khodam/s/devices/existing',{token:'existing',updatedAt:admin.firestore.Timestamp.fromMillis(1234)});const backup=await M.backupFixture(db,{project});await M.runMigration(db,options());await M.restoreFixture(db,backup,{project});assert.deepEqual(await M.backupFixture(db,{project}),backup);await assert.rejects(M.restoreFixture(db,backup,{project:'real-project'}),/demo|project/);
 });
 test('backup codec preserves user maps whose names look like type markers',async()=>{
  await put('makhdomeen/custom',{grade:'1st',custom:{$timestamp:[1,2],$reference:'user text'},bytes:Buffer.from('hello'),point:new admin.firestore.GeoPoint(30,31),ref:db.doc('makhdomeen/custom')});
  const backup=await M.backupFixture(db,{project});await M.restoreFixture(db,backup,{project});const data=await read('makhdomeen/custom');assert.deepEqual(data.custom,{$timestamp:[1,2],$reference:'user text'});assert.equal(data.bytes.toString(),'hello');assert.equal(data.point.latitude,30);assert.equal(data.ref.path,'makhdomeen/custom');
 });
 test('all mass uses historical roster snapshots and preserves valid finalized existing parts',async()=>{
  await put('attendance/2025-10-10_qoddas_all',{date:'2025-10-10',type:'qoddas',grade:'all',status:'finalized',attendedMakhdomIds:['m','n'],rosterSnapshot:[{id:'m',grade:'1st'},{id:'n',grade:'2nd'}],taskId:'t'});
  await put('attendance/2025-10-10_qoddas_all/grades/1st',{sessionId:'2025-10-10_qoddas_all',date:'2025-10-10',type:'qoddas',grade:'1st',status:'finalized',attendedMakhdomIds:['m'],taskId:'t'});
  await M.runMigration(db,options());const second=await read('attendance/2025-10-10_qoddas_all/grades/2nd');assert.ok(second);assert.deepEqual(second.attendedMakhdomIds,['n']);assert.equal(second.grade,'2nd');assert.equal((await read('attendance/2025-10-10_qoddas_all')).status,'finalized');
 });
 test('bootstrap project existing UID and dry-run preserve profile',async()=>{
  assert.throws(()=>B.parseBootstrapArgs(['--uid=real_uid']),/project/);assert.throws(()=>B.validateUid('admin'),/placeholder/);await put('khodam/real_uid',{name:'Existing',notes:'preserve'});await assert.rejects(B.bootstrapAdmin(db,{project,uid:'missing',dryRun:false}),/existing/);await B.bootstrapAdmin(db,{project,uid:'real_uid',dryRun:true});assert.equal((await read('khodam/real_uid')).role,undefined);await B.bootstrapAdmin(db,{project,uid:'real_uid',dryRun:false});assert.equal((await read('khodam/real_uid')).role,'stageAdmin');assert.equal((await read('khodam/real_uid')).notes,'preserve');
 });
 test('review canonical all root produced by real finalizer keeps authoritative finalized parts',async()=>{
  const Attendance=require('../src/attendance');const sessionId='2026-10-09_qoddas_all';
  await put('khodam/a',{role:'stageAdmin',status:'active'});
  await put('attendance/'+sessionId,{sessionId,date:admin.firestore.Timestamp.fromDate(new Date('2026-10-09')),type:'qoddas',grade:'all',status:'draft',attendedMakhdomIds:['m','n']});
  for(const [grade,ids]of [['1st',['m']],['2nd',['n']],['3rd',[]]])await put('attendance/'+sessionId+'/grades/'+grade,{sessionId,date:admin.firestore.Timestamp.fromDate(new Date('2026-10-09')),type:'qoddas',grade,status:'draft',attendedMakhdomIds:ids,taskId:null});
  await Attendance.executeFinalizeAttendance({db,actorUid:'a',sessionId,grade:'all'});
  const rootBefore=await read('attendance/'+sessionId);const partsBefore=await Promise.all(['1st','2nd','3rd'].map(g=>read('attendance/'+sessionId+'/grades/'+g)));
  const report=await M.runMigration(db,options());assert.equal((await read('attendance/'+sessionId)).status,'finalized');assert.deepEqual(await read('attendance/'+sessionId),rootBefore);assert.deepEqual(await Promise.all(['1st','2nd','3rd'].map(g=>read('attendance/'+sessionId+'/grades/'+g))),partsBefore);
  assert.equal(report.issues.some(x=>x.id===sessionId),false);const retry=await Attendance.executeFinalizeAttendance({db,actorUid:'a',sessionId,grade:'all'});assert.equal(retry.idempotent,true);
 });
 test('review canonical all draft root preserves each authoritative part status',async()=>{
  const sessionId='2026-10-09_qoddas_all',base={sessionId,date:admin.firestore.Timestamp.fromDate(new Date('2026-10-09')),type:'qoddas',attendedMakhdomIds:[],taskId:null};
  await put('attendance/'+sessionId,{...base,grade:'all',status:'draft'});
  for(const grade of ['1st','2nd','3rd'])await put('attendance/'+sessionId+'/grades/'+grade,{...base,grade,status:grade==='1st'?'finalized':'draft'});
  await M.runMigration(db,options());assert.equal((await read('attendance/'+sessionId)).status,'draft');assert.equal((await read('attendance/'+sessionId+'/grades/1st')).status,'finalized');assert.equal((await read('attendance/'+sessionId+'/grades/2nd')).status,'draft');
 });
 test('review historical roster and year map derive missing legacy scope without current child grade',async()=>{
  await put('makhdomeen/m',{fullName:'Now third',grade:'3rd'});
  for(const [id,date,evidence]of [['roster','2025-10-10',{rosterSnapshot:[{id:'m',grade:'1st'}]}],['year','2025-10-17',{yearSnapshot:{m:'2nd'}}]]){
   await put('attendance/'+id,{date,type:'khedma',status:'finalized',attendedMakhdomIds:['m'],taskId:'historical',...evidence});
  }
  await M.runMigration(db,options());
  for(const [date,grade]of [['2025-10-10','1st'],['2025-10-17','2nd']]){const sessionId=date+'_khedma_'+grade,p=await read('attendance/'+sessionId+'/grades/'+grade);assert.ok(p);assert.equal(p.grade,grade);assert.equal(p.sessionId,sessionId);assert.equal(p.taskId,'historical');assert.equal(p.status,'finalized');}
 });
 test('review missing scope mass snapshot spanning grades derives all actual parts',async()=>{
  await put('attendance/legacy-mass',{date:'2025-10-10',type:'qoddas',status:'finalized',attendedMakhdomIds:['m','n'],gradesByMakhdomId:{m:'1st',n:'2nd'}});await M.runMigration(db,options());assert.deepEqual((await read('attendance/2025-10-10_qoddas_all/grades/1st')).attendedMakhdomIds,['m']);assert.deepEqual((await read('attendance/2025-10-10_qoddas_all/grades/2nd')).attendedMakhdomIds,['n']);
 });
 test('review incomplete contradictory and service multi-grade snapshots stay unknown',async()=>{
  for(const [id,evidence]of [['incomplete',{yearSnapshot:{m:'1st'}}],['contradictory',{rosterSnapshot:[{id:'m',grade:'1st'},{id:'m',grade:'2nd'},{id:'n',grade:'1st'}]}],['cross-source',{yearSnapshot:{m:'1st',n:'1st'},gradesByMakhdomId:{m:'2nd',n:'2nd'}}],['multi-service',{yearSnapshot:{m:'1st',n:'2nd'}}]])await put('attendance/'+id,{date:'2025-10-10',type:'khedma',status:'finalized',attendedMakhdomIds:['m','n'],...evidence});
  const report=await M.runMigration(db,options());for(const id of ['incomplete','contradictory','cross-source','multi-service']){assert.equal((await read('attendance/'+id)).status,'legacyUnknown');assert.ok(report.issues.some(x=>x.id===id));}assert.equal((await db.collection('attendance/2025-10-10_khedma_1st/grades').get()).empty,true);
 });
 test('review migration retains nanosecond visit tuples and selects newest before ID',async()=>{
  // Firestore persists microsecond resolution; retain every persisted digit.
  const visitDate=new admin.firestore.Timestamp(1700000000,123456000),newer=new admin.firestore.Timestamp(1700000001,900000),older=new admin.firestore.Timestamp(1700000001,600000);
  await put('makhdomeen/m',{grade:'1st'});for(const [id,createdAt]of [['a',newer],['z',older]])await put('visits/'+id,{makhdomId:'m',grade:'1st',khademId:'s',visitDate,createdAt,visitType:'home'});
  await M.runMigration(db,options());const c=await read('makhdomeen/m');assert.equal(c.lastVisitId,'a');assert.ok(c.lastVisitDate.isEqual(visitDate));assert.ok(c.lastVisitCreatedAt.isEqual(newer));assert.ok((await read('visits/a')).createdAt.isEqual(newer));assert.ok((await read('visits/z')).createdAt.isEqual(older));assert.ok((await read('visits/a')).visitDate.isEqual(visitDate));
 });
 test('review visit tuple ID tie uses backend string ordering rather than locale collation',async()=>{
  const date=new admin.firestore.Timestamp(1700000000,123456000);await put('makhdomeen/m',{grade:'1st'});
  for(const id of ['a','Z'])await put('visits/'+id,{makhdomId:'m',grade:'1st',khademId:'s',visitDate:date,createdAt:date,visitType:'home'});
  await M.runMigration(db,options());assert.equal((await read('makhdomeen/m')).lastVisitId,'a');
 });
 test('review backup file restores descendants under missing parent without inventing ancestor',async()=>{
  const attendance={sessionId:'missing',grade:'1st',status:'finalized',date:admin.firestore.Timestamp.fromDate(new Date('2025-10-10')),attendedMakhdomIds:['m']},device={token:'private',updatedAt:new admin.firestore.Timestamp(1,900000)};
  await put('attendance/missing/grades/1st',attendance);await put('khodam/missing/devices/device',device);await put('attendance/missing/grades/absent/deeper/child',{note:'deep'});
  const file=path.join(dir,'fixture_backup_orphans.json');const backup=await M.backupFixture(db,{project,backupPath:file});assert.ok(backup.records.some(r=>r.path==='attendance/missing/grades/1st'));assert.ok(backup.records.some(r=>r.path==='khodam/missing/devices/device'));assert.ok(backup.records.some(r=>r.path==='attendance/missing/grades/absent/deeper/child'));
  await M.runMigration(db,options());await M.restoreFixture(db,JSON.parse(fs.readFileSync(file,'utf8')),{project});assert.deepEqual(await read('attendance/missing/grades/1st'),attendance);assert.deepEqual(await read('khodam/missing/devices/device'),device);assert.equal((await db.doc('attendance/missing').get()).exists,false);assert.equal((await db.doc('khodam/missing').get()).exists,false);assert.equal((await db.doc('attendance/missing/grades/absent').get()).exists,false);assert.deepEqual(await read('attendance/missing/grades/absent/deeper/child'),{note:'deep'});
 });
});
