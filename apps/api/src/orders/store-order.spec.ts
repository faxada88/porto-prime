import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../dispatch/dispatch.service.js',()=>({DispatchService:class{}}));
vi.mock('../delivery/delivery-pricing.service.js',()=>({DeliveryPricingService:class{}}));
vi.mock('../wallet/wallet.service.js',()=>({WalletService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{CUSTOMER:'CUSTOMER'},CourierStatus:{},UserStatus:{},PaymentStatus:{},OrderStatus:{}}));
import {OrdersService} from './orders.service.js';
function fixture(open:boolean){
 const prisma:any={deliveryPricingConfig:{findUnique:vi.fn(async()=>({storeOpen:open,storeMessage:'Voltamos às 18h'}))},address:{findFirst:vi.fn(async()=>({id:'a'}))},product:{findMany:vi.fn(async()=>[])},order:{create:vi.fn()}};
 const pricing:any={quoteForAddress:vi.fn(async()=>({deliveryFee:5,pricingRevision:1}))};
 return{prisma,pricing,service:new OrdersService(prisma,{authenticate:async()=>({id:'u',role:'CUSTOMER'})} as any,pricing,{} as any,{} as any,{} as any)};
}
describe('New orders and store availability',()=>{
 it('requires renewed confirmation if delivery pricing changes',async()=>{const f=fixture(true);await expect(f.service.create({addressId:'a',items:[{productId:'p',quantity:1}],pricingRevision:2,expectedDeliveryFee:5})).rejects.toThrow('Confirme');expect(f.prisma.order.create).not.toHaveBeenCalled();expect(f.prisma.product.findMany).not.toHaveBeenCalled()});
 it('rejects an outdated displayed fee even when the revision matches',async()=>{const f=fixture(true);await expect(f.service.create({addressId:'a',items:[{productId:'p',quantity:1}],pricingRevision:1,expectedDeliveryFee:4})).rejects.toThrow('Confirme');expect(f.prisma.order.create).not.toHaveBeenCalled()});
 it('closed store blocks a new order before quoting or persisting',async()=>{const f=fixture(false);await expect(f.service.create({addressId:'a',items:[{productId:'p',quantity:1}]})).rejects.toThrow('Voltamos às 18h');expect(f.pricing.quoteForAddress).not.toHaveBeenCalled();expect(f.prisma.order.create).not.toHaveBeenCalled()});
 it('open store still rejects archived or inactive-category products',async()=>{const f=fixture(true);await expect(f.service.create({addressId:'a',items:[{productId:'p',quantity:1}]})).rejects.toThrow('indisponíveis');expect(f.prisma.product.findMany.mock.calls[0][0].where).toEqual({id:{in:['p']},active:true,archived:false,category:{active:true,archived:false}});expect(f.prisma.order.create).not.toHaveBeenCalled()});
});
