import { describe,it,expect,vi } from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('../auth/auth.service.js',()=>({AuthService:class{}}));
vi.mock('../realtime/realtime.gateway.js',()=>({RealtimeGateway:class{}}));
vi.mock('../generated/prisma/client.js',()=>({UserRole:{COURIER:'COURIER'}}));
import {validateProfilePhoto} from './profile-photo.js';
import {CouriersService} from './couriers.service.js';
const png='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=';
describe('Courier profile photo',()=>{
 it('accepts a bounded PNG image',()=>expect(validateProfilePhoto(png)).toBe(png));
 it.each(['data:image/svg+xml;base64,PHN2Zz4=','https://example.test/photo.jpg','data:image/jpeg;base64,aaaa',null])('rejects arbitrary URLs, SVGs and invalid payloads',raw=>expect(()=>validateProfilePhoto(raw)).toThrow());
 it('rejects oversized payloads and dimensions',()=>{expect(()=>validateProfilePhoto('data:image/png;base64,'+'a'.repeat(90000))).toThrow();const bytes=Buffer.from(png.split(',')[1],'base64');bytes.writeUInt32BE(10000,16);expect(()=>validateProfilePhoto('data:image/png;base64,'+bytes.toString('base64'))).toThrow()});
 it('updates only the authenticated courier and notifies the active customer',async()=>{
  const current:any={id:'c',userId:'u',user:{name:'Name'},onboardingData:{pixKey:'old@example.test'}};
  const update=vi.fn(async()=>({}));const tx:any={$queryRawUnsafe:vi.fn(async()=>[]),courierProfile:{findUnique:async()=>({...current,onboardingData:{pixKey:'new@example.test',street:'New'}}),update}};
  const prisma:any={courierProfile:{findUnique:vi.fn(async()=>current)},$transaction:async(fn:any)=>fn(tx),order:{findMany:vi.fn(async()=>[{id:'o',customerId:'customer',status:'OUT_FOR_DELIVERY'}])}};
  const realtime:any={emitToUser:vi.fn(),emitToRole:vi.fn(),emitOrderUpdated:vi.fn()};
  const service=new CouriersService(prisma,{authenticate:async()=>({id:'u',role:'COURIER'})} as any,realtime);
  await service.savePhoto(png,'token');
  expect(update.mock.calls[0][0].where).toEqual({id:'c'});
  expect(update.mock.calls[0][0].data.onboardingData).toMatchObject({pixKey:'new@example.test',street:'New',profilePhoto:png});
  expect(realtime.emitToUser).toHaveBeenCalledWith('u','courier.profile.updated',{courierId:'c'});
  expect(realtime.emitOrderUpdated).toHaveBeenCalledWith({id:'o',customerId:'customer',status:'OUT_FOR_DELIVERY'});
 });
 it('rejects non-courier uploads before accessing profile data',async()=>{const prisma:any={courierProfile:{findUnique:vi.fn()}};const service=new CouriersService(prisma,{authenticate:async()=>({id:'customer',role:'CUSTOMER'})} as any,{} as any);await expect(service.savePhoto(png)).rejects.toThrow('motoboy');expect(prisma.courierProfile.findUnique).not.toHaveBeenCalled()});
});
