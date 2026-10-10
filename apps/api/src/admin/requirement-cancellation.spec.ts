import {describe,expect,it,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../dispatch/dispatch.service.js',()=>({DispatchService:class{}}));
vi.mock('../wallet/wallet.service.js',()=>({WalletService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{ADMIN:'ADMIN',COURIER:'COURIER'},CourierStatus:{APPROVED:'APPROVED',PENDING:'PENDING'},OrderStatus:{},PaymentStatus:{},UserStatus:{ACTIVE:'ACTIVE',PENDING:'PENDING',BLOCKED:'BLOCKED',SUSPENDED:'SUSPENDED'}}));
import {AdminService} from './admin.service.js';
function fixture(){
 const profile={id:'c',userId:'u',approvalStatus:'PENDING',user:{status:'PENDING'}};
 const requirement:any={id:'r',courierId:'c',status:'OPEN',courier:profile,previousApprovalStatus:'APPROVED',previousUserStatus:'ACTIVE'};
 const db:any={courierRequirement:{findUnique:vi.fn(async()=>requirement),count:vi.fn(async()=>0),update:vi.fn(async({data}:any)=>({...requirement,...data}))},courierProfile:{update:vi.fn()},user:{update:vi.fn(async()=>({id:'u'})),findUnique:vi.fn(async()=>({id:'u',role:'COURIER',courierProfile:profile}))}};
 db.$transaction=vi.fn(async(fn:any)=>fn(db));
 const realtime:any={emitToUser:vi.fn(),emitToRole:vi.fn()};
 return{db,profile,requirement,realtime,service:new AdminService(db,{authenticate:async()=>({id:'admin',role:'ADMIN'})}as any,{}as any,{}as any,realtime)};
}
describe('Acesso e cancelamento de pendências',()=>{
 it('cancela mantendo histórico e restaura acesso interrompido pela solicitação',async()=>{const f=fixture();const result=await f.service.cancelRequirement('r');expect(result).toMatchObject({status:'RESOLVED',canceledBy:'admin'});expect(result.canceledAt).toBeInstanceOf(Date);expect(result).not.toHaveProperty('courier');expect(f.db.user.update).toHaveBeenCalledWith({where:{id:'u'},data:{status:'ACTIVE'}});expect(f.realtime.emitToRole).toHaveBeenCalled()});
 it.each(['BLOCKED','SUSPENDED'])('não libera conta %s',async status=>{const f=fixture();f.profile.user.status=status;await f.service.cancelRequirement('r');expect(f.db.user.update).not.toHaveBeenCalled()});
 it('não aprova novo candidato ao cancelar',async()=>{const f=fixture();f.requirement.previousApprovalStatus='PENDING';await f.service.cancelRequirement('r');expect(f.db.courierProfile.update).not.toHaveBeenCalled()});
 it('não libera enquanto outra pendência existe',async()=>{const f=fixture();f.db.courierRequirement.count.mockResolvedValue(1);await f.service.cancelRequirement('r');expect(f.db.user.update).not.toHaveBeenCalled()});
 it('é idempotente',async()=>{const f=fixture();f.requirement.canceledAt=new Date();await f.service.cancelRequirement('r');expect(f.db.courierRequirement.update).not.toHaveBeenCalled()});
 it('recusa pendência inexistente',async()=>{const f=fixture();f.db.courierRequirement.findUnique.mockResolvedValue(null);await expect(f.service.cancelRequirement('missing')).rejects.toThrow('não encontrada')});
 it('ativar motoboy aprova também o perfil',async()=>{const f=fixture();await f.service.updateUserStatus('u','ACTIVE');expect(f.db.courierProfile.update).toHaveBeenCalledWith({where:{id:'c'},data:{approvalStatus:'APPROVED'}})});
 it('ativar não ignora pendências abertas',async()=>{const f=fixture();f.db.courierRequirement.count.mockResolvedValue(1);await expect(f.service.updateUserStatus('u','ACTIVE')).rejects.toThrow('pendências');expect(f.db.user.update).not.toHaveBeenCalled()});
 it('pendência cancelada não pode ser resolvida novamente',async()=>{const f=fixture();f.requirement.canceledAt=new Date();await expect(f.service.resolveRequirement('r')).rejects.toThrow('cancelada')});
});
