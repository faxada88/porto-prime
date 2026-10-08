import { describe, it, expect, vi } from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../dispatch/dispatch.service.js',()=>({DispatchService:class{}}));
vi.mock('../wallet/wallet.service.js',()=>({WalletService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{ADMIN:'ADMIN',COURIER:'COURIER'},CourierStatus:{},OrderStatus:{},PaymentStatus:{},UserStatus:{}}));
import { AdminService } from './admin.service.js';
function fixture(role='ADMIN'){
 const profile:any={id:'c',userId:'u',pixKey:'old@example.test',pixKeyType:'EMAIL',onboardingData:{street:'Old',cpf:'52998224725'},isOnline:true};
 const tx:any={$queryRawUnsafe:vi.fn(async()=>[]),courierProfile:{findUnique:vi.fn(async()=>profile),update:vi.fn(async()=>({}))},user:{update:vi.fn(async()=>({}))}};
 const prisma:any={...tx,$transaction:vi.fn(async(fn:any)=>fn(tx)),order:{count:async()=>3},courierLedgerEntry:{aggregate:vi.fn(async({where}:any)=>({_sum:{amount:where.type?120:40}}))},withdrawal:{findMany:async()=>[{status:'PAID',amount:50},{status:'PROCESSING',amount:20},{status:'PENDING',amount:10},{status:'REJECTED',amount:5}]}};
 const realtime:any={emitToUser:vi.fn(),emitToRole:vi.fn()};
 return {tx,prisma,realtime,service:new AdminService(prisma,{authenticate:async()=>({role})} as any,{} as any,{} as any,realtime)};
}
describe('Admin courier profile and finance',()=>{
 it('rejects non-admin reads and edits',async()=>{const f=fixture('COURIER');await expect(f.service.courierFinance('c')).rejects.toThrow('administrador');await expect(f.service.editCourier('c',{name:'Name'})).rejects.toThrow('administrador');expect(f.prisma.$transaction).not.toHaveBeenCalled()});
 it('separates paid, pending and rejected withdrawals',async()=>{const f=fixture();expect(await f.service.courierFinance('c')).toMatchObject({earningsTotal:120,availableBalance:40,deliveries:3,paidWithdrawalCount:1,paidWithdrawalTotal:50,pendingWithdrawalTotal:30})});
 it('preserves CPF and availability while merging changes',async()=>{const f=fixture();await f.service.editCourier('c',{street:'New',name:'New Name',pixKey:'NEW@example.test',pixKeyType:'EMAIL'});const data=f.tx.courierProfile.update.mock.calls[0][0].data;expect(data.onboardingData).toMatchObject({cpf:'52998224725',street:'New',pixKey:'new@example.test'});expect(data).not.toHaveProperty('isOnline');expect(data).not.toHaveProperty('document');expect(f.realtime.emitToUser).toHaveBeenCalledWith('u','courier.profile.updated',{courierId:'c'})});
 it('rejects protected fields and invalid values',async()=>{for(const body of [{isOnline:false},{document:'111'},{email:'invalid'},{vehicleYear:'1900'},{cnhCategory:'Z'}]){const f=fixture();await expect(f.service.editCourier('c',body)).rejects.toThrow();expect(f.prisma.$transaction).not.toHaveBeenCalled()}});
 it('does not emit updates when transaction fails',async()=>{const f=fixture();f.tx.user.update.mockRejectedValue({code:'P2002'});await expect(f.service.editCourier('c',{email:'new@example.test'})).rejects.toThrow('já está cadastrado');expect(f.realtime.emitToUser).not.toHaveBeenCalled()});
});
