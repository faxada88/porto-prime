import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
vi.mock('../prisma/prisma.service.js', () => ({ PrismaService: class {} }));
vi.mock('../realtime/realtime.gateway.js', () => ({ RealtimeGateway: class {} }));
import { DispatchService } from './dispatch.service.js';

function fixture(count: number) {
  const order: any = { id: 'order-test', status: 'SEARCHING_COURIER', courierId: null, activeOfferId: null, paymentStatus: 'PAID', address: {}, items: [] };
  const couriers: any[] = Array.from({ length: count }, (_, i) => ({ id: `courier-${i}`, user: { id: `user-${i}`, name: 'Test' }, approvalStatus: 'APPROVED', isOnline: true, presenceStatus: 'AVAILABLE', lastHeartbeatAt: new Date(), availableSince: new Date(), currentLatitude: i, currentLongitude: i, locationUpdatedAt: new Date(), busy: false, deliveryOffers: [] }));
  const offers: any[] = [];
  const prisma: any = {
    courierDemandSignal: {findUnique: async()=>({mode:"MANUAL_OFF",bonusAmount:2.5})},
    deliveryPricingConfig: { upsert: async () => ({ offerTimeoutSeconds: 15, heartbeatTimeoutSeconds: 60, distributorName: 'Test', distributorLatitude: 0, distributorLongitude: 0 }) },
    order: {
      findUnique: async () => ({ ...order }),
      updateMany: async ({ where, data }: any) => {
        if (order.status !== where.status || order.courierId !== where.courierId || order.activeOfferId !== where.activeOfferId) return { count: 0 };
        Object.assign(order, data); return { count: 1 };
      },
    },
    courierProfile: {
      findMany: vi.fn(async ({ where }: any) => couriers.filter(c => c.isOnline === where.isOnline && c.presenceStatus === where.presenceStatus && c.approvalStatus === where.approvalStatus && c.lastHeartbeatAt >= where.lastHeartbeatAt.gte && !c.busy && !(where.deliveryOffers?.none && offers.some(o => o.courierId === c.id))).map(c => ({ ...c, deliveryOffers: offers.filter(o => o.courierId === c.id) }))),
      updateMany: async ({ where, data }: any) => {
        const courier = couriers.find(c => c.id === where.id && c.presenceStatus === where.presenceStatus && c.lastHeartbeatAt >= where.lastHeartbeatAt.gte);
        if (!courier) return { count: 0 };
        Object.assign(courier, data); return { count: 1 };
      },
    },
    deliveryOffer: {
      groupBy: async ({ where }: any) => couriers.filter(c => where.courierId.in.includes(c.id)).map(c => ({ courierId: c.id, _max: { offeredAt: offers.filter(o => o.courierId === c.id && o.orderId === where.orderId).reduce((latest, o) => !latest || o.offeredAt > latest ? o.offeredAt : latest, null) } })),
      create: async ({ data }: any) => {
        const offer = { ...data, offeredAt: new Date(), order: { ...order }, courier: couriers.find(c => c.id === data.courierId) };
        offers.push(offer); return offer;
      },
    },
    dispatchEvent: { create: async () => ({}) },
  };
  prisma.$transaction = async (fn: any) => fn(prisma);
  const realtime: any = { emitToUser: vi.fn(), emitToRole: vi.fn() };
  const service = new DispatchService(prisma, realtime);
  function close(status: 'EXPIRED' | 'DECLINED') {
    const offer = offers.at(-1)!;
    offer.status = status;
    couriers.find(c => c.id === offer.courierId).presenceStatus = 'AVAILABLE';
    order.activeOfferId = null;
    vi.advanceTimersByTime(10);
  }
  return { service, order, couriers, offers, close, prisma };
}

beforeEach(() => { vi.useFakeTimers(); vi.setSystemTime(new Date('2026-10-08T12:00:00Z')); });
afterEach(() => vi.useRealTimers());
describe('delivery offer rotation without permanent exclusions', () => {
  it.each([1, 2, 3, 4])('continues for three full rounds with %i couriers', async count => {
    const f = fixture(count);
    for (let i = 0; i < count * 3; i++) {
      expect(await f.service.dispatchOrder(f.order.id)).not.toBeNull();
      expect(f.offers.at(-1).courierId).toBe(`courier-${i % count}`);
      f.close(i % 2 === 0 ? 'EXPIRED' : 'DECLINED');
    }
    expect(f.offers).toHaveLength(count * 3);
    expect(f.offers.every(o => ['EXPIRED', 'DECLINED'].includes(o.status))).toBe(true);
  });
  it('does not turn a requested-online courier offline on a stale heartbeat', async () => {
    const f = fixture(1);
    f.couriers[0].lastHeartbeatAt = new Date(0);
    await f.service.markStaleCouriersOffline();
    expect(f.couriers[0].isOnline).toBe(true);
    expect(f.couriers[0].presenceStatus).toBe('AVAILABLE');
    expect(await f.service.dispatchOrder(f.order.id)).toBeNull();
  });
  it('respects a manual offline choice even if availability is stale', async () => {
    const f = fixture(1);
    f.couriers[0].isOnline = false;
    expect(await f.service.dispatchOrder(f.order.id)).toBeNull();
  });
  it('retains one active offer and stops after assignment', async () => {
    const f = fixture(2);
    await f.service.dispatchOrder(f.order.id);
    expect(await f.service.dispatchOrder(f.order.id)).toBeNull();
    expect(f.offers).toHaveLength(1);
    f.order.activeOfferId = null;
    f.order.courierId = 'courier-0';
    f.order.status = 'COURIER_ASSIGNED';
    expect(await f.service.dispatchOrder(f.order.id)).toBeNull();
    expect(f.offers).toHaveLength(1);
  });
  it('skips offline, busy and stale couriers when recycling offers', async () => {
    const f = fixture(4);
    f.couriers[0].presenceStatus = 'OFFLINE';
    f.couriers[1].busy = true;
    f.couriers[2].lastHeartbeatAt = new Date(0);
    for (let i = 0; i < 3; i++) {
      await f.service.dispatchOrder(f.order.id);
      expect(f.offers.at(-1).courierId).toBe('courier-3');
      f.close('EXPIRED');
    }
  });
  it('keeps searching when no courier is available and resumes on availability', async () => {
    const f = fixture(1);
    f.couriers[0].presenceStatus = 'OFFLINE';
    expect(await f.service.dispatchOrder(f.order.id)).toBeNull();
    expect(f.order.status).toBe('SEARCHING_COURIER');
    f.couriers[0].presenceStatus = 'AVAILABLE';
    expect(await f.service.dispatchOrder(f.order.id)).not.toBeNull();
  });
  it('prioritizes a newly available courier who has not received the order', async () => {
    const f = fixture(3);
    f.couriers[2].presenceStatus = 'OFFLINE';
    await f.service.dispatchOrder(f.order.id); f.close('EXPIRED');
    await f.service.dispatchOrder(f.order.id); f.close('DECLINED');
    f.couriers[2].presenceStatus = 'AVAILABLE';
    await f.service.dispatchOrder(f.order.id);
    expect(f.offers.at(-1).courierId).toBe('courier-2');
  });
});

describe('Oferta com adicional cobrado no checkout',()=>{
 it('usa o adicional congelado no pedido e exibe ganhos sem somar novamente',async()=>{const f=fixture(1);Object.assign(f.order,{deliveryFee:8,courierDemandBonus:2.5,demandSurchargeIncluded:true});const payload=await f.service.dispatchOrder(f.order.id);expect(payload).toMatchObject({deliveryFee:8,demandBonus:2.5,courierEarnings:8});expect(f.offers[0].demandBonus).toBe(2.5);f.close('DECLINED');expect(await f.service.dispatchOrder(f.order.id)).toMatchObject({demandBonus:2.5,courierEarnings:8})});
});
