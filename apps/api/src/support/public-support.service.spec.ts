import {describe,it,expect} from 'vitest';
import {createHash} from 'node:crypto';
import {PublicSupportService,publicKeyMatches,publicText} from './public-support.service.js';

const key='A'.repeat(40),requestId='request_public_contact_001';
const payload={name:'Visitante',email:'visitante@example.com',phone:'',company:'',persona:'OTHER',topic:'ACCESS',text:'Não consigo entrar na minha conta.',requestId,accessKey:key};
function setup(role='ADMIN'){
 const contacts:any[]=[],messages:any[]=[],events:any[]=[];let authCalls=0;
 const find=(where:any)=>contacts.find(c=>Object.entries(where).every(([k,v])=>c[k]===v))||null;
 const db:any={publicContact:{
  findUnique:async({where}:any)=>find(where),count:async()=>contacts.length,
  create:async({data}:any)=>{const {messages:initial,...fields}=data;const c={...fields,id:'contact_'+contacts.length,status:'OPEN',notes:null,createdAt:new Date(),updatedAt:new Date()};contacts.push(c);messages.push({...initial.create,id:'message_'+messages.length,contactId:c.id,createdAt:new Date()});return c;},
  update:async({where,data}:any)=>Object.assign(find(where),data,{updatedAt:new Date()}),
  findMany:async()=>contacts,
 },publicContactMessage:{
  findMany:async({where,select}:any)=>messages.filter(m=>m.contactId===where.contactId).slice().reverse().map(m=>Object.fromEntries(Object.keys(select).map(k=>[k,m[k]]))),
  findFirst:async({where}:any)=>messages.find(m=>m.id===where.id&&m.contactId===where.contactId)||null,
  findUnique:async({where}:any)=>{const w=where.contactId_senderRole_requestId;return messages.find(m=>m.contactId===w.contactId&&m.senderRole===w.senderRole&&m.requestId===w.requestId)||null;},
  create:async({data}:any)=>{const m={...data,id:'message_'+messages.length,createdAt:new Date()};messages.push(m);return m;},
 }};db.$transaction=async(run:any)=>run(db);
 const service=new PublicSupportService(db,{authenticate:async()=>{authCalls++;return {id:'admin1',role}}} as any,{emitToRole:(...data:any[])=>events.push(data)} as any);
 return {service,contacts,messages,events,authCalls:()=>authCalls};
}
describe('Public support boundaries',()=>{
 it('creates an anonymous contact and notifies only Admin without issuing a session',async()=>{
  const f=setup(),result=await f.service.create(payload,'127.0.0.1');
  expect(result.protocol.startsWith('PP-')).toBe(true);expect(f.authCalls()).toBe(0);
  expect(f.events[0][0]).toBe('ADMIN');expect(f.events[0][2].senderRole).toBe('GUEST');
  expect(result).not.toHaveProperty('keyHash');expect(result).not.toHaveProperty('notes');
 });
 it('recovers a timed-out create using requestId and the same secret',async()=>{
  const f=setup();await f.service.create(payload,'ip');
  const result=await f.service.lookup({requestId,accessKey:key},'ip');
  expect(result.messages).toHaveLength(1);expect(f.contacts).toHaveLength(1);
 });
 it('deduplicates a repeated create',async()=>{
  const f=setup();const a=await f.service.create(payload,'ip'),b=await f.service.create(payload,'ip');
  expect(a.protocol).toBe(b.protocol);expect(f.contacts).toHaveLength(1);expect(f.messages).toHaveLength(1);
 });
 it('rejects requestId reuse with different content',async()=>{
  const f=setup();await f.service.create(payload,'ip');
  await expect(f.service.create({...payload,text:'Outro assunto'},'ip')).rejects.toThrow();
 });
 it('requires the access key, not just a protocol or email',async()=>{
  const f=setup();const c=await f.service.create(payload,'ip');
  await expect(f.service.lookup({protocol:c.protocol,accessKey:'B'.repeat(40)},'ip')).rejects.toThrow();
  await expect(f.service.lookup({protocol:c.protocol},'ip')).rejects.toThrow();
 });
 it('keeps internal notes out of the public detail',async()=>{
  const f=setup();const c=await f.service.create(payload,'ip');
  await f.service.status(c.id,{notes:'Anotação interna'},'Bearer admin');
  const publicView=await f.service.lookup({protocol:c.protocol,accessKey:key},'ip');
  expect(publicView).not.toHaveProperty('notes');expect((await f.service.adminDetail(c.id,'Bearer admin')).notes).toBe('Anotação interna');
 });
 it('allows an Admin reply and a visitor reply to reopen a resolved contact',async()=>{
  const f=setup();const c=await f.service.create(payload,'ip');
  await f.service.adminReply(c.id,{text:'Vamos ajudar.',requestId:'admin_reply_request_0001'},'Bearer admin');
  await f.service.status(c.id,{status:'RESOLVED'},'Bearer admin');
  await f.service.visitorReply(c.protocol,{text:'Ainda preciso de ajuda.',requestId:'guest_reply_request_0001',accessKey:key},'ip');
  const result=await f.service.lookup({protocol:c.protocol,accessKey:key},'ip');
  expect(result.status).toBe('OPEN');expect(result.messages).toHaveLength(3);
 });
 it('deduplicates retried messages',async()=>{
  const f=setup();const c=await f.service.create(payload,'ip');
  const reply={text:'Mais detalhes.',requestId:'guest_reply_request_0001',accessKey:key};
  await f.service.visitorReply(c.protocol,reply,'ip');await f.service.visitorReply(c.protocol,reply,'ip');
  expect(f.messages).toHaveLength(2);
 });
 it('prevents non-admins from reading or changing the Admin queue',async()=>{
  const f=setup('CUSTOMER');
  await expect(f.service.list('Bearer customer',{})).rejects.toThrow();
  await expect(f.service.adminReply('other',{text:'x',requestId:'request_admin_0001'},'Bearer customer')).rejects.toThrow();
 });
 it('validates topics, email and field sizes',async()=>{
  const f=setup();await expect(f.service.create({...payload,email:'inválido'},'ip')).rejects.toThrow();
  await expect(f.service.create({...payload,topic:'ADMIN'},'ip')).rejects.toThrow();
  expect(()=>publicText('x'.repeat(4001),'Mensagem',4000)).toThrow();
 });
 it('hashes and compares keys and rejects malformed keys',()=>{
  const digest=createHash('sha256').update(key).digest('hex');
  expect(publicKeyMatches(key,digest)).toBe(true);expect(publicKeyMatches('wrong',digest)).toBe(false);
 });
});
