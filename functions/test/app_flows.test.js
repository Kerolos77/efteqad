// Real emulator HTTP/Auth/callable boundary acceptance. No production fallback.
const {test, before, after} = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const {initializeApp, deleteApp} = require('firebase/app');
const {getAuth, connectAuthEmulator, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut, EmailAuthProvider, reauthenticateWithCredential} = require('firebase/auth');
const {getFirestore, connectFirestoreEmulator, doc, setDoc, updateDoc, getDoc, collectionGroup, query, where, orderBy, getDocs, Timestamp, terminate, onSnapshot} = require('firebase/firestore');
const {processOutboxNotification} = require('../src/notifications');
const projectId='demo-efteqad-rules';
const enabled=!!process.env.FIRESTORE_EMULATOR_HOST && !!process.env.FIREBASE_AUTH_EMULATOR_HOST;
let db, sdkApp, auth, client, stageToken, uid, email;
const tag='acceptance-'+Date.now();
async function signup(name) {
  const response=await fetch('http://'+process.env.FIREBASE_AUTH_EMULATOR_HOST+'/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key', {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:tag+'-'+name+'@example.test',password:'demo-password',returnSecureToken:true})});
  const result=await response.json(); assert.equal(response.status,200); return result;
}
async function callable(name,data,token) {
  const response=await fetch('http://127.0.0.1:5001/'+projectId+'/us-central1/'+name,{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({data})});
  const result=await response.json();
  if(result.error) {const e=new Error(result.error.message);e.code=result.error.status;throw e;}
  assert.equal(response.status,200);return result.result;
}
before(async()=>{
  if(!enabled)return;
  // Require emulator addresses and the fixed demo identity. Never read ADC.
  for(const address of [process.env.FIRESTORE_EMULATOR_HOST,process.env.FIREBASE_AUTH_EMULATOR_HOST]) assert.match(address,/^(127\.0\.0\.1|localhost):\d+$/);
  admin.initializeApp({projectId}); db=admin.firestore();
  sdkApp=initializeApp({projectId,apiKey:'demo-key',appId:'demo-app'},tag);
  auth=getAuth(sdkApp);connectAuthEmulator(auth,'http://'+process.env.FIREBASE_AUTH_EMULATOR_HOST,{disableWarnings:true});
  client=getFirestore(sdkApp);const [host,port]=process.env.FIRESTORE_EMULATOR_HOST.split(':');connectFirestoreEmulator(client,host,+port);
  const stage=await signup('stage');stageToken=stage.idToken;
  await db.doc('khodam/'+stage.localId).set({role:'stageAdmin',status:'active',name:'Demo admin'});
});
after(async()=>{if(!enabled)return;await terminate(client);await deleteApp(sdkApp);await db.terminate();await admin.app().delete();});
test('real Auth → pending/profile → trusted placement/import/assignment/task → concurrent presence/finalize/query → reopen → visits → replacement/reauth deletion',{skip:!enabled},async()=>{
  email=tag+'-user@example.test';
  const result=await createUserWithEmailAndPassword(auth,email,'demo-password');uid=result.user.uid;
  await setDoc(doc(client,'khodam',uid),{role:'pending',status:'pending',grade:null,name:'New user',phone:'',email,createdAt:Timestamp.now(),locale:'en'});
  assert.equal((await getDoc(doc(client,'khodam',uid))).data().status,'pending');
  await updateDoc(doc(client,'khodam',uid),{name:'Updated user',phone:'01000000000'});
  await assert.rejects(callable('importRows',{importId:tag,grade:'1st',rows:[{fullName:'Child',phone:'01000000001'}]},await result.user.getIdToken()),e=>e.code==='PERMISSION_DENIED');
  await callable('setKhademGrade',{khademId:uid,grade:'1st'},stageToken);
  assert.equal((await getDoc(doc(client,'khodam',uid))).data().status,'active');
  const importPayload={importId:tag,grade:'1st',rows:[{fullName:'First child',phone:'01000000001',trackingStartDate:'2026-10-01'},{fullName:'Second child',phone:'01000000002',trackingStartDate:'2026-10-01'}]};
  const imported=await callable('importRows',importPayload,stageToken), retry=await callable('importRows',importPayload,stageToken);
  assert.equal(imported.imported,2);assert.deepEqual(retry.results.map(r=>r.makhdomId),imported.results.map(r=>r.makhdomId));
  const ids=imported.results.map(r=>r.makhdomId);
  await callable('assignMakhdoms',{ids,targetKhademId:uid,expectedAssignments:Object.fromEntries(ids.map(id=>[id,null])),operationId:tag+'-assign'},stageToken);
  const task=await callable('createTask',{operationId:tag+'-task',taskData:{title:'Private roster',grade:'1st',assignedKhademId:uid,type:'attendance_khedma',dueDate:'2026-10-09'}},stageToken);
  await db.doc('khodam/'+uid+'/devices/en').set({token:'demo-en',locale:'en',platform:'test'});
  await db.doc('khodam/'+uid+'/devices/ar').set({token:'demo-ar',locale:'ar',platform:'test'});
  const pushes=[];
  await processOutboxNotification({db,outboxId:task.outboxId,messaging:{send:async p=>{pushes.push(p);return 'emulated';}}});
  assert.equal(pushes.length,2);assert.deepEqual(new Set(pushes.map(p=>p.notification.title)),new Set(['New task','مهمة جديدة']));
  assert.ok(pushes.every(p=>!JSON.stringify(p).includes('Private roster')));
  const sessionId='2026-10-09_khedma_1st',token=await result.user.getIdToken();
  // Independent authenticated callers and transaction writers. Admin is not the servant token.
  await Promise.all(ids.map((id,i)=>callable('setAttendancePresence',{sessionId,grade:'1st',makhdomId:id,isPresent:true,date:'2026-10-09',type:'khedma',taskId:task.taskId,operationId:tag+'-presence-'+i},i?stageToken:token)));
  await callable('finalizeAttendance',{sessionId,grade:'1st',taskId:task.taskId},token);
  const canonical=(await db.doc('attendance/'+sessionId+'/grades/1st').get()).data();assert.ok(canonical.date instanceof admin.firestore.Timestamp);
  // Cairo Oct 9 midnight = Oct 8 21:00 UTC; Oct 10 midnight = Oct 9 21:00 UTC.
  const readWindow=()=>getDocs(query(collectionGroup(client,'grades'),where('grade','==','1st'),where('date','>=',Timestamp.fromDate(new Date('2026-10-08T21:00:00Z'))),where('date','<',Timestamp.fromDate(new Date('2026-10-09T21:00:00Z'))),orderBy('date','desc')));
  let rows=await readWindow();let session=rows.docs.find(d=>d.data().sessionId===sessionId);assert.ok(session);assert.equal(session.data().status,'finalized');assert.deepEqual(new Set(session.data().attendedMakhdomIds),new Set(ids));
  const reopen={sessionId,grade:'1st',reason:'Demo correction',operationId:tag+'-reopen'};
  await callable('reopenAttendance',reopen,stageToken);rows=await readWindow();assert.equal(rows.docs.filter(d=>d.data().sessionId===sessionId&&d.data().status==='finalized').length,0);
  await callable('finalizeAttendance',{sessionId,grade:'1st'},stageToken);
  assert.equal((await callable('reopenAttendance',reopen,stageToken)).idempotent,true);
  assert.equal((await db.doc('attendance/'+sessionId).get()).data().status,'finalized');
  const visit=await callable('recordVisit',{makhdomId:ids[0],visitDate:'2026-10-10',notes:'Latest',visitType:'home',operationId:tag+'-new-visit'},token);
  await callable('recordVisit',{makhdomId:ids[0],visitDate:'2026-10-01',notes:'Earlier',visitType:'home',operationId:tag+'-old-visit'},token);
  const child=(await getDoc(doc(client,'makhdomeen',ids[0]))).data();assert.equal(child.lastVisitId,visit.visitId);assert.equal(child.visitCount,2);
  await signOut(auth);const replacement=await signup('replacement');await signInWithEmailAndPassword(auth,tag+'-replacement@example.test','demo-password');
  await assert.rejects(getDoc(doc(client,'makhdomeen',ids[0])),e=>e.code==='permission-denied');assert.notEqual(auth.currentUser.uid,uid);
  await signOut(auth);await signInWithEmailAndPassword(auth,email,'demo-password');
  await assert.rejects(reauthenticateWithCredential(auth.currentUser,EmailAuthProvider.credential(email,'wrong-password')));
  assert.equal((await db.doc('account_deletions/'+uid).get()).exists,false);
  await reauthenticateWithCredential(auth.currentUser,EmailAuthProvider.credential(email,'demo-password'));
  await callable('requestAccountDeletion',{expectedUid:uid,operationId:tag+'-delete'},await auth.currentUser.getIdToken(true));
  assert.equal((await db.doc('khodam/'+uid).get()).data().status,'deleting');
  assert.equal((await db.doc('account_deletions/'+uid).get()).data().status,'queued');
  console.log('Actual emulator HTTP/Auth acceptance; FCM worker executed with injected messaging, no scheduler/provider/device claim.');
});

test('fresh assigned all-mass task initializes private empty parts, zero finalize, first presence and collision safety', {skip:!enabled}, async()=>{
  const account=await createUserWithEmailAndPassword(auth,tag+'-mass@example.test','demo-password');
  const massUid=account.user.uid, token=await account.user.getIdToken();
  await db.doc('khodam/'+massUid).set({role:'servant',grade:'1st',status:'active',name:'Mass servant'});
  const create=async(day,op)=>callable('createTask',{operationId:tag+op,taskData:{title:'Mass',grade:'all',assignedKhademId:massUid,type:'attendance_qoddas',dueDate:day}},stageToken);
  const task=await create('2026-10-12T21:00:00Z','-mass');
  const sid='2026-10-12_qoddas_all';
  assert.equal((await db.doc('attendance/'+sid).get()).exists,false);
  // The denied initial listener/read is replaced after trusted initialization.
  await assert.rejects(getDoc(doc(client,'attendance',sid,'grades','2nd')),e=>e.code==='permission-denied');
  await callable('initializeAttendance',{taskId:task.taskId,sessionId:sid,grade:'all',expectedUid:massUid},token);
  for (const grade of ['1st','2nd','3rd']) {
    const row=await new Promise((resolve,reject)=>{let stop=()=>{};stop=onSnapshot(doc(client,'attendance',sid,'grades',grade),snap=>{if(!snap.metadata.fromCache){stop();resolve(snap.data());}},reject);});
    assert.deepEqual(row.attendedMakhdomIds,[]);assert.equal(row.taskId,task.taskId);assert.equal(row.status,'draft');
  }
  await callable('finalizeAttendance',{taskId:task.taskId,sessionId:sid,grade:'all',expectedUid:massUid},token);
  const rows=await getDocs(query(collectionGroup(client,'grades'),where('grade','==','1st'),where('date','>=',Timestamp.fromDate(new Date('2026-10-12T00:00:00Z'))),where('date','<',Timestamp.fromDate(new Date('2026-10-13T00:00:00Z')))));
  assert.equal(rows.docs.find(d=>d.data().sessionId===sid).data().status,'finalized');
  const before=(await db.doc('attendance/'+sid).get()).data();
  await callable('initializeAttendance',{taskId:task.taskId,sessionId:sid,grade:'all'},stageToken);
  assert.deepEqual((await db.doc('attendance/'+sid).get()).data(),before);
  const collision=await create('2026-10-12','-collision');
  await assert.rejects(callable('initializeAttendance',{taskId:collision.taskId,sessionId:sid,grade:'all'},token),e=>e.code==='INVALID_ARGUMENT');
  assert.equal((await db.doc('attendance/'+sid).get()).data().taskId,task.taskId);
  const active=await create('2026-10-13','-mass-presence'),activeSid='2026-10-13_qoddas_all';
  await db.doc('tasks/'+active.taskId).update({attendanceDay:admin.firestore.FieldValue.delete()});
  await callable('initializeAttendance',{taskId:active.taskId,sessionId:activeSid,grade:'all'},token);
  const child=await callable('saveMakhdomProfile',{patch:{fullName:'Mass child',phone:'01000000000',grade:'2nd'},operationId:tag+'-mass-child'},stageToken);
  await callable('setAttendancePresence',{taskId:active.taskId,sessionId:activeSid,grade:'all',date:'2026-10-13',type:'qoddas',makhdomId:child.makhdomId,isPresent:true,operationId:tag+'-mass-present',expectedUid:massUid},token);
  assert.deepEqual((await getDoc(doc(client,'attendance',activeSid,'grades','2nd'))).data().attendedMakhdomIds,[child.makhdomId]);
  const legacy=await create('2026-10-14T21:00:00Z','-legacy-zero'), legacySid='2026-10-14_qoddas_all';
  // Exercise the zero-finalize path without initialization for a retained Cairo-midnight instant.
  await db.doc('tasks/'+legacy.taskId).update({attendanceDay:admin.firestore.FieldValue.delete()});
  await callable('finalizeAttendance',{taskId:legacy.taskId,sessionId:legacySid,grade:'all',expectedUid:massUid},token);
  const legacyRows=await getDocs(query(collectionGroup(client,'grades'),where('grade','==','1st'),where('date','>=',Timestamp.fromDate(new Date('2026-10-14T00:00:00Z'))),where('date','<',Timestamp.fromDate(new Date('2026-10-15T00:00:00Z')))));
  assert.equal(legacyRows.docs.find(d=>d.data().sessionId===legacySid).data().date.toDate().toISOString(),'2026-10-14T00:00:00.000Z');
  // Arbitrary sessions remain private; initialization never grants grade-wide reads.
  await assert.rejects(getDoc(doc(client,'attendance','unrelated','grades','2nd')),e=>e.code==='permission-denied');
  for(const name of ['importRows','recordVisit','assignMakhdoms','saveMakhdomProfile','setAttendancePresence','finalizeAttendance','initializeAttendance'])
    await assert.rejects(callable(name,{expectedUid:'different-account'},token),e=>e.code==='PERMISSION_DENIED');
  const other=await createUserWithEmailAndPassword(auth,tag+'-other-mass@example.test','demo-password');
  await db.doc('khodam/'+other.user.uid).set({role:'servant',grade:'3rd',status:'active',name:'Other servant'});
  await assert.rejects(callable('initializeAttendance',{taskId:active.taskId,sessionId:activeSid,grade:'all',expectedUid:other.user.uid},await other.user.getIdToken()),e=>e.code==='PERMISSION_DENIED');
  await assert.rejects(getDoc(doc(client,'attendance',activeSid,'grades','2nd')),e=>e.code==='permission-denied');
});
