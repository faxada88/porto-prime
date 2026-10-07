import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service.js';
import { RealtimeGateway } from '../realtime/realtime.gateway.js';

type DispatchConfig = {
  offerTimeoutSeconds: number;
  heartbeatTimeoutSeconds: number;
  distributorName: string;
  distributorAddress: string | null;
  distributorLatitude: unknown;
  distributorLongitude: unknown;
};

@Injectable()
export class DispatchService implements OnModuleInit, OnModuleDestroy {
  private timer?: NodeJS.Timeout;
  private running = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeGateway,
  ) {}

  onModuleInit() {
    if (process.env.NODE_ENV === 'test') return;

    this.timer = setInterval(() => {
      void this.tick();
    }, 2_000);
    this.timer.unref?.();
    void this.tick();
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  private async config(): Promise<DispatchConfig> {
    return (this.prisma as any).deliveryPricingConfig.upsert({
      where: { id: 'default' },
      create: { id: 'default' },
      update: {},
      select: {
        offerTimeoutSeconds: true,
        heartbeatTimeoutSeconds: true,
        distributorName: true,
        distributorAddress: true,
        distributorLatitude: true,
        distributorLongitude: true,
      },
    });
  }

  private toNumber(value: unknown) {
    if (value === null || value === undefined) return null;
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
  }

  private haversineKm(
    aLat: number,
    aLng: number,
    bLat: number,
    bLng: number,
  ) {
    const rad = (v: number) => (v * Math.PI) / 180;
    const earth = 6371;
    const dLat = rad(bLat - aLat);
    const dLng = rad(bLng - aLng);
    const x =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(rad(aLat)) *
        Math.cos(rad(bLat)) *
        Math.sin(dLng / 2) ** 2;
    return 2 * earth * Math.asin(Math.sqrt(x));
  }

  private async tick() {
    if (this.running) return;
    this.running = true;
    try {
      await this.expireOffers();
      await this.markStaleCouriersOffline();

      const orders = await (this.prisma as any).order.findMany({
        where: {
          status: 'SEARCHING_COURIER',
          courierId: null,
          activeOfferId: null,
          paymentStatus: 'PAID',
        },
        select: { id: true },
        orderBy: { updatedAt: 'asc' },
        take: 30,
      });

      for (const order of orders) {
        await this.dispatchOrder(order.id);
      }
    } finally {
      this.running = false;
    }
  }

  async markStaleCouriersOffline() {
    const cfg = await this.config();
    const cutoff = new Date(
      Date.now() - Math.max(20, cfg.heartbeatTimeoutSeconds) * 1000,
    );

    await (this.prisma as any).courierDevicePresence.updateMany({
      where: {
        lastHeartbeatAt: { lt: cutoff },
        onlineRequested: true,
      },
      data: { onlineRequested: false },
    });

    const profiles = await (this.prisma as any).courierProfile.findMany({
      where: {
        presenceStatus: { in: ['AVAILABLE', 'OFFERED'] },
      },
      select: { id: true },
      take: 500,
    });

    for (const profile of profiles) {
      const onlineDevice = await (this.prisma as any)
        .courierDevicePresence.findFirst({
          where: {
            courierId: profile.id,
            onlineRequested: true,
            lastHeartbeatAt: { gte: cutoff },
          },
          select: { id: true },
        });

      if (onlineDevice) continue;

      await (this.prisma as any).courierProfile.updateMany({
        where: {
          id: profile.id,
          presenceStatus: { in: ['AVAILABLE', 'OFFERED'] },
        },
        data: {
          presenceStatus: 'OFFLINE',
          isOnline: false,
          availableSince: null,
        },
      });
    }
  }

  async startDispatch(orderId: string) {
    const order = await (this.prisma as any).order.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        customerId: true,
        courierId: true,
        paymentStatus: true,
        status: true,
        activeOfferId: true,
      },
    });

    if (!order) throw new NotFoundException('Pedido não encontrado');
    if (order.paymentStatus !== 'PAID') {
      throw new BadRequestException(
        'O pedido precisa estar pago antes do despacho',
      );
    }
    if (order.courierId) return order;

    const updated = await (this.prisma as any).$transaction(async (tx: any) => {
      const result = await tx.order.updateMany({
        where: {
          id: orderId,
          courierId: null,
          status: {
            in: ['CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'SEARCHING_COURIER'],
          },
        },
        data: {
          status: 'SEARCHING_COURIER',
        },
      });

      if (result.count === 0) {
        return tx.order.findUnique({ where: { id: orderId } });
      }

      await tx.dispatchEvent.create({
        data: {
          orderId,
          type: 'ADMIN_RELEASED',
        },
      });
      await tx.dispatchEvent.create({
        data: {
          orderId,
          type: 'SEARCH_STARTED',
        },
      });

      return tx.order.findUnique({ where: { id: orderId } });
    });

    this.realtime.emitOrderUpdated(updated);
    await this.dispatchOrder(orderId);
    return updated;
  }

  async dispatchOrder(orderId: string) {
    const cfg = await this.config();
    const heartbeatCutoff = new Date(
      Date.now() - Math.max(20, cfg.heartbeatTimeoutSeconds) * 1000,
    );
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const order = await (this.prisma as any).order.findUnique({
      where: { id: orderId },
      include: { address: true },
    });

    if (
      !order ||
      order.status !== 'SEARCHING_COURIER' ||
      order.courierId ||
      order.activeOfferId
    ) {
      return null;
    }

    const candidates = await (this.prisma as any).courierProfile.findMany({
      where: {
        approvalStatus: 'APPROVED',
        presenceStatus: 'AVAILABLE',
        lastHeartbeatAt: { gte: heartbeatCutoff },
        user: { status: 'ACTIVE' },
        deliveries: {
          none: {
            status: {
              notIn: ['DELIVERED', 'CANCELED'],
            },
          },
        },
        deliveryOffers: {
          none: { orderId },
        },
      },
      include: {
        user: { select: { id: true, name: true } },
        deliveryOffers: {
          where: { offeredAt: { gte: since } },
          select: { status: true },
        },
      },
      take: 100,
    });

    if (!candidates.length) return null;

    const pickupLat = this.toNumber(cfg.distributorLatitude);
    const pickupLng = this.toNumber(cfg.distributorLongitude);

    const ranked = candidates
      .map((courier: any) => {
        const lat = this.toNumber(courier.currentLatitude);
        const lng = this.toNumber(courier.currentLongitude);
        const locationFresh =
          courier.locationUpdatedAt &&
          new Date(courier.locationUpdatedAt).getTime() >=
            Date.now() - 5 * 60 * 1000;

        const distance =
          pickupLat !== null &&
          pickupLng !== null &&
          lat !== null &&
          lng !== null &&
          locationFresh
            ? this.haversineKm(lat, lng, pickupLat, pickupLng)
            : null;

        const accepted24h = courier.deliveryOffers.filter(
          (x: any) => x.status === 'ACCEPTED',
        ).length;
        const declined24h = courier.deliveryOffers.filter(
          (x: any) => x.status === 'DECLINED' || x.status === 'EXPIRED',
        ).length;
        const onlineMinutes = courier.availableSince
          ? Math.max(
              0,
              (Date.now() - new Date(courier.availableSince).getTime()) /
                60_000,
            )
          : 0;

        // Menor score vence. A arquitetura mantém os pesos isolados aqui
        // para troca futura do algoritmo sem mudar pedidos/ofertas.
        const score =
          (distance ?? 20) * 100 +
          accepted24h * 35 +
          declined24h * 8 -
          Math.min(onlineMinutes, 120) * 0.4;

        return {
          courier,
          distance,
          score,
        };
      })
      .sort((a: any, b: any) => a.score - b.score);

    for (const candidate of ranked) {
      const offerId = randomUUID();
      const expiresAt = new Date(
        Date.now() + Math.max(10, cfg.offerTimeoutSeconds) * 1000,
      );

      try {
        const offer = await (this.prisma as any).$transaction(
          async (tx: any) => {
            const courierClaim = await tx.courierProfile.updateMany({
              where: {
                id: candidate.courier.id,
                presenceStatus: 'AVAILABLE',
                lastHeartbeatAt: { gte: heartbeatCutoff },
              },
              data: {
                presenceStatus: 'OFFERED',
                lastOfferAt: new Date(),
              },
            });

            if (courierClaim.count !== 1) {
              throw new ConflictException('Motoboy não está mais disponível');
            }

            const orderClaim = await tx.order.updateMany({
              where: {
                id: orderId,
                status: 'SEARCHING_COURIER',
                courierId: null,
                activeOfferId: null,
              },
              data: { activeOfferId: offerId },
            });

            if (orderClaim.count !== 1) {
              throw new ConflictException('Pedido já possui oferta ativa');
            }

            const created = await tx.deliveryOffer.create({
              data: {
                id: offerId,
                orderId,
                courierId: candidate.courier.id,
                status: 'PENDING',
                score: candidate.score,
                expiresAt,
                distanceToPickupKm: candidate.distance,
                metadata: {
                  algorithm: 'balanced-v1',
                  accepted24h: candidate.courier.deliveryOffers.filter(
                    (x: any) => x.status === 'ACCEPTED',
                  ).length,
                  previousResponses24h:
                    candidate.courier.deliveryOffers.length,
                },
              },
              include: {
                order: {
                  include: {
                    address: true,
                    items: {
                      select: {
                        id: true,
                        productName: true,
                        quantity: true,
                      },
                    },
                  },
                },
                courier: {
                  include: {
                    user: { select: { id: true } },
                  },
                },
              },
            });

            await tx.dispatchEvent.create({
              data: {
                orderId,
                courierId: candidate.courier.id,
                offerId,
                type: 'OFFER_CREATED',
                payload: {
                  expiresAt: expiresAt.toISOString(),
                  score: candidate.score,
                  distanceToPickupKm: candidate.distance,
                },
              },
            });

            return created;
          },
        );

        const safePayload = this.safeOfferPayload(offer, cfg);
        this.realtime.emitToUser(
          offer.courier.user.id,
          'delivery.offer',
          safePayload,
        );
        this.realtime.emitToRole('ADMIN', 'dispatch.offer', {
          orderId,
          offerId,
          courierId: offer.courierId,
          expiresAt,
        });
        return safePayload;
      } catch {
        continue;
      }
    }

    return null;
  }

  private safeOfferPayload(offer: any, cfg: DispatchConfig) {
    return {
      offerId: offer.id,
      orderId: offer.orderId,
      status: offer.status,
      expiresAt: offer.expiresAt,
      deliveryFee: offer.order.deliveryFee,
      routeDistanceKm: offer.order.routeDistanceKm,
      routeDurationMinutes: offer.order.routeDurationMinutes,
      distanceToPickupKm: offer.distanceToPickupKm,
      pickup: {
        name: cfg.distributorName,
        region: cfg.distributorAddress || 'Base Porto Prime',
      },
      dropoff: {
        neighborhood: offer.order.address?.neighborhood ?? null,
        city: offer.order.address?.city ?? null,
      },
      itemCount: Array.isArray(offer.order.items)
        ? offer.order.items.reduce(
            (sum: number, item: any) => sum + Number(item.quantity || 0),
            0,
          )
        : 0,
    };
  }

  async currentOfferForCourier(courierId: string) {
    const cfg = await this.config();
    const offer = await (this.prisma as any).deliveryOffer.findFirst({
      where: {
        courierId,
        status: 'PENDING',
        expiresAt: { gt: new Date() },
      },
      include: {
        order: {
          include: {
            address: true,
            items: {
              select: {
                id: true,
                productName: true,
                quantity: true,
              },
            },
          },
        },
        courier: {
          include: {
            user: { select: { id: true } },
          },
        },
      },
      orderBy: { offeredAt: 'desc' },
    });

    return offer ? this.safeOfferPayload(offer, cfg) : null;
  }

  async acceptOffer(
    courierId: string,
    userId: string,
    orderId: string,
  ) {
    const now = new Date();

    const result = await (this.prisma as any).$transaction(
      async (tx: any) => {
        const offer = await tx.deliveryOffer.findFirst({
          where: {
            orderId,
            courierId,
            status: 'PENDING',
          },
        });

        if (!offer) {
          throw new ConflictException(
            'Esta oferta não está mais disponível',
          );
        }

        if (offer.expiresAt <= now) {
          await tx.deliveryOffer.updateMany({
            where: { id: offer.id, status: 'PENDING' },
            data: {
              status: 'EXPIRED',
              expiredAt: now,
              respondedAt: now,
            },
          });
          await tx.order.updateMany({
            where: { id: orderId, activeOfferId: offer.id },
            data: { activeOfferId: null },
          });
          throw new ConflictException('O tempo desta oferta terminou');
        }

        const accepted = await tx.deliveryOffer.updateMany({
          where: {
            id: offer.id,
            courierId,
            status: 'PENDING',
            expiresAt: { gt: now },
          },
          data: {
            status: 'ACCEPTED',
            acceptedAt: now,
            respondedAt: now,
          },
        });

        if (accepted.count !== 1) {
          throw new ConflictException('Oferta já respondida');
        }

        const claimed = await tx.order.updateMany({
          where: {
            id: orderId,
            status: 'SEARCHING_COURIER',
            courierId: null,
            activeOfferId: offer.id,
          },
          data: {
            courierId,
            status: 'COURIER_ASSIGNED',
            activeOfferId: null,
          },
        });

        if (claimed.count !== 1) {
          throw new ConflictException(
            'Esta entrega já foi atribuída',
          );
        }

        const otherOffers = await tx.deliveryOffer.findMany({
          where: {
            orderId,
            id: { not: offer.id },
            status: 'PENDING',
          },
          select: { id: true, courierId: true },
        });

        await tx.deliveryOffer.updateMany({
          where: {
            orderId,
            id: { not: offer.id },
            status: 'PENDING',
          },
          data: {
            status: 'CANCELED',
            canceledAt: now,
            respondedAt: now,
          },
        });

        await tx.courierProfile.update({
          where: { id: courierId },
          data: {
            presenceStatus: 'DELIVERING',
            isOnline: false,
            availableSince: null,
          },
        });

        const otherCourierIds = [
          ...new Set(
            otherOffers
              .map((x: any) => x.courierId)
              .filter((id: string) => id !== courierId),
          ),
        ];

        if (otherCourierIds.length) {
          await tx.courierProfile.updateMany({
            where: {
              id: { in: otherCourierIds },
              presenceStatus: 'OFFERED',
            },
            data: {
              presenceStatus: 'AVAILABLE',
              isOnline: true,
              availableSince: now,
            },
          });
        }

        await tx.dispatchEvent.create({
          data: {
            orderId,
            courierId,
            offerId: offer.id,
            type: 'OFFER_ACCEPTED',
          },
        });

        return tx.order.findUnique({
          where: { id: orderId },
          include: {
            items: true,
            address: true,
            customer: {
              select: { name: true, phone: true },
            },
          },
        });
      },
    );

    this.realtime.emitOrderUpdated(result);
    this.realtime.emitToUser(userId, 'delivery.accepted', {
      orderId,
      at: now.toISOString(),
    });
    return result;
  }

  async declineOffer(
    courierId: string,
    userId: string,
    orderId: string,
  ) {
    const now = new Date();
    const cfg = await this.config();
    const cutoff = new Date(
      Date.now() - Math.max(20, cfg.heartbeatTimeoutSeconds) * 1000,
    );

    const result = await (this.prisma as any).$transaction(
      async (tx: any) => {
        const offer = await tx.deliveryOffer.findFirst({
          where: {
            orderId,
            courierId,
            status: 'PENDING',
          },
        });
        if (!offer) {
          throw new ConflictException('Oferta já encerrada');
        }

        const changed = await tx.deliveryOffer.updateMany({
          where: { id: offer.id, status: 'PENDING' },
          data: {
            status: 'DECLINED',
            declinedAt: now,
            respondedAt: now,
          },
        });
        if (changed.count !== 1) {
          throw new ConflictException('Oferta já respondida');
        }

        await tx.order.updateMany({
          where: { id: orderId, activeOfferId: offer.id },
          data: { activeOfferId: null },
        });

        const courier = await tx.courierProfile.findUnique({
          where: { id: courierId },
          select: { lastHeartbeatAt: true },
        });
        const stillOnline =
          courier?.lastHeartbeatAt &&
          new Date(courier.lastHeartbeatAt) >= cutoff;

        await tx.courierProfile.update({
          where: { id: courierId },
          data: {
            presenceStatus: stillOnline ? 'AVAILABLE' : 'OFFLINE',
            isOnline: !!stillOnline,
            availableSince: stillOnline ? now : null,
          },
        });

        await tx.dispatchEvent.create({
          data: {
            orderId,
            courierId,
            offerId: offer.id,
            type: 'OFFER_DECLINED',
          },
        });

        return { success: true };
      },
    );

    this.realtime.emitToUser(userId, 'delivery.offer.closed', {
      orderId,
      reason: 'DECLINED',
    });
    this.realtime.emitToRole('ADMIN', 'dispatch.offer.closed', {
      orderId,
      courierId,
      reason: 'DECLINED',
    });
    setTimeout(() => void this.dispatchOrder(orderId), 0);
    return result;
  }

  private async expireOffers() {
    const cfg = await this.config();
    const heartbeatCutoff = new Date(
      Date.now() -
        Math.max(20, cfg.heartbeatTimeoutSeconds) * 1000,
    );

    const expired = await (this.prisma as any).deliveryOffer.findMany({
      where: {
        status: 'PENDING',
        expiresAt: { lte: new Date() },
      },
      include: {
        courier: {
          include: {
            user: { select: { id: true } },
          },
        },
      },
      take: 100,
    });

    for (const offer of expired) {
      const now = new Date();
      const changed = await (this.prisma as any).$transaction(
        async (tx: any) => {
          const updated = await tx.deliveryOffer.updateMany({
            where: {
              id: offer.id,
              status: 'PENDING',
              expiresAt: { lte: now },
            },
            data: {
              status: 'EXPIRED',
              expiredAt: now,
              respondedAt: now,
            },
          });

          if (updated.count !== 1) return false;

          await tx.order.updateMany({
            where: {
              id: offer.orderId,
              activeOfferId: offer.id,
            },
            data: { activeOfferId: null },
          });

          const onlineDevice = await tx.courierDevicePresence.findFirst({
            where: {
              courierId: offer.courierId,
              onlineRequested: true,
              lastHeartbeatAt: { gte: heartbeatCutoff },
            },
            select: { id: true },
          });

          const stillOnline = !!onlineDevice;

          await tx.courierProfile.update({
            where: { id: offer.courierId },
            data: {
              presenceStatus: stillOnline ? 'AVAILABLE' : 'OFFLINE',
              isOnline: stillOnline,
              availableSince: stillOnline ? now : null,
            },
          });

          await tx.dispatchEvent.create({
            data: {
              orderId: offer.orderId,
              courierId: offer.courierId,
              offerId: offer.id,
              type: 'OFFER_EXPIRED',
            },
          });

          return true;
        },
      );

      if (!changed) continue;

      this.realtime.emitToUser(
        offer.courier.user.id,
        'delivery.offer.closed',
        {
          orderId: offer.orderId,
          reason: 'EXPIRED',
        },
      );
      this.realtime.emitToRole('ADMIN', 'dispatch.offer.closed', {
        orderId: offer.orderId,
        courierId: offer.courierId,
        reason: 'EXPIRED',
      });

      setTimeout(() => void this.dispatchOrder(offer.orderId), 0);
    }
  }

  async audit(orderId: string) {
    return (this.prisma as any).dispatchEvent.findMany({
      where: { orderId },
      orderBy: { createdAt: 'asc' },
    });
  }
}
