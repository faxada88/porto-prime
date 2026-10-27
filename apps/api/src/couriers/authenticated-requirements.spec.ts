import { describe, expect, it, vi } from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
import { CouriersService } from './couriers.service.js';
function fixture(status='PENDING') {
  const profile:any={id:'c',userId:'u',user:{name:'João',status},approvalStatus:'PENDING',requirements:[]};
  const db:any={courierProfile:{findUnique:vi.fn(async()=>profile)},courierRequirement:{findFirst:vi.fn(async()=>({id:'r',courierId:'c',status:'OPEN'})),updateMany:vi.fn(async()=>({count:1})),findUnique:vi.fn(async()=>({id:'r',courierId:'c',courier:{userId:'u'}}))}};
  const auth:any={authenticate:vi.fn(async()=>({id:'u',role:'COURIER',status}))};
  const rt:any={emitToUser:vi.fn(),emitToRole:vi.fn()};
  return {db,auth,rt,profile,service:new CouriersService(db,auth,rt)};
}
describe('Authenticated courier requirements',()=>{
  it('reads account status without a CPF lookup',async()=>{const f=fixture();expect(await f.service.me('Bearer valid')).toMatchObject({userStatus:'PENDING',approvalStatus:'PENDING'});expect(f.auth.authenticate).toHaveBeenCalledWith('Bearer valid',true);expect(f.db.courierProfile.findUnique.mock.calls[0][0].where).toEqual({userId:'u'});});
  it('accepts the owner response and notifies only the owner and Admin',async()=>{const f=fixture();await f.service.respond('r','Documento atualizado','Bearer valid');expect(f.db.courierRequirement.findFirst.mock.calls[0][0].where).toEqual({id:'r',courierId:'c'});expect(f.rt.emitToUser).toHaveBeenCalledWith('u','courier.profile.updated',{courierId:'c'});expect(f.rt.emitToRole).toHaveBeenCalledWith('ADMIN','courier.profile.updated',{courierId:'c'});});
  it('rejects a requirement owned by another account',async()=>{const f=fixture();f.db.courierRequirement.findFirst.mockResolvedValue(null);await expect(f.service.respond('other','Resposta','Bearer valid')).rejects.toThrow('não encontrada');expect(f.db.courierRequirement.updateMany).not.toHaveBeenCalled();});
  it.each(['BLOCKED','SUSPENDED'])('keeps %s read-only',async status=>{const f=fixture(status);expect(await f.service.me('Bearer valid')).toHaveProperty('userStatus',status);await expect(f.service.respond('r','Resposta','Bearer valid')).rejects.toThrow('indisponível');expect(f.db.courierRequirement.updateMany).not.toHaveBeenCalled();});
  it('rejects invalid document payloads without changing the requirement',async()=>{const f=fixture();await expect(f.service.respond('r','Resposta','Bearer valid','data:text/html;base64,PHNjcmlwdD4=')).rejects.toThrow('JPEG');expect(f.db.courierRequirement.updateMany).not.toHaveBeenCalled();});
  it('does not reopen an already resolved requirement',async()=>{const f=fixture();f.db.courierRequirement.updateMany.mockResolvedValue({count:0});await expect(f.service.respond('r','Resposta','Bearer valid')).rejects.toThrow('concluída');expect(f.rt.emitToUser).not.toHaveBeenCalled();});
});
