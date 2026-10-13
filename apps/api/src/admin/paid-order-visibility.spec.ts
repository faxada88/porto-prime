import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../dispatch/dispatch.service.js',()=>({DispatchService:class{}}));
vi.mock('../wallet/wallet.service.js',()=>({WalletService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
import {AdminService} from './admin.service.js';
it('o servidor exclui rascunhos pendentes e falhos da fila e conserva pagos/reembolsados',async()=>{
 const records=[{id:'draft',paymentStatus:'PENDING'},{id:'failed',paymentStatus:'FAILED'},{id:'paid',paymentStatus:'PAID'},{id:'refund',paymentStatus:'REFUNDED'}];
 const findMany=vi.fn(async({where}:any)=>records.filter(r=>where.paymentStatus.in.includes(r.paymentStatus)));
 const service=new AdminService({order:{findMany}}as any,{authenticate:async()=>({role:'ADMIN'})}as any,{}as any,{}as any,{}as any);
 expect((await service.orders()).map(r=>r.id)).toEqual(['paid','refund']);expect(findMany.mock.calls[0][0].where).toMatchObject({adminDeletedAt:null,paymentStatus:{in:['PAID','PARTIALLY_REFUNDED','REFUNDED']}});
});
