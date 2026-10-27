import { EventEmitter } from 'node:events';
import { describe, expect, it, vi } from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
import { RealtimeGateway } from './realtime.gateway.js';
describe('Courier socket lifecycle',()=>{
  function fixture(){
    const auth:any={presenceEvents:new EventEmitter(),syncSessionPresence:vi.fn(),syncCourierPresence:vi.fn()};
    const db:any={courierDevicePresence:{updateMany:vi.fn(async()=>({count:1}))}};
    const gateway=new RealtimeGateway(auth,db);
    const sockets=new Map<string,any>();
    gateway.server={sockets:{sockets}} as any;
    return {auth,db,gateway,sockets};
  }
  it('marks only the disconnected session unavailable before reconciling',async()=>{
    const f=fixture();await f.gateway.handleDisconnect({id:'old',data:{sessionId:'s1',courierId:'c'}} as any);
    expect(f.db.courierDevicePresence.updateMany).toHaveBeenCalledWith({where:{sessionId:'s1'},data:{onlineRequested:false}});
    expect(f.auth.syncSessionPresence).toHaveBeenCalledWith('s1');
  });
  it('ignores an old socket disconnect if that same session already reconnected',async()=>{
    const f=fixture();f.sockets.set('new',{id:'new',data:{sessionId:'s1'}});
    await f.gateway.handleDisconnect({id:'old',data:{sessionId:'s1',courierId:'c'}} as any);
    expect(f.db.courierDevicePresence.updateMany).not.toHaveBeenCalled();
  });
  it('does not touch presence when a customer disconnects',async()=>{
    const f=fixture();await f.gateway.handleDisconnect({id:'customer',data:{sessionId:'s2'}} as any);
    expect(f.db.courierDevicePresence.updateMany).not.toHaveBeenCalled();
  });
});
