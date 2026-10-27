import { expect, vi } from 'vitest';
export function presenceFixture() {
  const now = new Date();
  const profile: any = { id: 'c', userId: 'u', user: { status: 'ACTIVE' }, approvalStatus: 'APPROVED', isOnline: true, presenceStatus: 'AVAILABLE' };
  const devices: any[] = [{ courierId: 'c', sessionId: 's1', onlineRequested: true, lastHeartbeatAt: now,
    session: { revokedAt: null, refreshExpiresAt: new Date(now.getTime() + 60000), user: profile.user } }];
  const offers: any[] = [];
  const orders: any[] = [];
  const db: any = {
    $queryRawUnsafe: vi.fn(async () => []),
    courierProfile: { findUnique: vi.fn(async () => ({...profile})), update: vi.fn(async ({ data }: any) => { Object.assign(profile, data); return { ...profile }; }) },
    courierDevicePresence: {
      count: vi.fn(async ({ where }: any) => devices.filter(d => d.onlineRequested && d.lastHeartbeatAt > where.lastHeartbeatAt.gt && !d.session.revokedAt && d.session.refreshExpiresAt > where.session.refreshExpiresAt.gt && d.session.user.status === where.session.user.status).length),
      findUnique: vi.fn(async ({ where }: any) => devices.find(d => d.sessionId === where.sessionId)),
      updateMany: vi.fn(async ({ where, data }: any) => { devices.filter(d => !where.sessionId || where.sessionId === d.sessionId).forEach(d => Object.assign(d, data)); return { count: 1 }; }),
      upsert: vi.fn(async ({ where, create, update }: any) => {
        const d = devices.find(d => d.sessionId === where.sessionId);
        if (d) Object.assign(d, update); else devices.push(create);
      }),
      findFirst: vi.fn(async ({ where }: any) => devices.find(d => d.onlineRequested && d.lastHeartbeatAt > where.lastHeartbeatAt.gt && !d.session.revokedAt && d.session.refreshExpiresAt > where.session.refreshExpiresAt.gt && d.session.user.status === where.session.user.status) ?? null),
    },
    deliveryOffer: {
      findMany: vi.fn(async () => offers.filter(o => o.status === 'PENDING')),
      findFirst: vi.fn(async ({where}: any) => { expect(where.order).toEqual({adminDeletedAt: null}); return offers.find(o => o.status === 'PENDING' && o.expiresAt > where.expiresAt.gt) ?? null; }),
      updateMany: vi.fn(async ({ where, data }: any) => { offers.filter(o => o.id === where.id && o.status === where.status).forEach(o => Object.assign(o, data)); }),
    },
    order: {
      findFirst: vi.fn(async () => orders.find(o => o.courierId === 'c' && !['DELIVERED', 'CANCELED'].includes(o.status)) ?? null),
      updateMany: vi.fn(async ({ where, data }: any) => { orders.filter(o => o.id === where.id && o.activeOfferId === where.activeOfferId && o.courierId === null).forEach(o => Object.assign(o, data)); }),
    },
  };
  db.$transaction = (fn: any) => fn(db);
  return {db, profile, devices, offers, orders};
}
