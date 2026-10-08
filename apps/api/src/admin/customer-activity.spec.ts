import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../dispatch/dispatch.service.js',()=>({DispatchService:class{}}));
vi.mock('../wallet/wallet.service.js',()=>({WalletService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{ADMIN:'ADMIN',CUSTOMER:'CUSTOMER'},CourierStatus:{},UserStatus:{},PaymentStatus:{PAID:'PAID'},OrderStatus:{DELIVERED:'DELIVERED',CANCELED:'CANCELED'}}));
import {AdminService} from './admin.service.js';
function fixture(role='ADMIN',customerRole='CUSTOMER'){
 const user={id:'customer',name:'Name',role:customerRole,customerProfile:{onboardingData:{cpf:'52998224725',password:'hidden',nested:{token:'hidden',city:'Porto Seguro'}}}};
 const prisma:any={user:{findUnique:vi.fn(async()=>user)},order:{findMany:vi.fn(async()=>[{id:'o',deliveryPin:'1234',deliveryPinAttempts:2,stripePaymentIntentId:'pi_private',items:[]}]),count:vi.fn(async()=>21),aggregate:vi.fn(async()=>({_sum:{total:150},_count:3}))},address:{findMany:vi.fn(async()=>[])},authSession:{findMany:vi.fn(async()=>[])}};
 return{prisma,service:new AdminService(prisma,{authenticate:async()=>({role})} as any,{} as any,{} as any,{} as any)};
}
describe('Admin customer activity',()=>{
 it('rejects non-admin access before reading customer data',async()=>{const f=fixture('CUSTOMER');await expect(f.service.customerActivity('customer')).rejects.toThrow('administrador');expect(f.prisma.user.findUnique).not.toHaveBeenCalled()});
 it('does not expose another role as a customer',async()=>{const f=fixture('ADMIN','COURIER');await expect(f.service.customerActivity('customer')).rejects.toThrow('Cliente');expect(f.prisma.order.findMany).not.toHaveBeenCalled()});
 it('scopes all history and address/session queries to the selected customer',async()=>{const f=fixture();const r=await f.service.customerActivity('customer',2);expect(f.prisma.order.findMany.mock.calls[0][0]).toMatchObject({where:{customerId:'customer'},skip:20,take:20});expect(f.prisma.address.findMany.mock.calls[0][0].where).toEqual({userId:'customer'});expect(f.prisma.authSession.findMany.mock.calls[0][0].where.userId).toBe('customer');expect(r.totalPages).toBe(2);expect(r.summary.paidTotal).toBe(150)});
 it('excludes passwords, tokens, payment secrets and delivery PINs',async()=>{const f=fixture();const r=await f.service.customerActivity('customer');expect(r.user.customerProfile?.onboardingData).toEqual({cpf:'52998224725',nested:{city:'Porto Seguro'}});expect(r.orders[0]).not.toHaveProperty('deliveryPin');expect(r.orders[0]).not.toHaveProperty('stripePaymentIntentId');const fields=f.prisma.authSession.findMany.mock.calls[0][0].select;expect(fields).not.toHaveProperty('tokenHash');expect(f.prisma.user.findUnique.mock.calls[0][0].select).not.toHaveProperty('passwordHash')});
 it('normalizes an invalid history page',async()=>{const f=fixture();const r=await f.service.customerActivity('customer',NaN);expect(r.page).toBe(1);expect(f.prisma.order.findMany.mock.calls[0][0].skip).toBe(0)});
});
