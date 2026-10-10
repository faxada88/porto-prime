import {describe,expect,it,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
import {OperationDemandService} from './operation-demand.service.js';
function fixture(role='ADMIN'){
 const db:any={courierDemandSignal:{findUnique:vi.fn(async()=>null),upsert:vi.fn(async(args:any)=>({...args.create,revision:2,updatedAt:new Date(),secret:'private'}))}};
 const realtime:any={emitToRole:vi.fn()};
 return{db,realtime,service:new OperationDemandService(db,{authenticate:async()=>({id:'u',role})}as any,realtime)};
}
describe('Aviso manual de alta demanda',()=>{
 it('inicia desativado sem gravar nem modificar configuração de entrega',async()=>{const f=fixture();expect(await f.service.read(undefined,'ADMIN')).toEqual({enabled:false,revision:0,updatedAt:null});expect(f.db.courierDemandSignal.upsert).not.toHaveBeenCalled()});
 it('ativa após persistir e notifica exclusivamente os papéis operacionais',async()=>{const f=fixture();const payload=await f.service.set(true);expect(payload).toMatchObject({enabled:true,revision:2});expect(payload).not.toHaveProperty('updatedBy');expect(payload).not.toHaveProperty('secret');expect(f.realtime.emitToRole.mock.calls).toEqual([['COURIER','courier.demand.updated',payload],['ADMIN','courier.demand.updated',payload]]);expect(f.db.courierDemandSignal.upsert.mock.calls[0][0].update).toEqual({enabled:true,revision:{increment:1},updatedBy:'u'})});
 it('desativa e transmite remoção do aviso',async()=>{const f=fixture();expect(await f.service.set(false)).toMatchObject({enabled:false})});
 it.each(['COURIER','CUSTOMER','PARTNER'])('%s não pode ativar o sinal',async role=>{const f=fixture(role);await expect(f.service.set(true)).rejects.toThrow('administrador');expect(f.db.courierDemandSignal.upsert).not.toHaveBeenCalled()});
 it.each(['true',1,null,undefined])('recusa corpo inválido %s',async value=>{const f=fixture();await expect(f.service.set(value)).rejects.toThrow('Informe');expect(f.db.courierDemandSignal.upsert).not.toHaveBeenCalled()});
 it('consulta é permitida ao motoboy autenticado',async()=>{const f=fixture('COURIER');expect(await f.service.read(undefined,'COURIER')).toMatchObject({enabled:false})});
 it('motoboy não acessa rota administrativa',async()=>{const f=fixture('COURIER');await expect(f.service.read(undefined,'ADMIN')).rejects.toThrow('administrador')});
 it('não emite ativação quando a persistência falha',async()=>{const f=fixture();f.db.courierDemandSignal.upsert.mockRejectedValue(new Error('DB unavailable'));await expect(f.service.set(true)).rejects.toThrow('DB unavailable');expect(f.realtime.emitToRole).not.toHaveBeenCalled()});
});
