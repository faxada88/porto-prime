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

  async dashboard(authorization?: string) {
    await this.requireAdmin(authorization);
    const [users, products, orders, onlineCouriers, paid] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.product.count({ where: { active: true } }),
      this.prisma.order.count(),
      this.prisma.courierProfile.count({
        where: {
          isOnline: true,
          approvalStatus: CourierStatus.APPROVED,
          user: { status: UserStatus.ACTIVE },
        },
      }),
      this.prisma.order.aggregate({
        where: { paymentStatus: PaymentStatus.PAID },
        _sum: { total: true },
      }),
    ]);

    return {
      users,
      products,
      orders,
      onlineCouriers,
      revenue: Number(paid._sum.total ?? 0),
    };
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

  async couriers(authorization?: string) {
    await this.requireAdmin(authorization);
    return (this.prisma as any).courierProfile.findMany({
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            status: true,
          },
        },
        requirements: { orderBy: { requestedAt: 'desc' } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async orders(authorization?: string) {
    await this.requireAdmin(authorization);
    return this.prisma.order.findMany({
      include: {
        customer: {
          select: { id: true, name: true, email: true, phone: true },
        },
        courier: {
          include: {
            user: { select: { id: true, name: true, phone: true } },
          },
        },
        address: true,
        items: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async users(authorization?: string) {
    await this.requireAdmin(authorization);
    return this.prisma.user.findMany({
      include: {
        courierProfile: true,
        partnerProfile: true,
        _count: { select: { orders: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async catalog(authorization?: string) {
    await this.requireAdmin(authorization);
    return this.prisma.category.findMany({
      include: {
        products: { orderBy: { name: 'asc' } },
      },
      orderBy: [{ position: 'asc' }, { name: 'asc' }],
    });
  }

  async updateUserStatus(userId: string, status: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const allowed = ['ACTIVE', 'PENDING', 'SUSPENDED', 'BLOCKED'];
    if (!allowed.includes(status)) {
      throw new BadRequestException('Status de usuário inválido');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { courierProfile: true },
    });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    return this.prisma.$transaction(async (tx) => {
      if (user.courierProfile && status !== 'ACTIVE') {
        await tx.courierProfile.update({
          where: { id: user.courierProfile.id },
          data: { isOnline: false },
        });
      }
      return tx.user.update({
        where: { id: userId },
        data: { status: status as UserStatus },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          role: true,
          status: true,
        },
      });
    });
  }

  async deleteUser(userId: string, authorization?: string) {
    const admin = await this.requireAdmin(authorization);
    if (admin.id === userId) {
      throw new BadRequestException('O administrador não pode excluir a própria conta');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { courierProfile: true, _count: { select: { orders: true } } },
    });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    if (user.role === UserRole.CUSTOMER && user._count.orders > 0) {
      throw new BadRequestException('Cliente com histórico de pedidos não pode ser excluído');
    }

    if (user.courierProfile) {
      const activeDeliveries = await this.prisma.order.count({
        where: {
          courierId: user.courierProfile.id,
          status: { notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELED] },
        },
      });
      if (activeDeliveries > 0) {
        throw new BadRequestException('Motoboy possui entrega ativa e não pode ser excluído');
      }

      await this.prisma.order.updateMany({
        where: { courierId: user.courierProfile.id },
        data: { courierId: null },
      });
    }

    await this.prisma.user.delete({ where: { id: userId } });
    return { success: true };
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
        const open = await (tx as any).courierRequirement.count({
          where: {
            courierId: user.courierProfile.id,
            status: { not: 'RESOLVED' },
          },
        });
        if (open) {
          throw new BadRequestException('Resolva todas as pendências antes de aprovar');
        }
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
        data: {
          approvalStatus: CourierStatus.REJECTED,
          isOnline: false,
        },
      });
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: { status: UserStatus.BLOCKED },
      select: { id: true, name: true, email: true, role: true, status: true },
    });
  }

  async createRequirement(
    courierId: string,
    body: { title: string; description: string },
    authorization?: string,
  ) {
    await this.requireAdmin(authorization);
    if (!body.title?.trim() || !body.description?.trim()) {
      throw new BadRequestException('Título e descrição são obrigatórios');
    }

    const profile = await (this.prisma as any).courierProfile.findUnique({
      where: { id: courierId },
      include: { user: true },
    });
    if (!profile) throw new NotFoundException('Motoboy não encontrado');

    return this.prisma.$transaction(async (tx) => {
      const requirement = await (tx as any).courierRequirement.create({
        data: {
          courierId,
          title: body.title.trim(),
          description: body.description.trim(),
        },
      });

      await tx.courierProfile.update({
        where: { id: courierId },
        data: {
          approvalStatus: CourierStatus.PENDING,
          isOnline: false,
        },
      });

      await tx.user.update({
        where: { id: profile.userId },
        data: { status: UserStatus.PENDING },
      });

      return requirement;
    });
  }

  async resolveRequirement(id: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const requirement = await (this.prisma as any).courierRequirement.findUnique({
      where: { id },
    });
    if (!requirement) throw new NotFoundException('Pendência não encontrada');

    return (this.prisma as any).courierRequirement.update({
      where: { id },
      data: { status: 'RESOLVED', resolvedAt: new Date() },
    });
  }

  async updateOrderStatus(orderId: string, status: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const allowed = [
      'PENDING',
      'CONFIRMED',
      'PREPARING',
      'READY_FOR_PICKUP',
      'COURIER_ASSIGNED',
      'PICKED_UP',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
      'CANCELED',
    ];
    if (!allowed.includes(status)) {
      throw new BadRequestException('Status de pedido inválido');
    }

    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Pedido não encontrado');

    const data: any = { status: status as OrderStatus };
    if (status === 'DELIVERED') data.deliveredAt = new Date();
    if (status === 'CANCELED') data.canceledAt = new Date();

    return this.prisma.order.update({
      where: { id: orderId },
      data,
      include: {
        customer: { select: { id: true, name: true, phone: true } },
        courier: { include: { user: { select: { name: true, phone: true } } } },
        address: true,
        items: true,
      },
    });
  }

  async assignCourier(orderId: string, courierId: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const [order, courier] = await Promise.all([
      this.prisma.order.findUnique({ where: { id: orderId } }),
      this.prisma.courierProfile.findUnique({
        where: { id: courierId },
        include: { user: true },
      }),
    ]);
    if (!order) throw new NotFoundException('Pedido não encontrado');
    if (!courier) throw new NotFoundException('Motoboy não encontrado');
    if (
      courier.approvalStatus !== CourierStatus.APPROVED ||
      courier.user.status !== UserStatus.ACTIVE
    ) {
      throw new BadRequestException('Motoboy não está aprovado e ativo');
    }

    return this.prisma.order.update({
      where: { id: orderId },
      data: {
        courierId,
        status: OrderStatus.COURIER_ASSIGNED,
      },
      include: {
        courier: { include: { user: { select: { name: true, phone: true } } } },
      },
    });
  }

  async releaseOrder(orderId: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Pedido não encontrado');
    if (order.paymentStatus !== PaymentStatus.PAID) {
      throw new BadRequestException('O pedido precisa estar pago antes de ser liberado');
    }

    if (order.courierId) {
      return this.prisma.order.update({
        where: { id: orderId },
        data: { status: OrderStatus.COURIER_ASSIGNED },
      });
    }

    const courier = await this.prisma.courierProfile.findFirst({
      where: {
        approvalStatus: CourierStatus.APPROVED,
        isOnline: true,
        user: { status: UserStatus.ACTIVE },
      },
      orderBy: { updatedAt: 'asc' },
    });
    if (!courier) {
      throw new BadRequestException('Nenhum motoboy disponível no momento');
    }

    return this.prisma.order.update({
      where: { id: orderId },
      data: {
        courierId: courier.id,
        status: OrderStatus.COURIER_ASSIGNED,
      },
      include: {
        courier: { include: { user: { select: { name: true, phone: true } } } },
      },
    });
  }

  async deleteOrder(orderId: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, status: true },
    });
    if (!order) throw new NotFoundException('Pedido não encontrado');
    if (order.status === OrderStatus.PICKED_UP || order.status === OrderStatus.OUT_FOR_DELIVERY) {
      throw new BadRequestException('Pedido em entrega não pode ser excluído');
    }

    await this.prisma.courierLedgerEntry.deleteMany({ where: { orderId } });
    await this.prisma.order.delete({ where: { id: orderId } });
    return { success: true };
  }

  async createProduct(
    body: {
      categoryId: string;
      name: string;
      description?: string;
      price: number;
      stock?: number;
    },
    authorization?: string,
  ) {
    await this.requireAdmin(authorization);
    const name = body.name?.trim();
    const price = Number(body.price);
    const stock = Number(body.stock ?? 0);
    if (!body.categoryId || !name || !Number.isFinite(price) || price < 0) {
      throw new BadRequestException('Categoria, nome e preço válido são obrigatórios');
    }
    if (!Number.isInteger(stock) || stock < 0) {
      throw new BadRequestException('Estoque inválido');
    }

    const category = await this.prisma.category.findUnique({
      where: { id: body.categoryId },
      select: { id: true },
    });
    if (!category) throw new NotFoundException('Categoria não encontrada');

    return this.prisma.product.create({
      data: {
        categoryId: body.categoryId,
        name,
        description: body.description?.trim() || null,
        price,
        stock,
        active: true,
      },
      include: { category: true },
    });
  }

  async updateProduct(
    productId: string,
    body: { stock?: number; active?: boolean },
    authorization?: string,
  ) {
    await this.requireAdmin(authorization);
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      select: { id: true },
    });
    if (!product) throw new NotFoundException('Produto não encontrado');

    const data: { stock?: number; active?: boolean } = {};
    if (body.stock !== undefined) {
      const stock = Number(body.stock);
      if (!Number.isInteger(stock) || stock < 0) {
        throw new BadRequestException('Estoque inválido');
      }
      data.stock = stock;
    }
    if (body.active !== undefined) data.active = Boolean(body.active);

    return this.prisma.product.update({
      where: { id: productId },
      data,
    });
  }

  async createCategory(body: { name: string }, authorization?: string) {
    await this.requireAdmin(authorization);
    const name = body.name?.trim();
    if (!name) throw new BadRequestException('Nome da categoria é obrigatório');

    const slug = name
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');

    if (!slug) throw new BadRequestException('Nome da categoria é inválido');

    const exists = await this.prisma.category.findFirst({
      where: { OR: [{ name }, { slug }] },
      select: { id: true },
    });
    if (exists) throw new BadRequestException('Categoria já cadastrada');

    return this.prisma.category.create({
      data: { name, slug, active: true },
    });
  }
}
