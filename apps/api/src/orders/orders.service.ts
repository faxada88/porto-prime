import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { validateProfilePhoto } from '../couriers/profile-photo.js';
import { randomInt } from 'node:crypto';
import {
  CourierStatus,
  OrderStatus,
  PaymentStatus,
  UserRole,
  UserStatus,
} from '../generated/prisma/client.js';
import { AuthService } from '../auth/auth.service.js';
import { DeliveryPricingService } from '../delivery/delivery-pricing.service.js';
import { DispatchService } from '../dispatch/dispatch.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { RealtimeGateway } from '../realtime/realtime.gateway.js';
import { WalletService } from '../wallet/wallet.service.js';
import { CreateOrderDto } from './dto/create-order.dto.js';

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly pricing: DeliveryPricingService,
    private readonly dispatch: DispatchService,
    private readonly wallet: WalletService,
    private readonly realtime: RealtimeGateway,
  ) {}

  private newDeliveryPin() {
    return randomInt(1000, 10000).toString();
  }

  private withoutDeliverySecrets<T extends Record<string, any>>(order: T) {
    const {
      deliveryPin: _deliveryPin,
      deliveryPinAttempts: _deliveryPinAttempts,
      ...safe
    } = order;
    return safe;
  }

  private async ensureCustomerPin<T extends Record<string, any>>(order: T) {
    if (order.deliveryPin) return order;

    const generated = this.newDeliveryPin();
    await this.prisma.order.updateMany({
      where: { id: order.id, deliveryPin: null },
      data: { deliveryPin: generated },
    });

    const current = await this.prisma.order.findUnique({
      where: { id: order.id },
      select: { deliveryPin: true },
    });

    return {
      ...order,
      deliveryPin: current?.deliveryPin ?? generated,
    };
  }

  async create(data: CreateOrderDto, authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) {
      throw new ForbiddenException('Apenas clientes podem criar pedidos');
    }

    const address = await this.prisma.address.findFirst({
      where: { id: data.addressId, userId: user.id },
    });
    if (!address) throw new NotFoundException('Endereço não encontrado');

    const quote = await this.pricing.quoteForAddress(address);

    const ids = [...new Set(data.items.map((item) => item.productId))];
    const products = await this.prisma.product.findMany({
      where: { id: { in: ids }, active: true },
    });
    if (products.length !== ids.length) {
      throw new BadRequestException(
        'Um ou mais produtos estão indisponíveis',
      );
    }

    const byId = new Map(products.map((product) => [product.id, product]));
    let subtotal = 0;

    const items = data.items.map((item) => {
      const product = byId.get(item.productId)!;
      if (product.stock < item.quantity) {
        throw new BadRequestException(
          `Estoque insuficiente para ${product.name}`,
        );
      }

      const unitPrice = Number(product.price);
      const total = unitPrice * item.quantity;
      subtotal += total;

      return {
        productId: product.id,
        productName: product.name,
        unitPrice,
        quantity: item.quantity,
        total,
      };
    });

    const deliveryFee = quote.deliveryFee;

    const order = await this.prisma.order.create({
      data: {
        customerId: user.id,
        addressId: address.id,
        subtotal,
        deliveryFee,
        total: subtotal + deliveryFee,
        routeDistanceKm: quote.distanceKm,
        routeDurationMinutes: quote.durationMinutes,
        deliveryPin: this.newDeliveryPin(),
        items: { create: items },
      },
      include: { items: true, address: true },
    });

    this.realtime.emitToRole('ADMIN', 'order.created', {
      orderId: order.id,
      at: new Date().toISOString(),
    });

    return order;
  }

  async clearPending(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) {
      throw new ForbiddenException('Acesso exclusivo de cliente');
    }

    const pending = await this.prisma.order.findMany({
      where: {
        customerId: user.id,
        paymentStatus: {
          in: [PaymentStatus.PENDING, PaymentStatus.FAILED],
        },
      },
      select: { id: true },
    });

    if (pending.length === 0) return { deleted: 0 };

    const result = await this.prisma.order.deleteMany({
      where: {
        id: { in: pending.map((order) => order.id) },
        customerId: user.id,
      },
    });

    return { deleted: result.count };
  }

  private withCourierPhoto<T extends { courier?: any }>(order: T) {
    if (!order.courier) return order;
    const { onboardingData, ...courier } = order.courier;
    return { ...order, courier: { ...courier, profilePhoto: onboardingData?.profilePhoto ?? null } };
  }

  async mine(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) {
      throw new ForbiddenException('Acesso exclusivo de cliente');
    }

    const orders = await this.prisma.order.findMany({
      where: { customerId: user.id },
      include: {
        items: true,
        address: true,
        courier: {
          select: {
            id: true,
            vehicleBrand: true,
            vehicleModel: true,
            vehiclePlate: true,
            currentLatitude: true,
            currentLongitude: true,
            locationUpdatedAt: true,
            onboardingData: true,
            user: {
              select: { name: true, phone: true },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return Promise.all(orders.map((order) => this.ensureCustomerPin(this.withCourierPhoto(order))));
  }

  async active(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) {
      throw new ForbiddenException('Acesso exclusivo de cliente');
    }

    const order = await this.prisma.order.findFirst({
      where: {
        customerId: user.id,
        status: {
          notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELED],
        },
      },
      include: {
        items: true,
        address: true,
        courier: {
          select: {
            id: true,
            vehicleBrand: true,
            vehicleModel: true,
            vehiclePlate: true,
            currentLatitude: true,
            currentLongitude: true,
            locationUpdatedAt: true,
            onboardingData: true,
            user: {
              select: { name: true, phone: true },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return order ? this.ensureCustomerPin(this.withCourierPhoto(order)) : null;
  }

  private async courier(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.COURIER) {
      throw new ForbiddenException('Acesso exclusivo de motoboy');
    }

    const profile = await this.prisma.courierProfile.findUnique({
      where: { userId: user.id },
      include: { user: true },
    });

    if (
      !profile ||
      profile.approvalStatus !== CourierStatus.APPROVED ||
      user.status !== UserStatus.ACTIVE
    ) {
      throw new ForbiddenException(
        'Cadastro de motoboy ainda não está liberado',
      );
    }

    return { user, profile };
  }

  async courierPresence(authorization?: string) {
    const { profile } = await this.courier(authorization);
    return {
      isOnline: profile.isOnline,
      presenceStatus: (profile as any).presenceStatus ?? 'OFFLINE',
      lastHeartbeatAt: (profile as any).lastHeartbeatAt ?? null,
      availableSince: (profile as any).availableSince ?? null,
      locationUpdatedAt: (profile as any).locationUpdatedAt ?? null,
    };
  }

  async courierHeartbeat(
    body: {
      online?: boolean;
      latitude?: number;
      longitude?: number;
    },
    authorization?: string,
  ) {
    const session = await this.auth.authenticateSession(authorization);
    const user = session.user;
    if (user.role !== UserRole.COURIER) {
      throw new ForbiddenException('Acesso exclusivo de motoboy');
    }

    const profile = await this.prisma.courierProfile.findUnique({
      where: { userId: user.id },
    });
    if (
      !profile ||
      profile.approvalStatus !== CourierStatus.APPROVED ||
      user.status !== UserStatus.ACTIVE
    ) {
      throw new ForbiddenException(
        'Cadastro de motoboy ainda não está liberado',
      );
    }

    if (body.online === true && !(profile.onboardingData as any)?.profilePhoto) {
      throw new BadRequestException('Adicione sua foto de perfil antes de ficar online. Ela será mostrada ao cliente na entrega.');
    }

    if (body.online === true) validateProfilePhoto((profile.onboardingData as any)?.profilePhoto);

    const now = new Date();
    const latitude =
      body.latitude === undefined ? undefined : Number(body.latitude);
    const longitude =
      body.longitude === undefined ? undefined : Number(body.longitude);

    if (
      latitude !== undefined &&
      (!Number.isFinite(latitude) || latitude < -90 || latitude > 90)
    ) {
      throw new BadRequestException('Latitude inválida');
    }
    if (
      longitude !== undefined &&
      (!Number.isFinite(longitude) ||
        longitude < -180 ||
        longitude > 180)
    ) {
      throw new BadRequestException('Longitude inválida');
    }

    const onlineRequested =
      body.online ?? profile.isOnline;

    if (body.online !== undefined) {
      await (this.prisma as any).courierDevicePresence.updateMany({
        where: { courierId: profile.id }, data: { onlineRequested: body.online },
      });
    }

    await (this.prisma as any).courierDevicePresence.upsert({
      where: { sessionId: session.id },
      create: {
        courierId: profile.id,
        sessionId: session.id,
        onlineRequested,
        lastHeartbeatAt: now,
        ...(latitude !== undefined && longitude !== undefined
          ? { latitude, longitude }
          : {}),
      },
      update: {
        onlineRequested,
        lastHeartbeatAt: now,
        ...(latitude !== undefined && longitude !== undefined
          ? { latitude, longitude }
          : {}),
      },
    });

    const cfg = await (this.prisma as any).deliveryPricingConfig.upsert({
      where: { id: 'default' },
      create: { id: 'default' },
      update: {},
      select: { heartbeatTimeoutSeconds: true },
    });
    const cutoff = new Date(
      Date.now() -
        Math.max(20, Number(cfg.heartbeatTimeoutSeconds || 45)) * 1000,
    );

    const [activeDelivery, pendingOffer, locationDevice, activeDeviceCount] =
      await Promise.all([
        this.prisma.order.findFirst({
          where: {
            courierId: profile.id,
            status: {
              notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELED],
            },
          },
          select: { id: true },
        }),
        (this.prisma as any).deliveryOffer.findFirst({
          where: {
            courierId: profile.id,
            status: 'PENDING',
            expiresAt: { gt: now },
          },
          select: { id: true },
        }),
        (this.prisma as any).courierDevicePresence.findFirst({
          where: {
            courierId: profile.id,
            lastHeartbeatAt: { gte: cutoff },
            latitude: { not: null },
            longitude: { not: null },
          },
          orderBy: { lastHeartbeatAt: 'desc' },
          select: {
            latitude: true,
            longitude: true,
            lastHeartbeatAt: true,
          },
        }),
        (this.prisma as any).courierDevicePresence.count({
          where: {
            courierId: profile.id,
            onlineRequested: true,
            lastHeartbeatAt: { gte: cutoff },
          },
        }),
      ]);

    const hasOnlineDevice = body.online ?? profile.isOnline;
    const presenceStatus = activeDelivery
      ? 'DELIVERING'
      : pendingOffer
        ? 'OFFERED'
        : hasOnlineDevice
          ? 'AVAILABLE'
          : 'OFFLINE';

    const updated = await (this.prisma as any).courierProfile.update({
      where: { id: profile.id },
      data: {
        presenceStatus,
        ...(body.online !== undefined ? { isOnline: body.online } : {}),
        lastHeartbeatAt: hasOnlineDevice ? now : profile.lastHeartbeatAt,
        availableSince:
          presenceStatus === 'AVAILABLE'
            ? (profile as any).availableSince ?? now
            : null,
        ...(locationDevice
          ? {
              currentLatitude: locationDevice.latitude,
              currentLongitude: locationDevice.longitude,
              locationUpdatedAt: locationDevice.lastHeartbeatAt,
            }
          : {}),
      },
    });

    this.realtime.emitToRole('ADMIN', 'courier.presence', {
      courierId: profile.id,
      presenceStatus,
      at: now.toISOString(),
    });

    return {
      isOnline: updated.isOnline,
      presenceStatus: updated.presenceStatus,
      lastHeartbeatAt: updated.lastHeartbeatAt,
      availableSince: updated.availableSince,
      locationUpdatedAt: updated.locationUpdatedAt,
      activeDevices: activeDeviceCount,
    };
  }

  async courierOnline(
    online: boolean,
    authorization?: string,
  ) {
    return this.courierHeartbeat({ online }, authorization);
  }

  async courierAvailable(authorization?: string) {
    const { profile } = await this.courier(authorization);
    const offer = await this.dispatch.currentOfferForCourier(profile.id);
    return offer ? [offer] : [];
  }

  async courierHistory(authorization?: string) {
    const { profile } = await this.courier(authorization);
    return this.prisma.order.findMany({
      where: {
        courierId: profile.id,
        status: { in: [OrderStatus.DELIVERED, OrderStatus.CANCELED] },
      },
      include: {
        items: true,
        address: true,
        customer: { select: { name: true } },
      },
      orderBy: { updatedAt: 'desc' },
      take: 100,
    });
  }

  async courierCurrent(authorization?: string) {
    const { profile } = await this.courier(authorization);

    const order = await this.prisma.order.findFirst({
      where: {
        courierId: profile.id,
        status: {
          notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELED],
        },
      },
      include: {
        items: true,
        address: true,
        customer: {
          select: { name: true, phone: true },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return order ? this.withoutDeliverySecrets(order) : null;
  }

  async courierAccept(
    orderId: string,
    authorization?: string,
  ) {
    const { user, profile } = await this.courier(authorization);
    return this.dispatch.acceptOffer(profile.id, user.id, orderId);
  }

  async courierReject(
    orderId: string,
    authorization?: string,
  ) {
    const { user, profile } = await this.courier(authorization);
    return this.dispatch.declineOffer(profile.id, user.id, orderId);
  }

  async courierStatus(
    orderId: string,
    raw: string,
    pin: string | undefined,
    authorization?: string,
  ) {
    const { profile } = await this.courier(authorization);
    const status = raw as OrderStatus;

    const allowed: OrderStatus[] = [
      OrderStatus.PICKED_UP,
      OrderStatus.OUT_FOR_DELIVERY,
      OrderStatus.DELIVERED,
    ];
    if (!allowed.includes(status)) {
      throw new BadRequestException('Etapa de entrega inválida');
    }

    const order = await this.prisma.order.findFirst({
      where: { id: orderId, courierId: profile.id },
    });
    if (!order) throw new NotFoundException('Entrega não encontrada');

    const transitions: Record<string, OrderStatus[]> = {
      COURIER_ASSIGNED: [OrderStatus.PICKED_UP],
      PICKED_UP: [OrderStatus.OUT_FOR_DELIVERY],
      OUT_FOR_DELIVERY: [OrderStatus.DELIVERED],
    };

    if (!(transitions[order.status] ?? []).includes(status)) {
      throw new BadRequestException(
        'Conclua a etapa atual antes de avançar',
      );
    }

    if (status === OrderStatus.DELIVERED) {
      const informed = (pin ?? '').replace(/\D/g, '');
      if (informed.length !== 4) {
        throw new BadRequestException(
          'Informe o PIN de 4 dígitos fornecido pelo cliente',
        );
      }

      let expected = order.deliveryPin;
      if (!expected) {
        expected = this.newDeliveryPin();
        await this.prisma.order.update({
          where: { id: order.id },
          data: { deliveryPin: expected },
        });
      }

      if (informed !== expected) {
        await this.prisma.order.update({
          where: { id: order.id },
          data: {
            deliveryPinAttempts: { increment: 1 },
          },
        });
        throw new BadRequestException(
          'PIN incorreto. Confirme o código com o cliente e tente novamente',
        );
      }
    }

    const eventType =
      status === OrderStatus.PICKED_UP
        ? 'COURIER_PICKED_UP'
        : status === OrderStatus.OUT_FOR_DELIVERY
          ? 'OUT_FOR_DELIVERY'
          : 'DELIVERED';

    const updated = await this.prisma.$transaction(async (tx) => {
      const changed = await tx.order.updateMany({
        where: {
          id: orderId,
          courierId: profile.id,
          status: order.status,
        },
        data: {
          status,
          deliveredAt:
            status === OrderStatus.DELIVERED ? new Date() : undefined,
        },
      });

      if (changed.count !== 1) {
        throw new BadRequestException(
          'A etapa da entrega já foi atualizada em outro dispositivo',
        );
      }

      await (tx as any).dispatchEvent.create({
        data: {
          orderId,
          courierId: profile.id,
          type: eventType,
        },
      });

      if (status === OrderStatus.DELIVERED) {
        const freshOrder = await tx.order.findUnique({
          where: { id: orderId },
          select: {
            id: true,
            courierId: true,
            deliveryFee: true,
          },
        });

        if (!freshOrder) {
          throw new NotFoundException('Pedido não encontrado');
        }

        await this.wallet.creditDeliveryTx(tx, freshOrder);

        await (tx as any).courierProfile.update({
          where: { id: profile.id },
          data: {
            presenceStatus: profile.isOnline ? 'AVAILABLE' : 'OFFLINE',
            availableSince: profile.isOnline ? new Date() : null,
            lastHeartbeatAt: new Date(),
          },
        });
      } else {
        await (tx as any).courierProfile.update({
          where: { id: profile.id },
          data: {
            presenceStatus: 'DELIVERING',
            lastHeartbeatAt: new Date(),
          },
        });
      }

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
    });

    if (!updated) throw new NotFoundException('Entrega não encontrada');

    this.realtime.emitOrderUpdated(updated);
    if (status === OrderStatus.DELIVERED) {
      await this.wallet.notifyWallet(profile.id);
    }

    return this.withoutDeliverySecrets(updated);
  }
}
