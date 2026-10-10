import {describe,expect,it,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{COURIER:'COURIER'}}));
import {CouriersService} from './couriers.service.js';
describe('Consulta pública de candidatura',()=>{
 it('consulta CPF formatado sem sessão e retorna aprovação e acesso atuais',async()=>{const findUnique=vi.fn(async()=>({user:{name:'João Santos',status:'ACTIVE'},approvalStatus:'APPROVED',requirements:[]}));const service=new CouriersService({courierProfile:{findUnique}}as any,{}as any,{}as any);expect(await service.status('529.982.247-25')).toMatchObject({found:true,name:'João S.',approvalStatus:'APPROVED',userStatus:'ACTIVE'});expect(findUnique.mock.calls[0][0].where.document).toBe('52998224725')});
 it('resposta atrasada não reabre solicitação cancelada',async()=>{const updateMany=vi.fn(async()=>({count:0}));const service=new CouriersService({courierRequirement:{findFirst:async()=>({id:'r',status:'OPEN'}),updateMany}}as any,{}as any,{}as any);await expect(service.publicRespond('r','52998224725','Resposta')).rejects.toThrow('cancelada');expect(updateMany.mock.calls[0][0].where).toMatchObject({status:{not:'RESOLVED'},canceledAt:null})});
});
