import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CourierStatus, OrderStatus, PaymentStatus, UserRole, UserStatus } from '../generated/prisma/client.js';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
  ) {}

  private async requireAdmin(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Acesso exclusivo do administrador');
    }
    return user;
  }

  async pending(authorization?: string) {
    await this.requireAdmin(authorization);
    return this.prisma.user.findMany({
      where: {
        status: UserStatus.PENDING,
        role: { in: [UserRole.COURIER, UserRole.PARTNER] },
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        status: true,
        courierProfile: true,
        partnerProfile: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async approve(userId: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { courierProfile: true, partnerProfile: true },
    });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    return this.prisma.$transaction(async (tx) => {
      if (user.role === UserRole.COURIER && user.courierProfile) {
        await tx.courierProfile.update({
          where: { id: user.courierProfile.id },
          data: { approvalStatus: CourierStatus.APPROVED },
        });
      } else if (user.role === UserRole.PARTNER && user.partnerProfile) {
        await tx.partnerProfile.update({
          where: { id: user.partnerProfile.id },
          data: { approved: true },
        });
      } else {
        throw new ForbiddenException('Perfil não requer aprovação');
      }

      return tx.user.update({
        where: { id: userId },
        data: { status: UserStatus.ACTIVE },
        select: { id: true, name: true, email: true, role: true, status: true },
      });
    });
  }

  async reject(userId: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { courierProfile: true, partnerProfile: true },
    });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    if (user.role === UserRole.COURIER && user.courierProfile) {
      await this.prisma.courierProfile.update({
        where: { id: user.courierProfile.id },
        data: { approvalStatus: CourierStatus.REJECTED, isOnline: false },
      });
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: { status: UserStatus.BLOCKED },
      select: { id: true, name: true, email: true, role: true, status: true },
    });
  }
  async orders(authorization?: string) {
    await this.requireAdmin(authorization);
    return this.prisma.order.findMany({
      where: { paymentStatus: PaymentStatus.PAID },
      include: {
        items: true,
        address: true,
        customer: { select: { id: true, name: true, phone: true } },
        courier: { include: { user: { select: { name: true, phone: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async releaseOrder(orderId: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Pedido não encontrado');
    if (order.paymentStatus !== PaymentStatus.PAID) {
      throw new ForbiddenException('O pedido precisa estar pago antes da liberação');
    }
    if (order.status !== OrderStatus.CONFIRMED && order.status !== OrderStatus.PREPARING) {
      throw new ForbiddenException('Pedido não está aguardando liberação');
    }

    const courier = await this.prisma.courierProfile.findFirst({
      where: {
        isOnline: true,
        approvalStatus: CourierStatus.APPROVED,
        user: { status: UserStatus.ACTIVE },
      },
      orderBy: { updatedAt: 'asc' },
    });

    if (!courier) {
      await this.prisma.order.update({
        where: { id: orderId },
        data: { status: OrderStatus.READY_FOR_PICKUP },
      });
      return { assigned: false, status: OrderStatus.READY_FOR_PICKUP, message: 'Pedido liberado. Aguardando motoboy disponível.' };
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      await tx.courierProfile.update({ where: { id: courier.id }, data: { isOnline: false } });
      return tx.order.update({
        where: { id: orderId },
        data: { courierId: courier.id, status: OrderStatus.COURIER_ASSIGNED },
        include: { courier: { include: { user: { select: { name: true, phone: true } } } } },
      });
    });
    return { assigned: true, order: updated };
  }
}
