import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
import {OrdersService} from './orders.service.js';
import {presenceFixture} from '../auth/courier-presence.fixture.js';
import {reconcileCourierPresence} from '../auth/courier-presence.js';
function fixture(){
 const f=presenceFixture();
 const auth:any={authenticateSession:vi.fn().mockResolvedValue({id:'s1',user:{id:'u',role:'COURIER',status:'ACTIVE'}}),syncCourierPresence:(id:string)=>reconcileCourierPresence(f.db,id)};
 return {...f,service:new OrdersService(f.db,auth,{} as any,{} as any,{} as any,{} as any)};
}
describe('Courier heartbeat and offer eligibility',()=>{
 it('refreshes a live session and preserves the related order filter',async()=>{const f=fixture();expect(await f.service.courierHeartbeat({},'token')).toMatchObject({isOnline:true,presenceStatus:'AVAILABLE'});expect(f.db.deliveryOffer.findFirst).toHaveBeenCalled();});
 it('preserves a real pending offer',async()=>{const f=fixture();f.offers.push({id:'offer',status:'PENDING',expiresAt:new Date(Date.now()+60000)});expect(await f.service.courierHeartbeat({},'token')).toMatchObject({isOnline:true,presenceStatus:'OFFERED'});});
 it('keeps a manual offline choice across subsequent heartbeats',async()=>{const f=fixture();expect(await f.service.courierHeartbeat({online:false},'token')).toMatchObject({isOnline:false,presenceStatus:'OFFLINE'});expect(await f.service.courierHeartbeat({},'token')).toMatchObject({isOnline:false});expect(f.db.courierDevicePresence.upsert.mock.calls.at(-1)[0].update).not.toHaveProperty('onlineRequested');});
 it('does not activate other sessions when one device goes online',async()=>{const f=fixture();f.devices.push({...f.devices[0],sessionId:'s2',onlineRequested:false});await f.service.courierHeartbeat({online:true},'token');expect(f.devices[1].onlineRequested).toBe(false);});
 it('refuses heartbeat for a profile not approved',async()=>{const f=fixture();f.profile.approvalStatus='PENDING';await expect(f.service.courierHeartbeat({online:true},'token')).rejects.toThrow('liberado');expect(f.db.courierDevicePresence.upsert).not.toHaveBeenCalled();});
});
