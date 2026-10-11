import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
import {SupportService} from './support.service.js';
function fixture(role='CUSTOMER') {
 const threads:any[]=[],messages:any[]=[];
 const user:any={id:'owner',role};
 const db:any={
  $queryRaw:vi.fn().mockResolvedValue([]),
  user:{findUnique:vi.fn().mockResolvedValue({id:'owner',name:'Pessoa',role})},
  order:{findFirst:vi.fn().mockResolvedValue({id:'order'})},
  supportThread:{
   findUnique:vi.fn(async({where}:any)=>where.id?threads.find(t=>t.id===where.id)||null:threads.find(t=>t.ownerId===where.ownerId_orderId.ownerId&&t.orderId===where.ownerId_orderId.orderId)||null),
   findUniqueOrThrow:vi.fn(async({where}:any)=>threads.find(t=>t.id===where.id)),
   create:vi.fn(async({data}:any)=>{const t={id:'thread'+threads.length,status:'OPEN',...data};threads.push(t);return t}),
   update:vi.fn(async({where,data}:any)=>Object.assign(threads.find(t=>t.id===where.id),data)),
   findMany:vi.fn().mockResolvedValue([]),count:vi.fn().mockResolvedValue(0),
  },
  supportMessage:{
   findUnique:vi.fn(async({where}:any)=>messages.find(m=>m.senderId===where.senderId_requestId.senderId&&m.requestId===where.senderId_requestId.requestId)||null),
   create:vi.fn(async({data}:any)=>{const m={id:'message'+messages.length,...data};messages.push(m);return m}),
   findFirst:vi.fn().mockResolvedValue(null),
   findMany:vi.fn().mockResolvedValue([]),
  },
 };db.$transaction=vi.fn((fn:any)=>fn(db));
 const auth:any={authenticate:vi.fn().mockResolvedValue(user)};
 const realtime:any={emitToUser:vi.fn(),emitToRole:vi.fn()};
 const service=new SupportService(db,auth,realtime);
 const body={category:role==='PARTNER'?'Comissão e indicações':role==='COURIER'?'Entrega em andamento':'Pedido e entrega',subject:'Preciso de ajuda',text:'Mensagem inicial',requestId:'request1'};
 return{service,db,auth,realtime,user,threads,messages,body};
}
describe('Support ownership, persistence and isolated realtime',()=>{
 it('refuses Admin endpoints to non-admins',async()=>{const f=fixture();await expect(f.service.list('token',{},true)).rejects.toThrow('Acesso exclusivo');expect(f.db.supportThread.findMany).not.toHaveBeenCalled()});
 it('never exposes another account conversation',async()=>{const f=fixture();f.threads.push({id:'private',ownerId:'other'});await expect(f.service.detail('private','token')).rejects.toThrow('não encontrado');expect(f.db.supportMessage.findMany).not.toHaveBeenCalled()});
 it('limits the personal list to its authenticated account',async()=>{const f=fixture();await f.service.list('token',{role:'ADMIN',status:'INVALID'});expect(f.db.supportThread.findMany.mock.calls[0][0].where).toEqual({ownerId:'owner'})});
 it('checks customer ownership and hides deleted orders before creating a chat',async()=>{const f=fixture();f.db.order.findFirst.mockResolvedValue(null);await expect(f.service.create({...f.body,orderId:'order'},'token')).rejects.toThrow('não está vinculado');expect(f.db.order.findFirst).toHaveBeenCalledWith({where:{id:'order',adminDeletedAt:null,customerId:'owner'},select:{id:true}});expect(f.db.$transaction).not.toHaveBeenCalled()});
 it('requires an assigned courier, including the profile user relation',async()=>{const f=fixture('COURIER');await f.service.create({...f.body,orderId:'order'},'token');expect(f.db.order.findFirst.mock.calls[0][0].where).toEqual({id:'order',adminDeletedAt:null,courier:{userId:'owner'}})});
 it('partners can open tickets without gaining customer order access',async()=>{const f=fixture('PARTNER');f.db.order.findFirst.mockResolvedValue(null);await expect(f.service.create({...f.body,orderId:'order'},'token')).rejects.toThrow();await f.service.create(f.body,'token');expect(f.threads).toHaveLength(1)});
 it('saves first message and emits only to the owner and administrators',async()=>{const f=fixture();const t=await f.service.create(f.body,'token');expect(f.messages[0]).toMatchObject({threadId:t.id,senderId:'owner',text:f.body.text});expect(f.realtime.emitToUser).toHaveBeenCalledWith('owner','support.updated',expect.objectContaining({threadId:t.id}));expect(f.realtime.emitToRole).toHaveBeenCalledWith('ADMIN','support.updated',expect.any(Object));expect(f.db.order.findFirst).not.toHaveBeenCalled()});
 it('retries the first send without creating a second ticket or message',async()=>{const f=fixture();await f.service.create(f.body,'token');await f.service.create(f.body,'token');expect(f.threads).toHaveLength(1);expect(f.messages).toHaveLength(1)});
 it('keeps one order conversation per owner',async()=>{const f=fixture();await f.service.create({...f.body,orderId:'order'},'token');await f.service.create({...f.body,orderId:'order',requestId:'second'},'token');expect(f.threads).toHaveLength(1);expect(f.messages).toHaveLength(2)});
 it('rejects reused request identifiers with different message content',async()=>{const f=fixture();const t=await f.service.create(f.body,'token');await expect(f.service.reply(t.id,{text:'Changed',requestId:'request1'},'token')).rejects.toThrow('já utilizado');expect(f.messages).toHaveLength(1)});
 it('retries a reply idempotently and reopens a resolved ticket',async()=>{const f=fixture();const t=await f.service.create(f.body,'token');t.status='RESOLVED';const body={text:'Preciso de mais ajuda',requestId:'reply1'};await f.service.reply(t.id,body,'token');await f.service.reply(t.id,body,'token');expect(f.messages).toHaveLength(2);expect(t.status).toBe('OPEN')});
 it('allows Admin response and resolution without updating the order',async()=>{const f=fixture('ADMIN');f.threads.push({id:'ticket',ownerId:'other',status:'OPEN'});await f.service.reply('ticket',{text:'Vamos ajudar',requestId:'answer'},'token');expect(f.threads[0].status).toBe('IN_PROGRESS');await f.service.status('ticket',{status:'RESOLVED'},'token');expect(f.threads[0].status).toBe('RESOLVED');expect(f.db.order.findFirst).not.toHaveBeenCalled()});
 it('validates categories, message limits, empty text and malformed bodies',async()=>{const f=fixture();for(const body of [null,[],{...f.body,category:'Arbitrary'},{...f.body,text:' '},{...f.body,text:'a'.repeat(4001)}])await expect(f.service.create(body as any,'token')).rejects.toThrow();expect(f.db.$transaction).not.toHaveBeenCalled()});
 it('forbids a normal account from changing status',async()=>{const f=fixture();await expect(f.service.status('ticket',{status:'RESOLVED'},'token')).rejects.toThrow('Acesso exclusivo')});
 it('validates older-message cursors against the same conversation',async()=>{const f=fixture();f.threads.push({id:'ticket',ownerId:'owner'});await expect(f.service.detail('ticket','token','foreign-message')).rejects.toThrow('anterior inválida');expect(f.db.supportMessage.findMany).not.toHaveBeenCalled()});
 it('provides stable, chronological pages of persisted messages',async()=>{const f=fixture();f.threads.push({id:'ticket',ownerId:'owner'});f.db.supportMessage.findMany.mockResolvedValue(Array.from({length:101},(_,i)=>({id:String(100-i),text:'message'})));const result=await f.service.detail('ticket','token');expect(result.messages).toHaveLength(100);expect(result.messages[0].id).toBe('1');expect(result.olderCursor).toBe('1');expect(f.db.supportMessage.findMany.mock.calls[0][0].select).not.toHaveProperty('sender')});
 it('paginates the Admin queue with bounded search',async()=>{const f=fixture('ADMIN');await f.service.list('token',{page:'2',role:'PARTNER',status:'OPEN',search:'Pessoa'},true);expect(f.db.supportThread.findMany.mock.calls[0][0]).toMatchObject({skip:200,take:100,where:{ownerRole:'PARTNER',status:'OPEN'}})});
});
