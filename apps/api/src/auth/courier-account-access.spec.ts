import { describe, expect, it, vi } from 'vitest';
vi.mock('../prisma/prisma.service.js', () => ({ PrismaService: class {} }));
import { AuthService } from './auth.service.js';

function fixture(role = 'COURIER', status = 'PENDING') {
  const user: any = { id: 'u', role, status, name: 'João', email: 'u@test.local' };
  const session: any = {id: 's', userId: 'u', user, expiresAt: new Date(Date.now()+60000), refreshExpiresAt: new Date(Date.now()+600000), lastSeenAt: new Date(), revokedAt: null};
  const db: any = { user: {findUnique: vi.fn(async()=>user)}, authSession: {findUnique: vi.fn(async()=>session), deleteMany: vi.fn(), update: vi.fn()} };
  const service = new AuthService(db, {} as any);
  user.passwordHash = (service as any).hashPassword('correct-password');
  const issue = vi.spyOn(service as any, 'issueSession').mockResolvedValue({token: 'valid', user});
  return {user, session, db, service, issue};
}
describe('Restricted courier account access', () => {
  it.each(['PENDING','SUSPENDED','BLOCKED'])('allows %s to authenticate and read its account, but not use operational endpoints', async status => {
    const f = fixture('COURIER', status);
    expect(await f.service.login({email: f.user.email, password: 'correct-password'})).toMatchObject({token: 'valid'});
    expect(await f.service.me('Bearer token')).toMatchObject({id: 'u', status});
    await expect(f.service.authenticate('Bearer token')).rejects.toMatchObject({status: 403});
    expect(await f.service.authenticate('Bearer token', true)).toMatchObject({id: 'u'});
    expect(await f.service.refresh('refresh')).toHaveProperty('accessToken');
  });
  it.each(['CUSTOMER','PARTNER','ADMIN'])('does not grant restricted %s a courier exception', async role => {
    const f=fixture(role);
    await expect(f.service.login({email:f.user.email,password:'correct-password'})).rejects.toThrow('aprovação');
    await expect(f.service.authenticate('Bearer token',true)).rejects.toMatchObject({status:403});
  });
  it('still rejects wrong passwords and revoked sessions', async()=>{
    const f=fixture();
    await expect(f.service.login({email:f.user.email,password:'wrong'})).rejects.toThrow('inválidos');
    f.session.revokedAt=new Date();
    await expect(f.service.me('Bearer token')).rejects.toMatchObject({status:401});
  });
  it('restores operational authorization in the same session after approval', async()=>{
    const f=fixture();
    await expect(f.service.authenticate('Bearer token')).rejects.toMatchObject({status:403});
    f.user.status='ACTIVE';
    expect(await f.service.authenticate('Bearer token')).toMatchObject({id:'u',status:'ACTIVE'});
    expect(f.issue).not.toHaveBeenCalled();
  });
});
