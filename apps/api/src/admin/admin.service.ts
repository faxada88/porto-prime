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
import { DispatchService } from '../dispatch/dispatch.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { validateProfilePhoto } from '../couriers/profile-photo.js';
import { normalizePix } from '../wallet/pix-key.js';
import { RealtimeGateway } from '../realtime/realtime.gateway.js';
import { WalletService } from '../wallet/wallet.service.js';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly dispatch: DispatchService,
    private readonly wallet: WalletService,
    private readonly realtime: RealtimeGateway,
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
      (this.prisma as any).courierProfile.count({
        where: {
          presenceStatus: { in: ['AVAILABLE', 'OFFERED', 'DELIVERING'] },
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

  async couriers(authorization?: string, onlyPending=false) {
    await this.requireAdmin(authorization);
    return (this.prisma as any).courierProfile.findMany({
      ...(onlyPending?{where:{OR:[{approvalStatus:CourierStatus.PENDING},{user:{is:{status:UserStatus.PENDING}}}]}}:{}),
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

  async courierDirectory(query: {q?:string;page?:string;size?:string;status?:string;online?:string}, authorization?: string) {
    await this.requireAdmin(authorization);
    const page=Number(query.page||1), size=Number(query.size||25), q=String(query.q||'').trim();
    if(!Number.isInteger(page)||page<1||page>100000||![25,50,100].includes(size)||q.length>100)throw new BadRequestException('Filtros de pesquisa inválidos');
    const status=query.status||'ALL', online=query.online||'ALL';
    if(!['ALL',...Object.values(UserStatus)].includes(status)||!['ALL','ONLINE','OFFLINE'].includes(online))throw new BadRequestException('Status de pesquisa inválido');
    const and:any[]=[];
    if(status!=='ALL')and.push({user:{is:{status}}});
    if(online!=='ALL')and.push({isOnline:online==='ONLINE'});
    if(q){const digits=q.replace(/\D/g,'');const or:any[]=[{document:{contains:q}},{vehiclePlate:{contains:q,mode:'insensitive'}},{user:{is:{OR:['name','email','phone'].map(k=>({[k]:{contains:q,mode:'insensitive'}}))}}}];if(digits.length>=3)or.push({document:{contains:digits}},{user:{is:{phone:{contains:digits}}}});and.push({OR:or});}
    const where=and.length?{AND:and}:{};
    const count=await this.prisma.courierProfile.count({where});
    const totalPages=Math.max(1,Math.ceil(count/size)), currentPage=Math.min(page,totalPages);
    const [rows,total,onlineCount,pendingCount]=await Promise.all([
      this.prisma.courierProfile.findMany({where,skip:(currentPage-1)*size,take:size,orderBy:[{createdAt:'desc'},{id:'desc'}],select:{id:true,userId:true,document:true,approvalStatus:true,isOnline:true,vehicleBrand:true,vehicleModel:true,vehiclePlate:true,createdAt:true,updatedAt:true,user:{select:{id:true,name:true,email:true,phone:true,status:true,createdAt:true}},_count:{select:{requirements:{where:{status:{not:'RESOLVED'}}}}}}}),
      this.prisma.courierProfile.count(),this.prisma.courierProfile.count({where:{isOnline:true}}),this.prisma.courierProfile.count({where:{approvalStatus:CourierStatus.PENDING}}),
    ]);
    return {rows,totalMatches:count,page:currentPage,size,totalPages,summary:{total,online:onlineCount,offline:total-onlineCount,pending:pendingCount}};
  }

  async courierRecord(id: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const row=await this.prisma.courierProfile.findUnique({where:{id},include:{user:{select:{id:true,name:true,email:true,phone:true,status:true,role:true,createdAt:true}},requirements:{orderBy:{requestedAt:'desc'}}}});
    if(!row)throw new NotFoundException('Motoboy não encontrado');
    return row;
  }

  async courierFinance(id: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const profile = await this.prisma.courierProfile.findUnique({ where: { id } });
    if (!profile) throw new NotFoundException('Motoboy não encontrado');
    const [credits, available, deliveries, withdrawals] = await Promise.all([
      this.prisma.courierLedgerEntry.aggregate({ where: { courierId: id, type: 'DELIVERY_CREDIT' }, _sum: { amount: true } }),
      this.prisma.courierLedgerEntry.aggregate({ where: { courierId: id, availableAt: { lte: new Date() } }, _sum: { amount: true } }),
      this.prisma.order.count({ where: { courierId: id, status: 'DELIVERED' } }),
      this.prisma.withdrawal.findMany({ where: { courierId: id }, orderBy: { requestedAt: 'desc' } }),
    ]);
    const paid = withdrawals.filter(w => w.status === 'PAID');
    return { earningsTotal: Number(credits._sum.amount || 0), availableBalance: Number(available._sum.amount || 0), deliveries, paidWithdrawalCount: paid.length, paidWithdrawalTotal: paid.reduce((sum, w) => sum + Number(w.amount), 0), pendingWithdrawalTotal: withdrawals.filter(w => ['PENDING','PROCESSING'].includes(w.status)).reduce((sum,w) => sum + Number(w.amount),0), withdrawals };
  }

  async editCourier(id: string, body: Record<string, unknown>, authorization?: string) {
    await this.requireAdmin(authorization);
    const allowed = ['name','email','phone','birthDate','cnh','cnhCategory','cnhExpiry','vehicleType','vehicleBrand','vehicleModel','vehicleYear','vehiclePlate','postalCode','cep','street','number','complement','neighborhood','city','state','pixKey','pixKeyType','cpf','document','hasMotorcycle','profilePhoto','extraData'];
    if (Object.keys(body).some(k => !allowed.includes(k))) throw new BadRequestException('Campo não permitido para edição');
    const input: Record<string, any> = {};
    for (const [key,value] of Object.entries(body)) {
      if(key==='extraData'){if(!value||typeof value!=='object'||Array.isArray(value)||JSON.stringify(value).length>20000)throw new BadRequestException('Dados adicionais inválidos');input[key]=value;continue;}
      if(key==='profilePhoto'){input[key]=validateProfilePhoto(value);continue;}
      if(key==='hasMotorcycle'){if(typeof value!=='boolean')throw new BadRequestException('Informe se possui moto');input[key]=value;continue;}
      if (typeof value !== 'string' && typeof value !== 'number') throw new BadRequestException('Dados de cadastro inválidos');
      input[key] = String(value).trim();
      if (input[key].length > 250) throw new BadRequestException('Campo muito longo');
    }
    if ('name' in input && input.name.length < 2) throw new BadRequestException('Informe o nome completo');
    if ('email' in input) { input.email = input.email.toLowerCase(); if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(input.email)) throw new BadRequestException('E-mail inválido'); }
    if ('phone' in input && !/^\+?[\d ()-]{10,20}$/.test(input.phone)) throw new BadRequestException('Telefone inválido');
    if ('vehicleYear' in input && input.vehicleYear && (!/^\d{4}$/.test(input.vehicleYear) || Number(input.vehicleYear) < 1950 || Number(input.vehicleYear) > new Date().getFullYear()+1)) throw new BadRequestException('Ano do veículo inválido');
    if ('cnhCategory' in input && input.cnhCategory && !['A','B','AB','C','D','E','AC','AD','AE'].includes(input.cnhCategory.toUpperCase())) throw new BadRequestException('Categoria de CNH inválida');
    for (const key of ['birthDate','cnhExpiry']) if (input[key]) {
      const raw = input[key];
      const parts = /^(\d{4})-(\d{2})-(\d{2})$/.exec(raw) || /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(raw);
      if (!parts) throw new BadRequestException('Informe uma data válida');
      const iso = raw.includes('/') ? `${parts[3]}-${parts[2]}-${parts[1]}` : raw;
      const date = new Date(iso + 'T00:00:00Z');
      if (!Number.isFinite(date.getTime()) || date.toISOString().slice(0,10) !== iso) throw new BadRequestException('Informe uma data válida');
      if (key === 'birthDate' && date > new Date()) throw new BadRequestException('Data de nascimento inválida');
    }
    let verified: any, identitySnapshot: any;
    if ('cpf' in input || 'document' in input || 'birthDate' in input) {
      identitySnapshot = await this.prisma.courierProfile.findUnique({where:{id}});
      if(!identitySnapshot)throw new NotFoundException('Motoboy não encontrado');
      if(input.cpf && input.document && input.cpf.replace(/\D/g,'')!==input.document.replace(/\D/g,''))throw new BadRequestException('CPF e documento devem corresponder');
      const cpf=String(input.cpf??input.document??identitySnapshot.document??(identitySnapshot.onboardingData as any)?.cpf??'').replace(/\D/g,'');
      const raw=String(input.birthDate??(identitySnapshot.onboardingData as any)?.birthDate??'');
      const birthDate=/^\d{4}-\d{2}-\d{2}$/.test(raw)?raw.split('-').reverse().join('/'):raw;
      const duplicate=await this.prisma.courierProfile.findFirst({where:{document:cpf,id:{not:id}},select:{id:true}});
      if(duplicate)throw new BadRequestException('Este CPF já possui cadastro');
      verified=await this.auth.verifyCourierIdentityForAdmin(cpf,birthDate);
      input.cpf=verified.cpf;input.document=verified.cpf;input.birthDate=verified.birthDate;input.name=verified.name;
    }
    let userId: string;
    try {
      userId = await this.prisma.$transaction(async tx => {
        await tx.$queryRawUnsafe('SELECT "id" FROM "CourierProfile" WHERE "id" = $1 FOR UPDATE', id);
        const current = await tx.courierProfile.findUnique({ where: { id } });
        if (!current) throw new NotFoundException('Motoboy não encontrado');
        if(identitySnapshot && (current.document!==identitySnapshot.document || (current.onboardingData as any)?.birthDate!==(identitySnapshot.onboardingData as any)?.birthDate))throw new BadRequestException('O cadastro foi atualizado. Reabra a ficha antes de salvar');
        const {extraData,...fields}=input;
        const stored:any=current.onboardingData||{};
        if(extraData)for(const key of Object.keys(extraData)){
          if(!Object.prototype.hasOwnProperty.call(stored,key)||allowed.includes(key)||/(password|senha|token|secret|cpf|status|role|verified|approval|commission|balance|earnings|online|session|permission)/i.test(key))throw new BadRequestException('Campo adicional não permitido');
          if(typeof extraData[key]!==typeof stored[key]||Array.isArray(extraData[key])!==Array.isArray(stored[key]))throw new BadRequestException('Mantenha o formato original dos dados adicionais');
        }
        const profileData: any = { onboardingData: { ...stored, ...extraData, ...fields } };
        if(verified){profileData.document=verified.cpf;profileData.onboardingData.cpfSituation=verified.situation;}

        for (const k of ['cnh','cnhCategory','vehicleBrand','vehicleModel','vehiclePlate']) if (k in input) profileData[k] = input[k] || null;
        if ('vehicleYear' in input) profileData.vehicleYear = input.vehicleYear ? Number(input.vehicleYear) : null;
        if ('pixKey' in input || 'pixKeyType' in input) {
          const pix = normalizePix(input.pixKey ?? current.pixKey, input.pixKeyType ?? current.pixKeyType);
          if (!pix) throw new BadRequestException('Informe uma chave PIX válida');
          profileData.pixKey = pix.key; profileData.pixKeyType = pix.type;
          profileData.onboardingData.pixKey = pix.key; profileData.onboardingData.pixKeyType = pix.type;
        }
        const userData: any = {};
        for (const k of ['name','email','phone']) if (k in input) userData[k] = input[k];
        if (Object.keys(userData).length) await tx.user.update({ where: { id: current.userId }, data: userData });
        await tx.courierProfile.update({ where: { id }, data: profileData });
        return current.userId;
      });
    } catch (e: any) { if (e.code === 'P2002') throw new BadRequestException('Este e-mail, telefone ou CPF já está cadastrado'); throw e; }
    this.realtime.emitToUser(userId, 'courier.profile.updated', { courierId: id });
    this.realtime.emitToRole('ADMIN', 'courier.profile.updated', { courierId: id });
    if(['profilePhoto','name','phone','vehiclePlate'].some(k=>k in input)){const orders=await this.prisma.order.findMany({where:{courierId:id,status:{notIn:['DELIVERED','CANCELED']}},select:{id:true,customerId:true,status:true}});for(const order of orders)this.realtime.emitOrderUpdated(order);}
    return { updated: true };
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

  async users(authorization?: string, compactCouriers=false) {
    await this.requireAdmin(authorization);
    if(compactCouriers)return this.prisma.user.findMany({select:{id:true,name:true,email:true,phone:true,role:true,status:true,createdAt:true,customerProfile:true,partnerProfile:true,courierProfile:{select:{id:true,document:true,approvalStatus:true,isOnline:true,vehicleModel:true,vehiclePlate:true}},_count:{select:{orders:true}}},orderBy:{createdAt:'desc'}});
    return this.prisma.user.findMany({
      include: {
        customerProfile: true,
        courierProfile: true,
        partnerProfile: true,
        _count: { select: { orders: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async customerActivity(id: string, pageRaw: number = 1, authorization?: string) {
    await this.requireAdmin(authorization);
    const page = Number.isFinite(pageRaw) ? Math.max(1,Math.floor(pageRaw)) : 1;
    const user = await this.prisma.user.findUnique({ where:{id},select:{id:true,name:true,email:true,phone:true,status:true,role:true,createdAt:true,updatedAt:true,customerProfile:true} });
    if(!user || user.role !== UserRole.CUSTOMER) throw new NotFoundException('Cliente não encontrado');
    const now = new Date();
    const [orders,totalOrders,paid,delivered,active,addresses,sessions] = await Promise.all([
      this.prisma.order.findMany({where:{customerId:id},include:{items:true,address:true,courier:{select:{vehicleBrand:true,vehicleModel:true,vehiclePlate:true,user:{select:{name:true,phone:true}}}}},orderBy:[{createdAt:'desc'},{id:'desc'}],take:20,skip:(page-1)*20}),
      this.prisma.order.count({where:{customerId:id}}),
      this.prisma.order.aggregate({where:{customerId:id,paymentStatus:PaymentStatus.PAID},_sum:{total:true},_count:true}),
      this.prisma.order.count({where:{customerId:id,status:OrderStatus.DELIVERED}}),
      this.prisma.order.count({where:{customerId:id,status:{notIn:[OrderStatus.DELIVERED,OrderStatus.CANCELED]}}}),
      this.prisma.address.findMany({where:{userId:id},orderBy:[{isDefault:'desc'},{createdAt:'desc'}]}),
      this.prisma.authSession.findMany({where:{userId:id,revokedAt:null,OR:[{expiresAt:{gt:now}},{refreshExpiresAt:{gt:now}}]},select:{deviceName:true,lastSeenAt:true,createdAt:true},orderBy:{lastSeenAt:'desc'},take:20}),
    ]);
    const clean=(value:any):any=>Array.isArray(value)?value.map(clean):value && typeof value==='object'?Object.fromEntries(Object.entries(value).filter(([k])=>!/(password|senha|token|secret)/i.test(k)).map(([k,v])=>[k,clean(v)])):value;
    return {user:{...user,customerProfile:user.customerProfile?{...user.customerProfile,onboardingData:clean(user.customerProfile.onboardingData)}:null},summary:{totalOrders,paidOrders:paid._count,paidTotal:Number(paid._sum.total||0),delivered,active},addresses,sessions,orders:orders.map(({deliveryPin,deliveryPinAttempts,deliveryPinVerifiedAt,stripePaymentIntentId,...order}:any)=>order),page,totalPages:Math.max(1,Math.ceil(totalOrders/20))};
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

  private normalizeBulkIds(ids: unknown) {
    if (!Array.isArray(ids)) {
      throw new BadRequestException('Selecione ao menos um registro');
    }

    const unique = [
      ...new Set(
        ids
          .map((id) => String(id ?? '').trim())
          .filter(Boolean),
      ),
    ];

    if (!unique.length) {
      throw new BadRequestException('Selecione ao menos um registro');
    }
    if (unique.length > 100) {
      throw new BadRequestException('Selecione no máximo 100 registros por operação');
    }

    return unique;
  }

  private async removeUser(userId: string, adminId: string) {
    if (adminId === userId) {
      throw new BadRequestException(
        'O administrador não pode excluir a própria conta',
      );
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        courierProfile: true,
        _count: { select: { orders: true } },
      },
    });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    if (user.role === UserRole.ADMIN) {
      throw new BadRequestException(
        'Contas administrativas não podem ser excluídas por esta ação',
      );
    }

    if (user.role === UserRole.CUSTOMER && user._count.orders > 0) {
      throw new BadRequestException(
        'Cliente possui histórico de pedidos e não pode ser excluído',
      );
    }

    if (user.courierProfile) {
      const courierId = user.courierProfile.id;
      const activeDeliveries = await this.prisma.order.count({
        where: {
          courierId,
          status: {
            notIn: [OrderStatus.DELIVERED, OrderStatus.CANCELED],
          },
        },
      });
      if (activeDeliveries > 0) {
        throw new BadRequestException(
          'Motoboy possui entrega ativa e não pode ser excluído',
        );
      }

      await this.prisma.$transaction(async (tx) => {
        await tx.order.updateMany({
          where: { courierId },
          data: { courierId: null },
        });
        await tx.courierLedgerEntry.deleteMany({
          where: { courierId },
        });
        await tx.withdrawal.deleteMany({
          where: { courierId },
        });
        await (tx as any).deliveryOffer.deleteMany({
          where: { courierId },
        });
        await (tx as any).courierDevicePresence.deleteMany({
          where: { courierId },
        });
        await tx.user.delete({ where: { id: userId } });
      });
    } else {
      await this.prisma.user.delete({ where: { id: userId } });
    }

    return {
      id: user.id,
      name: user.name,
      role: user.role,
    };
  }

  async deleteUser(userId: string, authorization?: string) {
    const admin = await this.requireAdmin(authorization);
    const deleted = await this.removeUser(userId, admin.id);
    return {
      success: true,
      deleted,
      message: `${deleted.name} foi excluído com sucesso`,
    };
  }

  async bulkDeleteUsers(ids: unknown, authorization?: string) {
    const admin = await this.requireAdmin(authorization);
    const normalized = this.normalizeBulkIds(ids);
    const deleted: Array<{ id: string; name: string; role: UserRole }> = [];
    const failed: Array<{ id: string; reason: string }> = [];

    for (const id of normalized) {
      try {
        deleted.push(await this.removeUser(id, admin.id));
      } catch (error) {
        failed.push({
          id,
          reason:
            error instanceof Error
              ? error.message
              : 'Não foi possível excluir este usuário',
        });
      }
    }

    const message = failed.length
      ? `${deleted.length} excluído(s). ${failed.length} registro(s) foram preservados por segurança.`
      : `${deleted.length} usuário(s) excluído(s) com sucesso`;

    return {
      success: failed.length === 0,
      deleted,
      failed,
      message,
    };
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

    const title = body.title?.trim();
    const description = body.description?.trim();

    if (!title || !description) {
      throw new BadRequestException('Título e descrição são obrigatórios');
    }

    const profile = await (this.prisma as any).courierProfile.findFirst({
      where: {
        OR: [
          { id: courierId },
          { userId: courierId },
        ],
      },
      include: { user: true },
    });

    if (!profile) {
      throw new NotFoundException('Candidatura do motoboy não encontrada');
    }

    return this.prisma.$transaction(async (tx) => {
      const requirement = await (tx as any).courierRequirement.create({
        data: {
          courierId: profile.id,
          title,
          description,
        },
      });

      await (tx as any).courierProfile.update({
        where: { id: profile.id },
        data: {
          approvalStatus: CourierStatus.PENDING,
        },
      });

      await tx.user.update({
        where: { id: profile.userId },
        data: { status: UserStatus.PENDING },
      });

      return {
        ...requirement,
        courier: {
          id: profile.id,
          userId: profile.userId,
          name: profile.user?.name ?? null,
        },
      };
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

  async updateOrderStatus(
    orderId: string,
    status: string,
    authorization?: string,
  ) {
    await this.requireAdmin(authorization);

    const allowed = [
      'PENDING',
      'CONFIRMED',
      'PREPARING',
      'READY_FOR_PICKUP',
      'CANCELED',
    ];
    if (!allowed.includes(status)) {
      throw new BadRequestException(
        'Etapas operacionais do motoboy são atualizadas somente pelo fluxo de entrega',
      );
    }

    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });
    if (!order) throw new NotFoundException('Pedido não encontrado');

    const data: any = { status: status as OrderStatus };
    if (status === 'CANCELED') data.canceledAt = new Date();

    return this.prisma.order.update({
      where: { id: orderId },
      data,
      include: {
        customer: { select: { id: true, name: true, phone: true } },
        courier: {
          include: {
            user: { select: { name: true, phone: true } },
          },
        },
        address: true,
        items: true,
      },
    });
  }

  async assignCourier(
    _orderId: string,
    _courierId: string,
    authorization?: string,
  ) {
    await this.requireAdmin(authorization);
    throw new BadRequestException(
      'Atribuição manual desativada. Use Liberar pedido para iniciar o despacho automático.',
    );
  }

  async releaseOrder(
    orderId: string,
    authorization?: string,
  ) {
    await this.requireAdmin(authorization);
    return this.dispatch.startDispatch(orderId);
  }

  async dispatchAudit(
    orderId: string,
    authorization?: string,
  ) {
    await this.requireAdmin(authorization);
    return this.dispatch.audit(orderId);
  }

  async withdrawals(authorization?: string) {
    return this.wallet.adminWithdrawals(authorization);
  }

  async updateWithdrawalStatus(
    id: string,
    status: string,
    authorization?: string,
  ) {
    return this.wallet.updateWithdrawalStatus(
      id,
      status,
      authorization,
    );
  }

  private async removeOrder(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        status: true,
        customer: { select: { name: true } },
      },
    });
    if (!order) throw new NotFoundException('Pedido não encontrado');
    if (
      order.status === OrderStatus.PICKED_UP ||
      order.status === OrderStatus.OUT_FOR_DELIVERY
    ) {
      throw new BadRequestException(
        'Pedido em entrega não pode ser excluído',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.courierLedgerEntry.deleteMany({
        where: { orderId },
      });
      await tx.order.delete({ where: { id: orderId } });
    });

    return {
      id: order.id,
      customerName: order.customer?.name ?? null,
    };
  }

  async deleteOrder(orderId: string, authorization?: string) {
    await this.requireAdmin(authorization);
    const deleted = await this.removeOrder(orderId);
    return {
      success: true,
      deleted,
      message: `Pedido #${deleted.id.slice(-8).toUpperCase()} excluído com sucesso`,
    };
  }

  async bulkDeleteOrders(ids: unknown, authorization?: string) {
    await this.requireAdmin(authorization);
    const normalized = this.normalizeBulkIds(ids);
    const deleted: Array<{ id: string; customerName: string | null }> = [];
    const failed: Array<{ id: string; reason: string }> = [];

    for (const id of normalized) {
      try {
        deleted.push(await this.removeOrder(id));
      } catch (error) {
        failed.push({
          id,
          reason:
            error instanceof Error
              ? error.message
              : 'Não foi possível excluir este pedido',
        });
      }
    }

    const message = failed.length
      ? `${deleted.length} pedido(s) excluído(s). ${failed.length} foram preservados por segurança.`
      : `${deleted.length} pedido(s) excluído(s) com sucesso`;

    return {
      success: failed.length === 0,
      deleted,
      failed,
      message,
    };
  }

  private catalogChanged(event = 'catalog.updated') {
    this.realtime.emitCatalogUpdated(event);
  }

  private catalogText(value: unknown, label: string, max: number, required = false) {
    if (typeof value !== 'string') throw new BadRequestException(`${label} inválido`);
    const text = value.trim();
    if ((required && !text) || text.length > max) throw new BadRequestException(`${label} inválido`);
    return text;
  }

  private catalogImage(value: unknown) {
    const text = this.catalogText(value ?? '', 'Imagem', 2048);
    if (!text) return null;
    try {
      const url = new URL(text);
      if (url.protocol !== 'https:' || url.username || url.password) throw new Error();
      return url.toString();
    } catch { throw new BadRequestException('Utilize uma URL HTTPS válida para a imagem'); }
  }

  private productFields(body: Record<string, unknown>, creating = false) {
    const data: Record<string, any> = {};
    for (const key of ['name', 'description'] as const) {
      if (body[key] !== undefined || (creating && key === 'name')) {
        data[key] = this.catalogText(body[key], key === 'name' ? 'Nome' : 'Descrição', key === 'name' ? 160 : 2000, key === 'name') || null;
      }
    }
    if (body.imageUrl !== undefined) data.imageUrl = this.catalogImage(body.imageUrl);
    for (const key of ['price', 'stock'] as const) {
      if (body[key] !== undefined || creating) {
        const raw = body[key] ?? (key === 'stock' ? 0 : undefined);
        const value = Number(raw);
        if ((typeof raw !== 'number' && typeof raw !== 'string') || raw === '' || !Number.isFinite(value) || value < 0 || value > (key === 'stock' ? 2147483647 : 99999999.99) || (key === 'stock' && !Number.isInteger(value)) || (key === 'price' && Math.abs(value * 100 - Math.round(value * 100)) > 0.00001)) {
          throw new BadRequestException(key === 'stock' ? 'Estoque inválido' : 'Preço inválido: utilize até duas casas decimais');
        }
        data[key] = value;
      }
    }
    for (const key of ['active', 'archived']) if (body[key] !== undefined) {
      if (typeof body[key] !== 'boolean') throw new BadRequestException('Disponibilidade inválida');
      data[key] = body[key];
    }
    return data;
  }

  async createProduct(body: Record<string, any>, authorization?: string) {
    await this.requireAdmin(authorization);
    const data = this.productFields(body, true);
    const categoryId = this.catalogText(body.categoryId, 'Categoria', 100, true);
    const category = await this.prisma.category.findUnique({ where: { id: categoryId } });
    if (!category || category.archived) throw new BadRequestException('Selecione uma categoria não arquivada');
    const result = await this.prisma.product.create({ data: { ...data, categoryId } as any, include: { category: true } });
    this.catalogChanged();
    return result;
  }

  async updateProduct(productId: string, body: Record<string, any>, authorization?: string) {
    await this.requireAdmin(authorization);
    if (!await this.prisma.product.findUnique({ where: { id: productId } })) throw new NotFoundException('Produto não encontrado');
    const data = this.productFields(body);
    if (body.categoryId !== undefined) {
      data.categoryId = this.catalogText(body.categoryId, 'Categoria', 100, true);
      const category = await this.prisma.category.findUnique({ where: { id: data.categoryId } });
      if (!category || category.archived) throw new BadRequestException('Selecione uma categoria não arquivada');
    }
    if (!Object.keys(data).length) throw new BadRequestException('Informe os campos que deseja atualizar');
    const result = await this.prisma.product.update({ where: { id: productId }, data });
    this.catalogChanged();
    return result;
  }

  private async categoryFields(body: Record<string, any>, id?: string) {
    const data: Record<string, any> = {};
    if (body.name !== undefined || !id) {
      data.name = this.catalogText(body.name, 'Nome da categoria', 100, true);
      data.slug = data.name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
      if (!data.slug) throw new BadRequestException('Nome da categoria inválido');
      const duplicate = await this.prisma.category.findFirst({ where: { ...(id ? { id: { not: id } } : {}), OR: [{ name: data.name }, { slug: data.slug }] } });
      if (duplicate) throw new BadRequestException('Categoria já cadastrada');
    }
    if (body.imageUrl !== undefined) data.imageUrl = this.catalogImage(body.imageUrl);
    if (body.position !== undefined) {
      const position = Number(body.position);
      if (!Number.isInteger(position) || position < 0 || position > 2147483647) throw new BadRequestException('Ordem inválida');
      data.position = position;
    }
    for (const key of ['active', 'archived']) if (body[key] !== undefined) {
      if (typeof body[key] !== 'boolean') throw new BadRequestException('Disponibilidade inválida');
      data[key] = body[key];
    }
    return data;
  }

  async createCategory(body: Record<string, any>, authorization?: string) {
    await this.requireAdmin(authorization);
    const data = await this.categoryFields(body);
    const result = await this.prisma.category.create({ data: data as any });
    this.catalogChanged();
    return result;
  }

  async updateCategory(id: string, body: Record<string, any>, authorization?: string) {
    await this.requireAdmin(authorization);
    if (!await this.prisma.category.findUnique({ where: { id } })) throw new NotFoundException('Categoria não encontrada');
    const data = await this.categoryFields(body, id);
    if (!Object.keys(data).length) throw new BadRequestException('Informe os campos que deseja atualizar');
    const result = await this.prisma.category.update({ where: { id }, data });
    this.catalogChanged();
    return result;
  }

  async updateStore(body: Record<string, any>, authorization?: string) {
    await this.requireAdmin(authorization);
    if (typeof body.storeOpen !== 'boolean') throw new BadRequestException('Informe se a loja está aberta');
    const data = { storeOpen: body.storeOpen, ...(body.storeMessage !== undefined ? { storeMessage: this.catalogText(body.storeMessage, 'Mensagem da loja', 240, true) } : {}) };
    const result = await this.prisma.deliveryPricingConfig.upsert({ where: { id: 'default' }, create: { id: 'default', ...data }, update: data, select: { storeOpen: true, storeMessage: true, updatedAt: true } });
    this.realtime.emitCatalogUpdated('store.updated', result);
    return result;
  }
}
