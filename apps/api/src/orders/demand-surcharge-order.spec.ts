import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../dispatch/dispatch.service.js',()=>({DispatchService:class{}}));
vi.mock('../delivery/delivery-pricing.service.js',()=>({DeliveryPricingService:class{}}));
vi.mock('../wallet/wallet.service.js',()=>({WalletService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{CUSTOMER:'CUSTOMER'},CourierStatus:{},UserStatus:{},PaymentStatus:{},OrderStatus:{}}));
import {OrdersService} from './orders.service.js';
function fixture(){
 const config={storeOpen:true,pricingRevision:1};
 const db:any={customerCreditEntry:{aggregate:vi.fn(async()=>({_sum:{amount:0}})),create:vi.fn()},$queryRawUnsafe:vi.fn(async()=>[]),deliveryPricingConfig:{findUnique:vi.fn(async()=>config)},courierDemandSignal:{findUnique:vi.fn(async()=>({mode:'MANUAL_ON',bonusAmount:2.5}))},address:{findFirst:vi.fn(async()=>({id:'a'}))},product:{findMany:vi.fn(async()=>[{id:'p',price:10,stock:10,name:'Produto'}])},order:{create:vi.fn(async({data}:any)=>({id:'order',...data}))}};
 db.$transaction=vi.fn(async(fn:any)=>fn(db));
 const pricing:any={quoteForAddress:vi.fn(async()=>({deliveryFee:8,baseDeliveryFee:5.5,demandSurcharge:2.5,pricingRevision:1,distanceKm:3,durationMinutes:10}))};
 const realtime:any={emitToRole:vi.fn()};
 const service=new OrdersService(db,{authenticate:async()=>({id:'u',role:'CUSTOMER'})} as any,pricing,{}as any,{}as any,realtime);
 const data={addressId:'a',items:[{productId:'p',quantity:2}],pricingRevision:1,expectedDeliveryFee:8};
 return{db,config,pricing,realtime,service,data};
}
describe('Congelamento do adicional antes do pagamento',()=>{
 it('aplica voucher somente em produtos e mantém entrega integral',async()=>{const f=fixture();f.db.customerCreditEntry.aggregate.mockResolvedValue({_sum:{amount:100}});const order=await f.service.create({...f.data,expectedTotal:8});expect(order).toMatchObject({storeCreditUsed:20,total:8,deliveryFee:8});expect(f.db.customerCreditEntry.create).toHaveBeenCalledWith({data:expect.objectContaining({amount:-20,idempotencyKey:'order:order:credit-use'})});});
 it('rejeita total confirmado com saldo de voucher desatualizado',async()=>{const f=fixture();await expect(f.service.create({...f.data,expectedTotal:20})).rejects.toThrow('Confirme');expect(f.db.order.create).not.toHaveBeenCalled();});
 it('persiste taxa final, adicional incluído e total acordado sem duplicação',async()=>{const f=fixture();const order=await f.service.create(f.data);expect(order).toMatchObject({deliveryFee:8,courierDemandBonus:2.5,demandSurchargeIncluded:true,subtotal:20,total:28});expect(f.db.$queryRawUnsafe).toHaveBeenCalledTimes(3);expect(f.realtime.emitToRole).toHaveBeenCalled()});
 it('rejeita troca de adicional durante a consulta de produtos, antes de criar o pedido',async()=>{const f=fixture();f.db.courierDemandSignal.findUnique.mockResolvedValue({mode:'MANUAL_ON',bonusAmount:5});await expect(f.service.create(f.data)).rejects.toThrow('Confirme');expect(f.db.order.create).not.toHaveBeenCalled();expect(f.realtime.emitToRole).not.toHaveBeenCalled()});
 it('rejeita taxa base alterada entre a cotação e a gravação',async()=>{const f=fixture();f.config.pricingRevision=2;await expect(f.service.create(f.data)).rejects.toThrow('Confirme');expect(f.db.order.create).not.toHaveBeenCalled()});
 it('rejeita desativação durante o checkout e solicita nova confirmação',async()=>{const f=fixture();f.db.courierDemandSignal.findUnique.mockResolvedValue({mode:'MANUAL_OFF',bonusAmount:2.5});await expect(f.service.create(f.data)).rejects.toThrow('Confirme');expect(f.db.order.create).not.toHaveBeenCalled()});
 it('sem alta demanda conserva R$ 5,50 e nenhum bônus',async()=>{const f=fixture();f.pricing.quoteForAddress.mockResolvedValue({deliveryFee:5.5,demandSurcharge:0,pricingRevision:1});f.db.courierDemandSignal.findUnique.mockResolvedValue({mode:'MANUAL_OFF',bonusAmount:2.5});expect(await f.service.create({...f.data,expectedDeliveryFee:5.5})).toMatchObject({deliveryFee:5.5,courierDemandBonus:0,total:25.5})});
});
