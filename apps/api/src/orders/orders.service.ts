import { randomInt } from 'node:crypto';
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  CourierStatus,
  OrderStatus,
  PaymentStatus,
  UserRole,
  UserStatus,
} from '../generated/prisma/client.js';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateOrderDto } from './dto/create-order.dto.js';

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
  ) {}

  private newDeliveryPin() {
    return randomInt(1000, 10000).toString();
  }

  private withoutDeliveryPin<T extends Record<string, any>>(order: T) {
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

    const ids = [...new Set(data.items.map((item) => item.productId))];
    const products = await this.prisma.product.findMany({
      where: { id: { in: ids }, active: true },
    });
    if (products.length !== ids.length) {
      throw new BadRequestException('Um ou mais produtos estão indisponíveis');
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

    const deliveryFee = 5.9;

    return this.prisma.order.create({
      data: {
        customerId: user.id,
        addressId: address.id,
        subtotal,
        deliveryFee,
        total: subtotal + deliveryFee,
        deliveryPin: this.newDeliveryPin(),
        items: { create: items },
      },
      include: { items: true, address: true },
    });
  }

  async clearPending(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) {
      throw new ForbiddenException('Acesso exclusivo de cliente');
    }

    const pending = await this.prisma.order.findMany({
      where: {
        customerId: user.id,
        paymentStatus: { in: [PaymentStatus.PENDING, PaymentStatus.FAILED] },
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
          include: {
            user: { select: { name: true, phone: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return Promise.all(orders.map((order) => this.ensureCustomerPin(order)));
  }

  async active(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) {
      throw new ForbiddenException('Acesso exclusivo de cliente');
    }

    const order = await this.prisma.order.findFirst({
      where: {
        customerId: user.id,
        status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELED] },
      },
      include: {
        items: true,
        address: true,
        courier: {
          include: {
            user: { select: { name: true, phone: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return order ? this.ensureCustomerPin(order) : null;
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

    return profile;
  }

  async courierOnline(online: boolean, authorization?: string) {
    const courier = await this.courier(authorization);

    return this.prisma.courierProfile.update({
      where: { id: courier.id },
      data: { isOnline: !!online },
    });
  }

  async courierAvailable(authorization?: string) {
    const courier = await this.courier(authorization);
    if (!courier.isOnline) return [];

    const orders = await this.prisma.order.findMany({
      where: {
        status: OrderStatus.READY_FOR_PICKUP,
        courierId: null,
        paymentStatus: PaymentStatus.PAID,
      },
      include: {
        items: true,
        address: true,
        customer: { select: { name: true, phone: true } },
      },
      orderBy: { createdAt: 'asc' },
      take: 10,
    });

    return orders.map((order) => this.withoutDeliveryPin(order));
  }

  async courierCurrent(authorization?: string) {
    const courier = await this.courier(authorization);

    const order = await this.prisma.order.findFirst({
      where: {
        courierId: courier.id,
        status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELED] },
      },
      include: {
        items: true,
        address: true,
        customer: { select: { name: true, phone: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return order ? this.withoutDeliveryPin(order) : null;
  }

  async courierAccept(orderId: string, authorization?: string) {
    const courier = await this.courier(authorization);
    if (!courier.isOnline) {
      throw new BadRequestException('Fique online para aceitar entregas');
    }

    const current = await this.prisma.order.findFirst({
      where: {
        courierId: courier.id,
        status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELED] },
      },
      select: { id: true },
    });
    if (current) {
      throw new BadRequestException(
        'Finalize sua entrega atual antes de aceitar outra',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const claimed = await tx.order.updateMany({
        where: {
          id: orderId,
          status: OrderStatus.READY_FOR_PICKUP,
          courierId: null,
          paymentStatus: PaymentStatus.PAID,
        },
        data: {
          courierId: courier.id,
          status: OrderStatus.COURIER_ASSIGNED,
        },
      });

      if (claimed.count !== 1) {
        throw new BadRequestException(
          'Esta entrega já foi aceita por outro motoboy',
        );
      }

      await tx.courierProfile.update({
        where: { id: courier.id },
        data: { isOnline: false },
      });

      let order = await tx.order.findUnique({
        where: { id: orderId },
        include: {
          items: true,
          address: true,
          customer: { select: { name: true, phone: true } },
        },
      });

      if (!order) throw new NotFoundException('Entrega não encontrada');

      if (!order.deliveryPin) {
        order = await tx.order.update({
          where: { id: orderId },
          data: { deliveryPin: this.newDeliveryPin() },
          include: {
            items: true,
            address: true,
            customer: { select: { name: true, phone: true } },
          },
        });
      }

      return this.withoutDeliveryPin(order);
    });
  }

  async courierStatus(
    orderId: string,
    raw: string,
    pin: string | undefined,
    authorization?: string,
  ) {
    const courier = await this.courier(authorization);
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
      where: { id: orderId, courierId: courier.id },
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
          data: { deliveryPinAttempts: { increment: 1 } },
        });
        throw new BadRequestException(
          'PIN incorreto. Confirme o código com o cliente e tente novamente',
        );
      }
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.order.update({
        where: { id: orderId },
        data: {
          status,
          deliveredAt:
            status === OrderStatus.DELIVERED ? new Date() : undefined,
        },
        include: {
          items: true,
          address: true,
          customer: { select: { name: true, phone: true } },
        },
      });

      if (status === OrderStatus.DELIVERED) {
        await tx.courierProfile.update({
          where: { id: courier.id },
          data: { isOnline: true },
        });
      }

      return this.withoutDeliveryPin(updated);
    });
  }
}
