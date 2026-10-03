import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { OrderStatus, PaymentStatus, UserRole } from '../generated/prisma/client.js';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateOrderDto } from './dto/create-order.dto.js';

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService, private readonly auth: AuthService) {}

  async create(data: CreateOrderDto, authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Apenas clientes podem criar pedidos');

    const address = await this.prisma.address.findFirst({ where: { id: data.addressId, userId: user.id } });
    if (!address) throw new NotFoundException('Endereço não encontrado');

    const ids = [...new Set(data.items.map((item) => item.productId))];
    const products = await this.prisma.product.findMany({ where: { id: { in: ids }, active: true } });
    if (products.length !== ids.length) throw new BadRequestException('Um ou mais produtos estão indisponíveis');

    const byId = new Map(products.map((product) => [product.id, product]));
    let subtotal = 0;
    const items = data.items.map((item) => {
      const product = byId.get(item.productId)!;
      if (product.stock < item.quantity) throw new BadRequestException(`Estoque insuficiente para ${product.name}`);
      const unitPrice = Number(product.price);
      const total = unitPrice * item.quantity;
      subtotal += total;
      return { productId: product.id, productName: product.name, unitPrice, quantity: item.quantity, total };
    });

    const deliveryFee = 0;
    return this.prisma.order.create({
      data: {
        customerId: user.id,
        addressId: address.id,
        subtotal,
        deliveryFee,
        total: subtotal + deliveryFee,
        items: { create: items },
      },
      include: { items: true, address: true },
    });
  }

  async clearPending(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Acesso exclusivo de cliente');

    const pending = await this.prisma.order.findMany({
      where: {
        customerId: user.id,
        paymentStatus: { in: [PaymentStatus.PENDING, PaymentStatus.FAILED] },
        status: { in: [OrderStatus.PENDING, OrderStatus.CANCELED] },
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
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Acesso exclusivo de cliente');
    return this.prisma.order.findMany({
      where: { customerId: user.id },
      include: { items: true, address: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async active(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Acesso exclusivo de cliente');
    return this.prisma.order.findFirst({
      where: { customerId: user.id, status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELED] } },
      include: { items: true, address: true, courier: { include: { user: { select: { name: true, phone: true } } } } },
      orderBy: { createdAt: 'desc' },
    });
  }
}
