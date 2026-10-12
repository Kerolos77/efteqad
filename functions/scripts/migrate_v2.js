/** One-time, transactionally guarded v2 migration. Never deploy this CLI. */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const admin = require('firebase-admin');
const A = require('../src/access');
const PLAN_VERSION = 2;
const COLLECTIONS = ['visits', 'makhdomeen', 'khodam', 'tasks', 'attendance'];
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const fingerprint = project => hash(JSON.stringify({project, planVersion:PLAN_VERSION, collections:COLLECTIONS}));
const timestamp = value => { if(value instanceof admin.firestore.Timestamp)return value;const d = value instanceof Date ? value : typeof value === 'string' ? new Date(value) : null; return d && Number.isFinite(d.getTime()) && (!/^\d{4}-\d{2}-\d{2}$/.test(value) || d.toISOString().slice(0,10)===value) ? admin.firestore.Timestamp.fromDate(d) : null; };
function compareTimestamps(left,right){const a=timestamp(left),b=timestamp(right);return (a?.seconds||0)-(b?.seconds||0)||(a?.nanoseconds||0)-(b?.nanoseconds||0);}
const day = value => timestamp(value)?.toDate().toISOString().slice(0,10);
function parseArgs(argv = process.argv.slice(2)) {
 const o={dryRun:true,apply:false,resume:false,checkpointPath:path.resolve('migration_checkpoint.json'),reportPath:path.resolve('migration_report.json')};let mode;
 for(const arg of argv){
  if(['--dry-run','--apply'].includes(arg)){if(mode && mode!==arg)throw new Error('Conflicting migration mode');mode=arg;o.dryRun=arg==='--dry-run';o.apply=!o.dryRun;}
  else if(arg==='--resume')o.resume=true;
  else if(/^--(project|checkpoint|report|backup|restore)=/.test(arg)){const i=arg.indexOf('='),key=arg.slice(2,i),value=arg.slice(i+1);if(!value)throw new Error('Empty '+key);o[key==='project'?'project':key+'Path']=key==='project'?value:path.resolve(value);}
  else throw new Error('Unknown option '+arg);
 }
 validateProject(o.project);
 if(o.resume && o.dryRun)throw new Error('--resume requires --apply mode');
 if(o.backupPath && o.restorePath)throw new Error('Choose backup or restore');
 if(o.restorePath && o.dryRun)throw new Error('Restore requires --apply');
 const outputs=[o.reportPath,o.checkpointPath,o.backupPath,o.restorePath].filter(Boolean);if(new Set(outputs).size!==outputs.length)throw new Error('Output paths must be distinct');
 return o;
}
function validateProject(project,db){
 if(typeof project!=='string'||!/^([a-z][a-z0-9-]{4,62})$/.test(project))throw new Error('Explicit --project identity required');
 if(process.env.FIRESTORE_EMULATOR_HOST && project!=='demo-efteqad-rules')throw new Error('Emulator project must be demo-efteqad-rules');
 if(!process.env.FIRESTORE_EMULATOR_HOST && project.startsWith('demo-'))throw new Error('Demo project requires FIRESTORE_EMULATOR_HOST');
 if(db && db.projectId!==project)throw new Error('Firestore project does not match explicit project');
 return project;
}
function auditStudentVisits(data,visits=[]){
 const patch={},discrepancies=[];if((data.visitCount||0)!==visits.length){patch.visitCount=visits.length;discrepancies.push('visit-count-mismatch');}
 const sorted=visits.filter(v=>timestamp(v.visitDate)).sort((a,b)=>compareTimestamps(b.visitDate,a.visitDate)||compareTimestamps(b.createdAt,a.createdAt)||((b.id||'')>(a.id||'')?1:(b.id||'')<(a.id||'')?-1:0));
 if(sorted.length){const v=sorted[0];Object.assign(patch,{lastVisitId:v.id,lastVisitDate:timestamp(v.visitDate),lastVisitNotes:v.notes??v.description??null});if(timestamp(v.createdAt))patch.lastVisitCreatedAt=timestamp(v.createdAt);}
 else if(!visits.length)Object.assign(patch,{lastVisitId:null,lastVisitDate:null,lastVisitNotes:null,lastVisitCreatedAt:null});
 if(data.notes && data.legacyNotes==null)patch.legacyNotes=data.notes;
 const created=timestamp(data.createdAt);patch.createdAtKnown=Boolean(created && data.createdAtKnown!==false);
 if(timestamp(data.trackingStartDate))patch.trackingStartEstimated=data.trackingStartEstimated===true;
 else if(patch.createdAtKnown)Object.assign(patch,{trackingStartDate:created,trackingStartEstimated:true});
 else {patch.trackingStartEstimated=true;discrepancies.push('unknown-tracking-origin');}
 if(data.active===false)Object.assign(patch,{assignedKhademId:null,assignedKhademName:null});
 const aliases={'ثانوية عامة':'general','General':'general','General secondary':'general','صنايع / فني':'technical','Technical / vocational':'technical','خدمات':'services','Services':'services','تجاري':'commercial','Commercial':'commercial','أخرى':'other','Other':'other'};
 if(data.secondaryType && aliases[data.secondaryType])patch.secondaryType=aliases[data.secondaryType];
 else if(data.secondaryType && !['general','technical','services','commercial','other'].includes(data.secondaryType)){patch.secondaryType='other';if(!data.secondaryTypeCustomLabel)patch.secondaryTypeCustomLabel=data.secondaryType;}
 return {patch,discrepancies};
}
function auditServantDevices(data){
 const token=typeof data.fcmToken==='string'?data.fcmToken.trim():'';
 return {patch:{},devicesToCreate:token?[{installationId:'legacy_device_'+hash(token),token,locale:['ar','en'].includes(data.locale)?data.locale:'ar',...(timestamp(data.tokenUpdatedAt)?{updatedAt:timestamp(data.tokenUpdatedAt)}:{})}]:[]};
}
function historicalGrades(data,ids){
 const sources=[];let invalid=false;
 for(const field of ['rosterSnapshot','gradesByMakhdomId','yearSnapshot']){
  if(data[field]==null)continue;
  const value=data[field],map=new Map();
  const rows=Array.isArray(value)?value.map(row=>[row?.id,row?.grade]):value&&typeof value==='object'?Object.entries(value):null;
  if(!rows||!rows.length){invalid=true;continue;}
  for(const [child,grade]of rows){if(typeof child!=='string'||!child||!A.GRADES.includes(grade)||map.has(child)&&map.get(child)!==grade)invalid=true;else map.set(child,grade);}
  if(!ids||ids.some(child=>!map.has(child)))invalid=true;
  sources.push(map);
 }
 const grades=new Map();for(const source of sources)for(const [child,grade]of source){if(grades.has(child)&&grades.get(child)!==grade)invalid=true;else grades.set(child,grade);}
 return {present:sources.length>0,invalid,grades};
}
function attendancePlan(id,data){
 const issues=[],parts={};const date=day(data.date),type=({service:'khedma',mass:'qoddas'})[data.type]||data.type;
 const scoped=/^(\d{4}-\d{2}-\d{2})_(khedma|qoddas)_(1st|2nd|3rd|all)$/.exec(id);
 let grade=[...A.GRADES,'all'].includes(data.grade)?data.grade:scoped?.[3];
 if(scoped && ((date && scoped[1]!==date)||(type && scoped[2]!==type)||(data.grade && data.grade!==scoped[3])))issues.push('historical-scope-conflict');
 const ids=Array.isArray(data.attendedMakhdomIds)?[...new Set(data.attendedMakhdomIds)].sort():null;
 const historical=historicalGrades(data,ids);
 if(historical.invalid)issues.push('conflicting-or-incomplete-historical-snapshot');
 if(!grade && historical.present && !historical.invalid){const scopes=[...new Set(historical.grades.values())];if(scopes.length===1)grade=scopes[0];else if(scopes.length>1 && type==='qoddas')grade='all';}
 if(grade && grade!=='all' && historical.present && [...historical.grades.values()].some(g=>g!==grade))issues.push('historical-scope-conflict');
 if(!date || !['khedma','qoddas'].includes(type))issues.push('unknown-date-or-type');
 if(!grade)issues.push('unknown-historical-grade');
 if(!ids)issues.push('unknown-attendance-list');
 if(!['draft','finalized','legacyUnknown'].includes(data.status))issues.push('unknown-status');
 if(grade==='all' && type!=='qoddas')issues.push('invalid-all-scope');
 if(grade==='all' && ids){
  if(!historical.present || historical.invalid)issues.push('unknown-historical-grade');
  else for(const g of A.GRADES)parts[g]=ids.filter(child=>historical.grades.get(child)===g);
 }else if(grade && ids)parts[grade]=ids;
 const unknown=issues.length>0;
 return {issues,unknown,grade,parts,target:date&&grade&&['khedma','qoddas'].includes(type)?date+'_'+type+'_'+grade:null,base:{sessionId:null,date:timestamp(data.date),type,grade:grade||'legacyUnknown',status:unknown?'legacyUnknown':data.status,attendedMakhdomIds:ids||[],taskId:data.taskId||null}};
}
function auditAttendanceSession(data){const p=attendancePlan('',data);return {patch:{...(p.unknown?{status:'legacyUnknown'}:{}),...(!p.grade?{grade:'legacyUnknown'}:{})},issues:p.issues};}
function sameAttendancePart(existing,expected){return existing.sessionId===expected.sessionId && day(existing.date)===day(expected.date) && existing.type===expected.type && existing.grade===expected.grade && existing.status===expected.status && (existing.taskId||null)===(expected.taskId||null) && JSON.stringify([...(existing.attendedMakhdomIds||[])].sort())===JSON.stringify([...expected.attendedMakhdomIds].sort());}
async function canonicalAllParts(source,data,p,get){
 if(p.target!==source.id || p.grade!=='all' || p.base.type!=='qoddas' || !['draft','finalized'].includes(data.status))return null;
 const parts=[];for(const grade of A.GRADES)parts.push(await get(source.ref.collection('grades').doc(grade)));
 // Current backend roots have grade parts rather than legacy roster snapshots.
 // If any such evidence exists, preserve stored business statuses and report
 // actual inconsistencies; migration must never finalize/downgrade those parts.
 if(!parts.some(part=>part.exists))return null;
 const historical=historicalGrades(data,data.attendedMakhdomIds);
 // A complete legacy snapshot can fill missing parts, provided every existing
 // part agrees with that historical scope and recorded root status.
 if(parts.some(part=>!part.exists)&&historical.present&&!historical.invalid&&!p.unknown&&parts.every((part,i)=>!part.exists||sameAttendancePart(part.data(),{...p.base,sessionId:source.id,grade:A.GRADES[i],attendedMakhdomIds:p.parts[A.GRADES[i]]})))return null;
 const issues=[],owners=new Map();
 for(let i=0;i<parts.length;i++){
  const snap=parts[i],grade=A.GRADES[i];if(!snap.exists){issues.push('missing-canonical-grade-part');continue;}
  const part=snap.data();
  if(part.sessionId!==source.id||part.grade!==grade||day(part.date)!==day(data.date)||part.type!==data.type||(part.taskId||null)!==(data.taskId||null)||!Array.isArray(part.attendedMakhdomIds)||!['draft','finalized','legacyUnknown'].includes(part.status)){issues.push('conflicting-canonical-grade-part');continue;}
  if(data.status==='finalized'&&part.status!=='finalized')issues.push('conflicting-canonical-part-status');
  for(const child of part.attendedMakhdomIds){if(owners.has(child)&&owners.get(child)!==grade)issues.push('conflicting-canonical-child-grade');owners.set(child,grade);}
 }
 if(!Array.isArray(data.attendedMakhdomIds)||JSON.stringify([...new Set(data.attendedMakhdomIds)].sort())!==JSON.stringify([...owners.keys()].sort()))issues.push('conflicting-canonical-attendee-union');
 return {parts,issues};
}
function normalizeVisit(data,child){
 const patch={},issues=[];const author=data.khademId||data.servantId;if(author){patch.khademId=author;patch.servantId=author;}else issues.push('unknown-visit-author');
 const grade=A.GRADES.includes(data.grade)?data.grade:A.GRADES.includes(child?.grade)?child.grade:null;if(grade)patch.grade=grade;else issues.push('unknown-visit-grade');
 for(const field of ['visitDate','createdAt']){const value=timestamp(data[field]);if(value)patch[field]=value;else issues.push('unknown-'+field);}
 const raw=data.visitType;if(typeof raw==='string'){
  const key=raw.trim().replace(/^[🏠📞⛪💬]\s*/u,'').toLowerCase();
  const aliases={home:'home','home visit':'home','منزلية':'home','زيارة منزلية':'home','زيارة بيت':'home',phone:'phone','phone call':'phone','مكالمة تليفونية':'phone','تليفونية':'phone','مكالمة':'phone','مكالمة هاتفية':'phone',church:'church','church meetup':'church','church meeting':'church','كنيسة':'church','لقاء في الكنيسة':'church','لقاء بالكنيسة':'church',other:'other','message / other':'other','رسالة / أخرى':'other','أخرى':'other','اخرى':'other'};
  if(aliases[key])patch.visitType=aliases[key];else{patch.legacyVisitType=raw;patch.visitTypeUnknown=true;issues.push('unknown-visit-type');}
 }else issues.push('unknown-visit-type');
 return {patch,issues};
}
function atomicJson(file,value){fs.mkdirSync(path.dirname(file),{recursive:true});const temp=file+'.tmp-'+process.pid;const fd=fs.openSync(temp,'w',0o600);try{fs.writeFileSync(fd,JSON.stringify(value,null,2));fs.fsyncSync(fd);}finally{fs.closeSync(fd);}fs.renameSync(temp,file);}
function loadCheckpoint(o){
 const empty={planVersion:PLAN_VERSION,project:o.project,fingerprint:fingerprint(o.project),lastCursor:null,completedUnits:[]};
 if(!o.resume||!o.checkpointPath||!fs.existsSync(o.checkpointPath))return empty;
 let c;try{c=JSON.parse(fs.readFileSync(o.checkpointPath,'utf8'));}catch{throw new Error('Invalid checkpoint JSON');}
 const validUnit=p=>typeof p==='string'&&new RegExp('^('+COLLECTIONS.join('|')+')/[^/]+$').test(p);
 if(c.planVersion!==PLAN_VERSION||c.project!==o.project||c.fingerprint!==empty.fingerprint||!Array.isArray(c.completedUnits)||!c.completedUnits.every(validUnit)||new Set(c.completedUnits).size!==c.completedUnits.length||(c.lastCursor!==null && (!validUnit(c.lastCursor)||c.lastCursor!==c.completedUnits.at(-1))))throw new Error('Invalid checkpoint identity/version/fingerprint/cursor/units');
 return c;
}
async function* documents(db,collection){let cursor;for(;;){let q=db.collection(collection).orderBy(admin.firestore.FieldPath.documentId()).limit(100);if(cursor)q=q.startAfter(cursor);const snap=await q.get();if(snap.empty)return;for(const doc of snap.docs)yield doc;cursor=snap.docs.at(-1);}}
async function runMigration(db,options={}){
 const o={dryRun:true,...options};validateProject(o.project,db);const checkpoint=loadCheckpoint(o);const report={project:o.project,planVersion:PLAN_VERSION,dryRun:o.dryRun,scanned:0,updated:0,skipped:0,issues:[]};
 // A persisted cursor is informational only: every resume checks server receipts,
 // including records committed just before a lost checkpoint and new records.
 const attendanceTargets=new Map();for await(const s of documents(db,'attendance')){const target=attendancePlan(s.id,s.data()).target;if(target){if(!attendanceTargets.has(target))attendanceTargets.set(target,[]);attendanceTargets.get(target).push(s.ref);}}
 for(const collection of COLLECTIONS)for await(const candidate of documents(db,collection)){
  report.scanned++;const receiptRef=db.doc('migration_v2_receipts/'+hash(candidate.ref.path));
  const work=async tx=>{
   const get=ref=>tx?tx.get(ref):ref.get();const source=await get(candidate.ref),receipt=await get(receiptRef);if(!source.exists)return {skipped:true,issues:['source-missing']};
   if(receipt.exists){const r=receipt.data();if(r.planVersion!==PLAN_VERSION||r.project!==o.project||r.fingerprint!==fingerprint(o.project)||r.sourcePath!==source.ref.path)throw new Error('Invalid migration receipt');return {skipped:true,issues:r.issues||[]};}
   const data=source.data(),writes=[],issues=[];let patch={};
   if(collection==='visits'){const child=data.makhdomId?await get(db.doc('makhdomeen/'+A.id(data.makhdomId))):null;const result=normalizeVisit(data,child?.data());patch=result.patch;issues.push(...result.issues);}
   if(collection==='makhdomeen'){
    const query=db.collection('visits').where('makhdomId','==',source.id).limit(1001),visits=await get(query);if(visits.size>1000){issues.push('visit-limit-requires-manual-review');}else{const result=auditStudentVisits(data,visits.docs.map(v=>({...v.data(),id:v.id})));patch=result.patch;issues.push(...result.discrepancies);}
    if(A.GRADES.includes(data.grade)){const roster=db.doc('attendance_roster/'+source.id);await get(roster);writes.push({ref:roster,data:A.roster(source.id,{...data,...patch}),replace:true});}else issues.push('unknown-roster-grade');
   }
   if(collection==='khodam'){
    const children=await get(db.collection('makhdomeen').where('assignedKhademId','==',source.id).limit(1001));if(children.size>1000)issues.push('assignment-limit-requires-manual-review');else patch.assignedCount=children.docs.filter(c=>c.data().active!==false).length;
    for(const device of auditServantDevices(data).devicesToCreate){const ref=source.ref.collection('devices').doc(device.installationId),existing=await get(ref);if(!existing.exists){const {installationId,...payload}=device;writes.push({ref,data:payload,create:true});}}
   }
   if(collection==='tasks' && data.type==='attendance'){
    if(timestamp(data.dueDate) && ['khedma','service','attendance_khedma'].includes(data.attendanceType||data.legacyCategory))patch.type='attendance_khedma';else issues.push('ambiguous-attendance-task');
   }
   if(collection==='attendance'){
    const p=attendancePlan(source.id,data),canonical=await canonicalAllParts(source,data,p,get);
    if(canonical){
     issues.push(...canonical.issues);
     if(!canonical.issues.length){if(!(data.date instanceof admin.firestore.Timestamp))patch.date=timestamp(data.date);for(const part of canonical.parts)if(!(part.data().date instanceof admin.firestore.Timestamp))writes.push({ref:part.ref,data:{date:timestamp(part.data().date)}});}
    }else{
    issues.push(...p.issues);
    const peers=attendanceTargets.get(p.target)||[];let conflicting=false;
    for(const ref of peers){if(ref.path===source.ref.path)continue;const peer=await get(ref);if(peer.exists && hash(JSON.stringify(attendancePlan(peer.id,peer.data()).base))!==hash(JSON.stringify(p.base)))conflicting=true;}
    if(conflicting){issues.push('conflicting-attendance-target');patch.status='legacyUnknown';}
    else if(p.unknown){patch.status='legacyUnknown';if(!p.grade)patch.grade='legacyUnknown';}
    else{
     const rootRef=db.doc('attendance/'+p.target),root=await get(rootRef),base={...p.base,sessionId:p.target};
     if(root.exists && rootRef.path!==source.ref.path && hash(JSON.stringify(attendancePlan(root.id,root.data()).base))!==hash(JSON.stringify(p.base))){issues.push('conflicting-attendance-target');patch.status='legacyUnknown';}
     else{
      const parts=[];for(const [grade,ids]of Object.entries(p.parts)){const ref=rootRef.collection('grades').doc(grade),existing=await get(ref),part={...base,grade,attendedMakhdomIds:ids};if(existing.exists){if(!sameAttendancePart(existing.data(),part)){issues.push('existing-attendance-part-preserved');parts.push(null);}else parts.push({ref,data:{date:base.date}});}else parts.push({ref,data:part,create:true});}
      if(issues.includes('existing-attendance-part-preserved')){patch.status='legacyUnknown';}else{if(rootRef.path===source.ref.path)patch=base;else if(!root.exists)writes.push({ref:rootRef,data:{...data,...base},create:true});else writes.push({ref:rootRef,data:base});for(const part of parts)if(part)writes.push(part);}
     }
    }
    }
   }
   if(Object.keys(patch).length)writes.unshift({ref:source.ref,data:patch});
   if(tx){for(const w of writes){if(w.create)tx.create(w.ref,w.data);else if(w.replace)tx.set(w.ref,w.data);else tx.update(w.ref,w.data);}tx.create(receiptRef,{planVersion:PLAN_VERSION,project:o.project,fingerprint:fingerprint(o.project),sourcePath:source.ref.path,sourceVersion:source.updateTime.toDate().toISOString(),sourceFingerprint:hash(JSON.stringify(data)),issues,completedAt:admin.firestore.Timestamp.now()});}
   return {changed:writes.length>0,issues};
  };
  const result=o.dryRun?await work(null):await db.runTransaction(work);if(result.changed)report.updated++;if(result.skipped)report.skipped++;for(const reason of result.issues)report.issues.push({collection,id:candidate.id,reason});
  if(!o.dryRun){if(!checkpoint.completedUnits.includes(candidate.ref.path))checkpoint.completedUnits.push(candidate.ref.path);checkpoint.lastCursor=checkpoint.completedUnits.at(-1)||null;if(o.checkpointPath)atomicJson(o.checkpointPath,checkpoint);}
 }
 if(o.reportPath)atomicJson(o.reportPath,report);return report;
}
function fixtureProject(db,o){validateProject(o.project,db);if(o.project!=='demo-efteqad-rules'||!process.env.FIRESTORE_EMULATOR_HOST)throw new Error('Fixture backup/restore requires local demo emulator');}
function encode(value){
 if(value instanceof admin.firestore.Timestamp)return {type:'timestamp',value:[value.seconds,value.nanoseconds]};
 if(value instanceof admin.firestore.GeoPoint)return {type:'geopoint',value:[value.latitude,value.longitude]};
 if(Buffer.isBuffer(value))return {type:'bytes',value:value.toString('base64')};
 if(value instanceof admin.firestore.DocumentReference)return {type:'reference',value:value.path};
 if(Array.isArray(value))return {type:'array',value:value.map(encode)};
 if(value&&typeof value==='object')return {type:'map',value:Object.fromEntries(Object.entries(value).map(([k,v])=>[k,encode(v)]))};
 return {type:'scalar',value};
}
function decode(item,db){
 if(!item||typeof item!=='object')throw new Error('Invalid backup value');
 switch(item.type){
  case 'timestamp':return new admin.firestore.Timestamp(...item.value);
  case 'geopoint':return new admin.firestore.GeoPoint(...item.value);
  case 'bytes':return Buffer.from(item.value,'base64');
  case 'reference':return db.doc(item.value);
  case 'array':return item.value.map(v=>decode(v,db));
  case 'map':return Object.fromEntries(Object.entries(item.value).map(([k,v])=>[k,decode(v,db)]));
  case 'scalar':return item.value;
  default:throw new Error('Invalid backup type');
 }
}
async function backupFixture(db,o){fixtureProject(db,o);const records=[];const walk=async parent=>{for(const collection of await parent.listCollections()){for(const ref of await collection.listDocuments()){const snap=await ref.get();if(snap.exists)records.push({path:ref.path,data:encode(snap.data())});await walk(ref);}}};await walk(db);records.sort((a,b)=>a.path.localeCompare(b.path));const backup={project:o.project,formatVersion:1,records};if(o.backupPath)atomicJson(o.backupPath,backup);return backup;}
async function restoreFixture(db,backup,o){fixtureProject(db,o);if(backup.project!==o.project||backup.formatVersion!==1||!Array.isArray(backup.records)||backup.records.some(r=>!r.path||r.path.split('/').length%2!==0||!r.data)||new Set(backup.records.map(r=>r.path)).size!==backup.records.length)throw new Error('Invalid fixture backup');for(const c of await db.listCollections())await db.recursiveDelete(c);for(let i=0;i<backup.records.length;i+=200){const b=db.batch();for(const r of backup.records.slice(i,i+200))b.set(db.doc(r.path),decode(r.data,db));await b.commit();}}
if(require.main===module){(async()=>{const o=parseArgs();const app=admin.initializeApp({projectId:o.project});const db=app.firestore();try{if(o.backupPath){await backupFixture(db,o);console.log('Local fixture backup written');}else if(o.restorePath){await restoreFixture(db,JSON.parse(fs.readFileSync(o.restorePath,'utf8')),o);console.log('Local fixture restored');}else{const r=await runMigration(db,o);console.log(JSON.stringify({dryRun:r.dryRun,scanned:r.scanned,updated:r.updated,skipped:r.skipped,issues:r.issues.length}));}}finally{await db.terminate();await app.delete();}})().catch(()=>{console.error('Migration failed; check project, options, checkpoint and local emulator availability. No secret diagnostics printed.');process.exitCode=1;});}
module.exports={parseArgs,validateProject,auditStudentVisits,auditAttendanceSession,auditServantDevices,runMigration,backupFixture,restoreFixture};
