const {test,before,after}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {collection,collectionGroup,query,where,orderBy,documentId,limit,startAfter,getDocs,setDoc,doc,Timestamp}=require('firebase/firestore');
let env;
before(async()=>{
 const address=process.env.FIRESTORE_EMULATOR_HOST;if(!address)return;const [host,port]=address.split(':');
 env=await initializeTestEnvironment({projectId:'demo-efteqad-task5-queries',firestore:{host,port:+port,rules:fs.readFileSync(require('node:path').join(__dirname,'../../firestore.rules'),'utf8')}});
 await env.withSecurityRulesDisabled(async context=>{
  const db=context.firestore(),set=(path,data)=>setDoc(doc(db,path),data);
  await Promise.all([set('khodam/s',{role:'servant',status:'active',grade:'1st'}),set('khodam/stage',{role:'stageAdmin',status:'active'}),set('makhdomeen/m',{fullName:'Child',grade:'1st',active:true,assignedKhademId:'s'})]);
  const jobs=[];
  for(let i=0;i<110;i++)jobs.push(set('visits/v'+String(i).padStart(3,'0'),{makhdomId:'m',grade:'1st',khademId:'another-author',visitDate:Timestamp.fromDate(new Date('2026-10-09T10:00:00Z')),createdAt:Timestamp.fromDate(new Date('2026-10-09T11:00:00Z'))}));
  for(let i=0;i<20;i++)jobs.push(set('visits/old'+i,{makhdomId:'m',grade:'1st',visitDate:Timestamp.fromDate(new Date('2025-10-09')),createdAt:Timestamp.fromDate(new Date('2025-10-09'))}));
  for(const grade of ['1st','2nd'])for(let i=0;i<12;i++)jobs.push(set('attendance/session'+i+'/grades/'+grade,{sessionId:'session'+i,grade,date:Timestamp.fromDate(new Date('2026-10-09')),type:'khedma',status:'finalized',attendedMakhdomIds:[]}));
  for(let i=0;i<100;i++)jobs.push(set('attendance/old'+i+'/grades/1st',{sessionId:'old'+i,grade:'1st',date:Timestamp.fromDate(new Date('2025-10-09')),type:'khedma',status:'legacyUnknown'}));
  for(let i=0;i<110;i++)jobs.push(set('notifications/n'+String(i).padStart(3,'0'),{recipientId:'s',createdAt:Timestamp.fromDate(new Date('2026-10-09')),isRead:false}));
  for(let i=0;i<jobs.length;i+=40)await Promise.all(jobs.slice(i,i+40));
 });
});
after(async()=>{if(env)await env.cleanup();});
const run=process.env.FIRESTORE_EMULATOR_HOST?test:test.skip;
const from=Timestamp.fromDate(new Date('2026-07-19T00:00:00Z')),to=Timestamp.fromDate(new Date('2026-10-17T00:00:00Z'));
run('real assigned child range cursor50 includes other authors without tie gaps',async()=>{
 const db=env.authenticatedContext('s').firestore(),base=query(collection(db,'visits'),where('makhdomId','==','m'),where('visitDate','>=',from),where('visitDate','<',to),orderBy('visitDate','desc'),orderBy('createdAt','desc'),orderBy(documentId(),'desc'));
 const start=performance.now(),a=await assertSucceeds(getDocs(query(base,limit(50)))),b=await getDocs(query(base,startAfter(a.docs.at(-1)),limit(50))),c=await getDocs(query(base,startAfter(b.docs.at(-1)),limit(50)));
 const ids=[...a.docs,...b.docs,...c.docs].map(d=>d.id);assert.deepEqual([a.size,b.size,c.size],[50,50,10]);assert.equal(ids.length,110);assert.equal(new Set(ids).size,110);assert.equal(ids[0],'v109');assert.equal(ids.at(-1),'v000');
 console.log(JSON.stringify({measurement:'local emulator documents returned, not billing reads',query:'assigned child visit range paged',documents:ids.length,pages:[a.size,b.size,c.size],elapsedMs:Math.round(performance.now()-start),fixtureVisits:130}));
});
run('own and stage gradeparts range authorized crossgrade and root scans denied',async()=>{
 const servant=env.authenticatedContext('s').firestore(),stage=env.authenticatedContext('stage').firestore(),scoped=(db,grades)=>query(collectionGroup(db,'grades'),where('grade','in',grades),where('date','>=',from),where('date','<',to),orderBy('date','desc'));
 const start=performance.now(),own=await assertSucceeds(getDocs(scoped(servant,['1st']))),all=await assertSucceeds(getDocs(scoped(stage,['1st','2nd','3rd'])));assert.equal(own.size,12);assert.equal(all.size,24);await assertFails(getDocs(scoped(servant,['2nd'])));await assertFails(getDocs(query(collection(servant,'attendance'),orderBy('date','desc'))));
 console.log(JSON.stringify({measurement:'local emulator documents returned, not billing reads',query:'attendance last90day gradeparts',ownDocuments:own.size,stageDocuments:all.size,fixtureParts:124,elapsedMs:Math.round(performance.now()-start)}));
});
run('notification tie cursors and separate unread query',async()=>{
 const db=env.authenticatedContext('s').firestore(),base=query(collection(db,'notifications'),where('recipientId','==','s'),orderBy('createdAt','desc'),orderBy(documentId(),'desc'));
 const a=await getDocs(query(base,limit(50))),b=await getDocs(query(base,startAfter(a.docs.at(-1)),limit(50))),c=await getDocs(query(base,startAfter(b.docs.at(-1)),limit(50))),ids=[...a.docs,...b.docs,...c.docs].map(d=>d.id);assert.equal(ids.length,110);assert.equal(new Set(ids).size,110);
 const unread=await assertSucceeds(getDocs(query(collection(db,'notifications'),where('recipientId','==','s'),where('isRead','==',false))));assert.equal(unread.size,110);
});
