import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../dispatch/dispatch.service.js',()=>({DispatchService:class{}}));
vi.mock('../wallet/wallet.service.js',()=>({WalletService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{ADMIN:'ADMIN'},CourierStatus:{},UserStatus:{},PaymentStatus:{},OrderStatus:{}}));
import {AdminService} from './admin.service.js';
import {ProductsService} from '../products/products.service.js';
function fixture(role='ADMIN'){
 const prisma:any={category:{findMany:vi.fn(async()=>[{id:'empty',name:'Nova categoria'}]),findUnique:vi.fn(async()=>({id:'cat',archived:false})),findFirst:vi.fn(async()=>null),create:vi.fn(async a=>a.data),update:vi.fn(async a=>a.data)},product:{findUnique:vi.fn(async()=>({id:'p'})),findMany:vi.fn(async()=>[]),create:vi.fn(async a=>a.data),update:vi.fn(async a=>a.data)},deliveryPricingConfig:{upsert:vi.fn(async a=>a.update),findUnique:vi.fn(async()=>null)}};
 const realtime:any={emitCatalogUpdated:vi.fn()};
 return{prisma,realtime,service:new AdminService(prisma,{authenticate:async()=>({role})} as any,{} as any,{} as any,realtime)};
}
describe('Catalog control',()=>{
 it('blocks non-admin writes before any mutation',async()=>{const f=fixture('CUSTOMER');await expect(f.service.updateStore({storeOpen:false})).rejects.toThrow();await expect(f.service.updateProduct('p',{active:false})).rejects.toThrow();expect(f.prisma.product.findUnique).not.toHaveBeenCalled();expect(f.prisma.deliveryPricingConfig.upsert).not.toHaveBeenCalled()});
 it('validates price stock and boolean values',async()=>{const f=fixture();for(const body of [{price:-1},{price:1.999},{stock:0.5},{active:'false'},{stock:-1}])await expect(f.service.updateProduct('p',body)).rejects.toThrow();expect(f.prisma.product.update).not.toHaveBeenCalled();expect(f.realtime.emitCatalogUpdated).not.toHaveBeenCalled()});
 it('saves all product fields and emits after persistence',async()=>{const f=fixture();expect(await f.service.createProduct({categoryId:'cat',name:' Água ',price:3.5,stock:8,description:' Mineral ',imageUrl:'https://assets.example.test/water.png'})).toMatchObject({name:'Água',description:'Mineral',stock:8,price:3.5,categoryId:'cat'});expect(f.realtime.emitCatalogUpdated).toHaveBeenCalledOnce()});
 it('archives and restores without deleting historical records',async()=>{const f=fixture();await f.service.updateProduct('p',{archived:true});expect(f.prisma.product.update).toHaveBeenCalledWith({where:{id:'p'},data:{archived:true}});await f.service.updateProduct('p',{archived:false});expect(f.prisma.product.update).toHaveBeenLastCalledWith({where:{id:'p'},data:{archived:false}})});
 it('rejects unsafe image protocols and credentials',async()=>{const f=fixture();for(const imageUrl of ['javascript:alert(1)','http://example.test/a.png','https://u:secret@example.test/a.png'])await expect(f.service.updateProduct('p',{imageUrl})).rejects.toThrow('HTTPS')});
 it('rejects archived category assignments',async()=>{const f=fixture();f.prisma.category.findUnique.mockResolvedValue({archived:true});await expect(f.service.updateProduct('p',{categoryId:'cat'})).rejects.toThrow('arquivada');expect(f.prisma.product.update).not.toHaveBeenCalled()});
 it('normalizes slug and rejects category duplicates',async()=>{const f=fixture();expect(await f.service.createCategory({name:' Águas ',position:3})).toMatchObject({name:'Águas',slug:'aguas',position:3});f.prisma.category.findFirst.mockResolvedValue({id:'duplicate'});await expect(f.service.updateCategory('cat',{name:'Águas'})).rejects.toThrow('já cadastrada')});
 it('changes store state without touching pricing',async()=>{const f=fixture();await f.service.updateStore({storeOpen:false,storeMessage:'Voltamos às 18h',baseFee:0});expect(f.prisma.deliveryPricingConfig.upsert.mock.calls[0][0].update).toEqual({storeOpen:false,storeMessage:'Voltamos às 18h'});expect(f.realtime.emitCatalogUpdated).toHaveBeenCalledWith('store.updated',{storeOpen:false,storeMessage:'Voltamos às 18h'})});
 it('does not emit success when persistence fails',async()=>{const f=fixture();f.prisma.product.update.mockRejectedValue(new Error('write failed'));await expect(f.service.updateProduct('p',{stock:2})).rejects.toThrow();expect(f.realtime.emitCatalogUpdated).not.toHaveBeenCalled()});
 it('hides archived products and inactive categories from public catalog',async()=>{const f=fixture();await new ProductsService(f.prisma).findAll();expect(f.prisma.product.findMany.mock.calls[0][0].where).toEqual({active:true,archived:false,category:{active:true,archived:false}})});
 it('includes empty active categories in the public category list',async()=>{const f=fixture();expect(await new ProductsService(f.prisma).categories()).toEqual([{id:'empty',name:'Nova categoria'}]);expect(f.prisma.category.findMany.mock.calls[0][0].where).toEqual({active:true,archived:false})});
 it('public store read selects no private configuration',async()=>{const f=fixture();expect(await new ProductsService(f.prisma).store()).toMatchObject({storeOpen:true});expect(f.prisma.deliveryPricingConfig.findUnique.mock.calls[0][0].select).toEqual({storeOpen:true,storeMessage:true,updatedAt:true})});
});
