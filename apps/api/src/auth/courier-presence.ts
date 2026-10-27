/** Session-scoped operational presence; never inferred from an old profile flag. */
export const PRESENCE_TTL_MS = 20_000;

export function liveDeviceWhere(now = new Date()) {
  return {
    onlineRequested: true,
    lastHeartbeatAt: { gt: new Date(now.getTime() - PRESENCE_TTL_MS) },
    session: { revokedAt: null, refreshExpiresAt: { gt: now }, user: { status: 'ACTIVE' as const } },
  };
}

export async function reconcileCourierPresence(prisma: any, courierId: string) {
  return prisma.$transaction(async (tx: any) => {
    await tx.$queryRawUnsafe('SELECT "id" FROM "CourierProfile" WHERE "id" = $1 FOR UPDATE', courierId);
    const profile = await tx.courierProfile.findUnique({ where: { id: courierId }, include: { user: true } });
    if (!profile) return null;
    const now = new Date();
    const allowed = profile.user.status === 'ACTIVE' && profile.approvalStatus === 'APPROVED';
    if (!allowed) await tx.courierDevicePresence.updateMany({ where: { courierId }, data: { onlineRequested: false } });
    const device = allowed ? await tx.courierDevicePresence.findFirst({ where: { courierId, ...liveDeviceWhere(now) }, orderBy: { lastHeartbeatAt: 'desc' } }) : null;
    const isOnline = !!device;
    const closed = !isOnline ? await tx.deliveryOffer.findMany({ where: { courierId, status: 'PENDING' }, select: { id: true, orderId: true } }) : [];
    for (const offer of closed) {
      await tx.deliveryOffer.updateMany({ where: { id: offer.id, status: 'PENDING' }, data: { status: 'CANCELED', canceledAt: now, respondedAt: now } });
      await tx.order.updateMany({ where: { id: offer.orderId, activeOfferId: offer.id, courierId: null }, data: { activeOfferId: null } });
    }
    const delivery = isOnline && await tx.order.findFirst({ where: { courierId, OR: [{ adminDeletedAt: null, status: { notIn: ['DELIVERED', 'CANCELED'] } }, { cancellation: { is: { returnStatus: { in: ['REQUIRED', 'IN_TRANSIT', 'ARRIVED'] } } } }] }, select: { id: true } });
    const offer = isOnline && await tx.deliveryOffer.findFirst({ where: { courierId, status: 'PENDING', expiresAt: { gt: now }, order: { adminDeletedAt: null } }, select: { id: true } });
    const presenceStatus = !isOnline ? 'OFFLINE' : delivery ? 'DELIVERING' : offer ? 'OFFERED' : 'AVAILABLE';
    const updated = await tx.courierProfile.update({ where: { id: courierId }, data: {
      isOnline, presenceStatus, availableSince: presenceStatus === 'AVAILABLE' ? profile.availableSince ?? now : null,
      ...(device ? { lastHeartbeatAt: device.lastHeartbeatAt } : {}),
    } });
    return { ...updated, userId: profile.userId, closed, changed: profile.isOnline !== isOnline || profile.presenceStatus !== presenceStatus };
  });
}
