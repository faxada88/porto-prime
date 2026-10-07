import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { RealtimeGateway } from '../realtime/realtime.gateway.js';

@Injectable()
export class WalletService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly realtime: RealtimeGateway,
  ) {}

  private async courierForUser(userId: string) {
    const courier = await this.prisma.courierProfile.findUnique({
      where: { userId },
      include: { user: true },
    });
    if (!courier) throw new NotFoundException('Perfil de motoboy não encontrado');
    return courier;
  }

  private async authenticatedCourier(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== 'COURIER') {
      throw new ForbiddenException('Acesso exclusivo de motoboy');
    }
    return this.courierForUser(user.id);
  }

  private async availableBalance(courierId: string, tx?: any) {
    const client = tx ?? this.prisma;
    const aggregate = await client.courierLedgerEntry.aggregate({
      where: {
        courierId,
        availableAt: { lte: new Date() },
      },
      _sum: { amount: true },
    });
    return Number(aggregate._sum.amount ?? 0);
  }

  async creditDeliveryTx(
    tx: any,
    order: {
      id: string;
      courierId: string | null;
      deliveryFee: unknown;
    },
  ) {
    if (!order.courierId) {
      throw new BadRequestException('Pedido sem motoboy responsável');
    }

    const cfg = await tx.deliveryPricingConfig.upsert({
      where: { id: 'default' },
      create: { id: 'default' },
      update: {},
      select: { platformCommissionPercent: true },
    });

    const gross = Number(order.deliveryFee);
    const commissionPercent = Number(cfg.platformCommissionPercent ?? 0);
    const net = Math.max(
      0,
      gross * (1 - commissionPercent / 100),
    );
    const idempotencyKey = `delivery:${order.id}:credit`;

    const existing = await tx.courierLedgerEntry.findUnique({
      where: { idempotencyKey },
    });
    if (existing) return existing;

    const entry = await tx.courierLedgerEntry.upsert({
      where: { idempotencyKey },
      create: {
        courierId: order.courierId,
        orderId: order.id,
        type: 'DELIVERY_CREDIT',
        amount: Number(net.toFixed(2)),
        description: `Entrega #${order.id.slice(-8).toUpperCase()}`,
        idempotencyKey,
        metadata: {
          deliveryFeeGross: Number(gross.toFixed(2)),
          platformCommissionPercent: commissionPercent,
          courierCredit: Number(net.toFixed(2)),
        },
      },
      update: {},
    });

    const existingEvent = await tx.dispatchEvent.findFirst({
      where: {
        orderId: order.id,
        courierId: order.courierId,
        type: 'WALLET_CREDITED',
      },
      select: { id: true },
    });

    if (!existingEvent) {
      await tx.dispatchEvent.create({
        data: {
          orderId: order.id,
          courierId: order.courierId,
          type: 'WALLET_CREDITED',
          payload: {
            deliveryFee: Number(gross.toFixed(2)),
            credited: Number(net.toFixed(2)),
            idempotencyKey,
          },
        },
      });
    }

    return entry;
  }

  async notifyWallet(courierId: string) {
    const courier = await this.prisma.courierProfile.findUnique({
      where: { id: courierId },
      select: { userId: true },
    });
    if (!courier) return;
    this.realtime.emitToUser(courier.userId, 'wallet.updated', {
      at: new Date().toISOString(),
    });
    this.realtime.emitToRole('ADMIN', 'wallet.updated', {
      courierId,
      at: new Date().toISOString(),
    });
  }

  async summary(authorization?: string) {
    const courier = await this.authenticatedCourier(authorization);
    const now = new Date();
    const startToday = new Date(now);
    startToday.setHours(0, 0, 0, 0);
    const weekStart = new Date(startToday);
    weekStart.setDate(
      weekStart.getDate() - ((weekStart.getDay() + 6) % 7),
    );

    const [
      available,
      pendingWithdrawals,
      todayCredits,
      weekCredits,
      todayDeliveries,
      weekDeliveries,
      latest,
    ] = await Promise.all([
      this.availableBalance(courier.id),
      this.prisma.withdrawal.aggregate({
        where: {
          courierId: courier.id,
          status: { in: ['PENDING', 'PROCESSING'] },
        },
        _sum: { amount: true },
      }),
      this.prisma.courierLedgerEntry.aggregate({
        where: {
          courierId: courier.id,
          type: 'DELIVERY_CREDIT',
          createdAt: { gte: startToday },
        },
        _sum: { amount: true },
      }),
      this.prisma.courierLedgerEntry.aggregate({
        where: {
          courierId: courier.id,
          type: 'DELIVERY_CREDIT',
          createdAt: { gte: weekStart },
        },
        _sum: { amount: true },
      }),
      this.prisma.order.count({
        where: {
          courierId: courier.id,
          status: 'DELIVERED',
          deliveredAt: { gte: startToday },
        },
      }),
      this.prisma.order.count({
        where: {
          courierId: courier.id,
          status: 'DELIVERED',
          deliveredAt: { gte: weekStart },
        },
      }),
      this.prisma.courierLedgerEntry.findMany({
        where: { courierId: courier.id },
        orderBy: { createdAt: 'desc' },
        take: 8,
      }),
    ]);

    const pending = Number(pendingWithdrawals._sum.amount ?? 0);
    return {
      availableBalance: Number(available.toFixed(2)),
      totalBalance: Number((available + pending).toFixed(2)),
      pendingWithdrawals: Number(pending.toFixed(2)),
      earningsToday: Number(
        Number(todayCredits._sum.amount ?? 0).toFixed(2),
      ),
      earningsWeek: Number(
        Number(weekCredits._sum.amount ?? 0).toFixed(2),
      ),
      deliveriesToday: todayDeliveries,
      deliveriesWeek: weekDeliveries,
      recentEntries: latest,
    };
  }

  async ledger(authorization?: string, take = 100) {
    const courier = await this.authenticatedCourier(authorization);
    return this.prisma.courierLedgerEntry.findMany({
      where: { courierId: courier.id },
      orderBy: { createdAt: 'desc' },
      take: Math.min(Math.max(take, 1), 200),
    });
  }

  async withdrawals(authorization?: string) {
    const courier = await this.authenticatedCourier(authorization);
    return this.prisma.withdrawal.findMany({
      where: { courierId: courier.id },
      orderBy: { requestedAt: 'desc' },
    });
  }

  async requestWithdrawal(
    amountRaw: number,
    authorization?: string,
  ) {
    const courier = await this.authenticatedCourier(authorization);
    const amount = Number(amountRaw);
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new BadRequestException('Valor de saque inválido');
    }
    if (!courier.pixKey || !courier.pixKeyType) {
      throw new BadRequestException(
        'Cadastre uma chave PIX antes de solicitar saque',
      );
    }

    const pixKey = courier.pixKey;
    const pixKeyType = courier.pixKeyType;
    const withdrawalId = randomUUID();

    const withdrawal = await this.prisma.$transaction(async (tx) => {
      await (tx as any).$queryRawUnsafe(
        'SELECT "id" FROM "CourierProfile" WHERE "id" = $1 FOR UPDATE',
        courier.id,
      );

      const available = await this.availableBalance(courier.id, tx);
      if (amount > available + 0.0001) {
        throw new BadRequestException('Saldo disponível insuficiente');
      }

      const row = await tx.withdrawal.create({
        data: {
          id: withdrawalId,
          courierId: courier.id,
          amount: Number(amount.toFixed(2)),
          status: 'PENDING',
          pixKeyType,
          pixKey,
        },
      });

      await tx.courierLedgerEntry.create({
        data: {
          courierId: courier.id,
          type: 'WITHDRAWAL_DEBIT',
          amount: -Number(amount.toFixed(2)),
          description: 'Reserva para saque solicitado',
          idempotencyKey: `withdrawal:${withdrawalId}:reserve`,
          metadata: {
            withdrawalId,
            status: 'PENDING',
          },
        },
      });

      // Eventos de saque não têm pedido; a auditoria financeira permanece
      // no ledger e na própria entidade Withdrawal.
      return row;
    });

    await this.notifyWallet(courier.id);
    return withdrawal;
  }

  async adminWithdrawals(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== 'ADMIN') {
      throw new ForbiddenException('Acesso exclusivo de administrador');
    }

    return this.prisma.withdrawal.findMany({
      include: {
        courier: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
                phone: true,
              },
            },
          },
        },
      },
      orderBy: { requestedAt: 'desc' },
      take: 500,
    });
  }

  async updateWithdrawalStatus(
    id: string,
    status: string,
    authorization?: string,
  ) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== 'ADMIN') {
      throw new ForbiddenException('Acesso exclusivo de administrador');
    }

    if (!['PROCESSING', 'PAID', 'REJECTED'].includes(status)) {
      throw new BadRequestException('Status de saque inválido');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const current = await tx.withdrawal.findUnique({
        where: { id },
      });
      if (!current) throw new NotFoundException('Saque não encontrado');

      if (['PAID', 'REJECTED', 'CANCELED'].includes(current.status)) {
        if (current.status === status) return current;
        throw new ConflictException('Este saque já foi encerrado');
      }

      const row = await tx.withdrawal.update({
        where: { id },
        data: {
          status: status as any,
          processedAt:
            status === 'PAID' || status === 'REJECTED'
              ? new Date()
              : null,
        },
      });

      if (status === 'REJECTED') {
        const key = `withdrawal:${id}:reversal`;
        const existing = await tx.courierLedgerEntry.findUnique({
          where: { idempotencyKey: key },
        });

        if (!existing) {
          await tx.courierLedgerEntry.create({
            data: {
              courierId: current.courierId,
              type: 'REVERSAL',
              amount: current.amount,
              description: 'Estorno de saque rejeitado',
              idempotencyKey: key,
              metadata: {
                withdrawalId: id,
                reason: 'REJECTED',
              },
            },
          });
        }
      }

      return row;
    });

    await this.notifyWallet(updated.courierId);
    return updated;
  }
}
