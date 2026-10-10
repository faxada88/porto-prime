import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../dispatch/dispatch.service.js',()=>({DispatchService:class{}}));
vi.mock('../wallet/wallet.service.js',()=>({WalletService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{ADMIN:'ADMIN'},CourierStatus:{},UserStatus:{},PaymentStatus:{},OrderStatus:{}}));
import {AdminService} from './admin.service.js';
function fixture(role='ADMIN'){
 const orders:any[]=[{id:'one',status:'OUT_FOR_DELIVERY',paymentStatus:'PAID',storeCreditUsed:10,items:[{issueId:'refund',availabilityStatus:'REFUND_PROCESSING'}],customer:{name:'Cliente'},adminDeletedAt:null},{id:'two',status:'CANCELED',paymentStatus:'REFUNDED',customer:{name:'Outro cliente'},adminDeletedAt:null}];
 const db:any={order:{findUnique:vi.fn(async({where}:any)=>orders.find(o=>o.id===where.id)),updateMany:vi.fn(async({where,data}:any)=>{const o=orders.find(o=>o.id===where.id&&o.adminDeletedAt===null);if(!o)return{count:0};Object.assign(o,data);return{count:1};}),findMany:vi.fn(async()=>orders.filter(o=>o.adminDeletedAt===null)),delete:vi.fn()},courierLedgerEntry:{deleteMany:vi.fn()},customerCreditEntry:{deleteMany:vi.fn()}};
 const realtime:any={emitToRole:vi.fn()};const service=new AdminService(db,{authenticate:async()=>({id:'admin',role})}as any,{}as any,{}as any,realtime);return{service,db,realtime,orders};
}
describe('Exclusão administrativa sem perda financeira',()=>{
 it('permite remover pedido em entrega com reembolso e voucher preservando registros',async()=>{const f=fixture();expect((await f.service.deleteOrder('one')).success).toBe(true);expect(f.orders[0].adminDeletedAt).toBeInstanceOf(Date);expect(f.orders[0].adminDeletedBy).toBe('admin');expect(f.orders[0].status).toBe('OUT_FOR_DELIVERY');expect(f.orders[0].items[0].availabilityStatus).toBe('REFUND_PROCESSING');expect(f.db.order.delete).not.toHaveBeenCalled();expect(f.db.courierLedgerEntry.deleteMany).not.toHaveBeenCalled();expect(f.db.customerCreditEntry.deleteMany).not.toHaveBeenCalled();expect(f.realtime.emitToRole).toHaveBeenCalledWith('ADMIN','order.admin.deleted',{id:'one'});});
 it('permite excluir cancelados e reembolsados em lote',async()=>{const f=fixture();const result=await f.service.bulkDeleteOrders(['one','two','two']);expect(result.deleted).toHaveLength(2);expect(result.failed).toHaveLength(0);expect(f.orders.every(o=>o.adminDeletedAt)).toBe(true);});
 it('excluir novamente é idempotente e mantém autor e data',async()=>{const f=fixture();await f.service.deleteOrder('one');const previous=f.orders[0].adminDeletedAt;await f.service.deleteOrder('one');expect(f.orders[0].adminDeletedAt).toBe(previous);expect(f.realtime.emitToRole).toHaveBeenCalledTimes(1);});
 it('listas administrativas ocultam removidos',async()=>{const f=fixture();await f.service.deleteOrder('one');const result=await f.service.orders();expect(result.map(o=>o.id)).toEqual(['two']);expect(f.db.order.findMany).toHaveBeenCalledWith(expect.objectContaining({where:{adminDeletedAt:null}}));});
 it('mantém exclusão restrita a administrador',async()=>{const f=fixture('CUSTOMER');await expect(f.service.deleteOrder('one')).rejects.toThrow('exclusivo');expect(f.db.order.updateMany).not.toHaveBeenCalled();});
 it('informa falhas por ID sem desfazer as exclusões válidas',async()=>{const f=fixture();const result=await f.service.bulkDeleteOrders(['one','missing']);expect(result.deleted).toHaveLength(1);expect(result.failed).toEqual([{id:'missing',reason:'Pedido não encontrado'}]);});
});
