import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../dispatch/dispatch.service.js',()=>({DispatchService:class{}}));
vi.mock('../wallet/wallet.service.js',()=>({WalletService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../delivery/delivery-pricing.service.js',()=>({DeliveryPricingService:class{}}));
vi.mock('./dto/create-order.dto.js',()=>({CreateOrderDto:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{COURIER:'COURIER'},UserStatus:{ACTIVE:'ACTIVE'},CourierStatus:{APPROVED:'APPROVED'},PaymentStatus:{PAID:'PAID'},OrderStatus:Object.fromEntries(['DELIVERED','CANCELED','CONFIRMED','PREPARING','READY_FOR_PICKUP','SEARCHING_COURIER'].map(k=>[k,k]))}));
import {OrdersService} from './orders.service.js';
function fixture(role='COURIER',approvalStatus='APPROVED'){
 const prisma:any={courierProfile:{findUnique:async()=>({id:'c',approvalStatus})},order:{findMany:vi.fn(async()=>[{address:{neighborhood:'Centro',latitude:-16.441,longitude:-39.061}}]),count:vi.fn(async({where}:any)=>where.deliveredAt?2:1)}};
 const realtime:any={demandVersion:0};
 const service=new OrdersService(prisma,{authenticate:async()=>({id:'u',role,status:'ACTIVE'})} as any,{} as any,{} as any,{} as any,realtime);
 return{prisma,realtime,service};
}
describe('Courier radar read-only endpoint',()=>{
 it('is restricted to approved active couriers',async()=>{for(const [role,status] of [['CUSTOMER','APPROVED'],['COURIER','PENDING']]){const f=fixture(role,status);await expect(f.service.courierRadar()).rejects.toThrow();expect(f.prisma.order.findMany).not.toHaveBeenCalled()}});
 it('filters paid unassigned orders and reports a clearly defined completion rate',async()=>{const f=fixture();const r=await f.service.courierRadar();expect(f.prisma.order.findMany.mock.calls[0][0].where).toMatchObject({paymentStatus:'PAID',courierId:null});expect(r).toMatchObject({pendingOrders:1,completedToday:2,activeDeliveries:1,completionRate:67});expect(r.zones[0].latitude).toBe(-16.44)});
 it('reuses shared demand cache and invalidates it when operation changes',async()=>{const f=fixture();await f.service.courierRadar();await f.service.courierRadar();expect(f.prisma.order.findMany).toHaveBeenCalledTimes(1);f.realtime.demandVersion++;await f.service.courierRadar();expect(f.prisma.order.findMany).toHaveBeenCalledTimes(2)});
});
