import { afterEach, describe, expect, it, vi } from 'vitest';
import { liveDeviceWhere, reconcileCourierPresence, PRESENCE_TTL_MS } from './courier-presence.js';

import { presenceFixture } from './courier-presence.fixture.js';
afterEach(() => vi.useRealTimers());
describe('Operational courier presence', () => {
  it('requires an unrevoked, unexpired session with a fresh heartbeat', () => {
    const now = new Date();
    expect(liveDeviceWhere(now)).toMatchObject({ onlineRequested: true, session: { revokedAt: null, user: { status: 'ACTIVE' } } });
    expect(liveDeviceWhere(now).lastHeartbeatAt.gt.getTime()).toBe(now.getTime() - PRESENCE_TTL_MS);
  });
  it.each(['stale', 'revoked', 'expired', 'offline'])('removes %s devices from availability and releases pending offers', async reason => {
    const f = presenceFixture();
    if (reason === 'stale') f.devices[0].lastHeartbeatAt = new Date(0);
    if (reason === 'revoked') f.devices[0].session.revokedAt = new Date();
    if (reason === 'expired') f.devices[0].session.refreshExpiresAt = new Date(0);
    if (reason === 'offline') f.devices[0].onlineRequested = false;
    f.offers.push({ id: 'offer', orderId: 'o', status: 'PENDING' });
    f.orders.push({ id: 'o', courierId: null, activeOfferId: 'offer' });
    const result = await reconcileCourierPresence(f.db, 'c');
    expect(result).toMatchObject({isOnline: false, presenceStatus: 'OFFLINE', changed: true});
    expect(f.offers[0].status).toBe('CANCELED');
    expect(f.orders[0].activeOfferId).toBeNull();
  });
  it('keeps a second live session online when the first session logs out', async () => {
    const f = presenceFixture();
    f.devices.push({...f.devices[0], sessionId: 's2', session: {...f.devices[0].session}});
    f.devices[0].session.revokedAt = new Date();
    expect(await reconcileCourierPresence(f.db, 'c')).toMatchObject({isOnline: true, presenceStatus: 'AVAILABLE'});
  });
  it.each(['PENDING', 'SUSPENDED', 'BLOCKED'])('makes %s unavailable without revoking authentication', async status => {
    const f = presenceFixture(); f.profile.user.status = status;
    expect(await reconcileCourierPresence(f.db, 'c')).toMatchObject({isOnline: false, presenceStatus: 'OFFLINE'});
    expect(f.devices[0].onlineRequested).toBe(false);
    expect(f.devices[0].session.revokedAt).toBeNull();
  });
  it('does not re-enable availability merely because the Admin approved the account', async () => {
    const f = presenceFixture(); f.profile.user.status = 'PENDING';
    await reconcileCourierPresence(f.db, 'c');
    f.profile.user.status = 'ACTIVE';
    expect(await reconcileCourierPresence(f.db, 'c')).toMatchObject({isOnline: false});
  });
  it('does not cancel or reassign an already accepted delivery on disconnect', async () => {
    const f = presenceFixture(); f.devices[0].onlineRequested = false;
    f.orders.push({id: 'o', courierId: 'c', status: 'OUT_FOR_DELIVERY'});
    await reconcileCourierPresence(f.db, 'c');
    expect(f.orders[0]).toEqual({id: 'o', courierId: 'c', status: 'OUT_FOR_DELIVERY'});
  });
});
