import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { CourierStatus, OrderStatus, PaymentStatus, UserRole, UserStatus } from '../generated/prisma/client.js';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService, private readonly auth: AuthService) {}

  private async requireAdmin(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.ADMIN) throw new ForbiddenException('Acesso exclusivo do administrador');
    return user;
  }

  async dashboard(authorization?: string) {
    await this.requireAdmin(authorization);
    const [users, pending, orders, products, onlineCouriers, revenue] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.user.count({ where: { status: UserStatus.PENDING } }),
      this.prisma.order.count(),
      this.prisma.product.count({ where: { active: true } }),
      this.prisma.courierProfile.count({ where: { isOnline: true, approvalStatus: CourierStatus.APPROVED } }),
      this.prisma.order.aggregate({ where: { paymentStatus: PaymentStatus.PAID }, _sum: { total: true } }),
    ]);
    return { users, pending, orders, products, onlineCouriers, revenue: revenue._sum.total ?? 0 };
  }

  async pending(authorization?: string) {
    await this.requireAdmin(authorization);
    return this.prisma.user.findMany({
      where: { status: UserStatus.PENDING, role: { in: [UserRole.COURIER, UserRole.PARTNER] } },
      select: { id:true,name:true,email:true,phone:true,document:true,role:true,status:true,courierProfile:{include:{requirements:{orderBy:{createdAt:'desc'}}}},partnerProfile:true,createdAt:true },
      orderBy: { createdAt: 'asc' },
    });
  }

  async users(role: UserRole | undefined, authorization?: string) {
    await this.requireAdmin(authorization);
    return this.prisma.user.findMany({
      where: role ? { role } : { role: { not: UserRole.ADMIN } },
      select: {
        id:true,name:true,email:true,phone:true,document:true,role:true,status:true,createdAt:true,updatedAt:true,
        customerProfile:true,
        courierProfile:{ include:{ requirements:{orderBy:{createdAt:'desc'}}, _count:{ select:{ deliveries:true } } } },
        partnerProfile:true,
        _count:{ select:{ orders:true } },
      },
      orderBy:{ createdAt:'desc' },
    });
  }

  async setUserStatus(userId:string, status:UserStatus, authorization?:string) {
    await this.requireAdmin(authorization);
    if (status !== UserStatus.ACTIVE && status !== UserStatus.BLOCKED && status !== UserStatus.SUSPENDED) throw new BadRequestException('Status inválido');
    const user=await this.prisma.user.findUnique({where:{id:userId}});
    if(!user) throw new NotFoundException('Usuário não encontrado');
    if(user.role===UserRole.ADMIN) throw new ForbiddenException('Não é permitido alterar outro administrador por esta operação');
    if(user.role===UserRole.COURIER && status!==UserStatus.ACTIVE) {
      await this.prisma.courierProfile.updateMany({where:{userId},data:{isOnline:false}});
    }
    return this.prisma.user.update({where:{id:userId},data:{status},select:{id:true,name:true,role:true,status:true}});
  }

  async requestCourierInfo(userId:string,data:{title:string;message:string;fieldKey?:string},authorization?:string) {
    await this.requireAdmin(authorization);
    const user=await this.prisma.user.findUnique({where:{id:userId},include:{courierProfile:true}});
    if(!user?.courierProfile || user.role!==UserRole.COURIER) throw new NotFoundException('Motoboy não encontrado');
    const title=String(data.title??'').trim(),message=String(data.message??'').trim();
    if(!title||!message) throw new BadRequestException('Título e orientação são obrigatórios');
    const requirement=await this.prisma.courierRequirement.create({data:{courierId:user.courierProfile.id,title,message,fieldKey:data.fieldKey?.trim()||null}});
    await this.prisma.courierProfile.update({where:{id:user.courierProfile.id},data:{approvalStatus:'NEEDS_INFO',isOnline:false}});
    await this.prisma.user.update({where:{id:userId},data:{status:UserStatus.PENDING}});
    return requirement;
  }

  async resolveCourierRequirement(id:string,authorization?:string) {
    await this.requireAdmin(authorization);
    const requirement=await this.prisma.courierRequirement.findUnique({where:{id}});
    if(!requirement) throw new NotFoundException('Pendência não encontrada');
    return this.prisma.courierRequirement.update({where:{id},data:{status:'RESOLVED',resolvedAt:new Date()}});
  }

  async approve(userId:string, authorization?:string) {
    await this.requireAdmin(authorization);
    const user=await this.prisma.user.findUnique({where:{id:userId},include:{courierProfile:{include:{requirements:true}},partnerProfile:true}});
    if(!user) throw new NotFoundException('Usuário não encontrado');
    return this.prisma.$transaction(async tx=>{
      if(user.role===UserRole.COURIER && user.courierProfile) { const open=user.courierProfile.requirements.some(r=>r.status!=='RESOLVED'); if(open) throw new BadRequestException('Resolva todas as pendências antes de aprovar'); await tx.courierProfile.update({where:{id:user.courierProfile.id},data:{approvalStatus:CourierStatus.APPROVED}}); }
      else if(user.role===UserRole.PARTNER && user.partnerProfile) await tx.partnerProfile.update({where:{id:user.partnerProfile.id},data:{approved:true}});
      else throw new ForbiddenException('Perfil não requer aprovação');
      return tx.user.update({where:{id:userId},data:{status:UserStatus.ACTIVE},select:{id:true,name:true,email:true,role:true,status:true}});
    });
  }

  async reject(userId:string, authorization?:string) {
    await this.requireAdmin(authorization);
    const user=await this.prisma.user.findUnique({where:{id:userId},include:{courierProfile:true}});
    if(!user) throw new NotFoundException('Usuário não encontrado');
    if(user.role===UserRole.COURIER && user.courierProfile) await this.prisma.courierProfile.update({where:{id:user.courierProfile.id},data:{approvalStatus:CourierStatus.REJECTED,isOnline:false}});
    return this.prisma.user.update({where:{id:userId},data:{status:UserStatus.BLOCKED},select:{id:true,name:true,email:true,role:true,status:true}});
  }

  async orders(authorization?:string) {
    await this.requireAdmin(authorization);
    return this.prisma.order.findMany({
      include:{items:true,address:true,customer:{select:{id:true,name:true,email:true,phone:true}},courier:{include:{user:{select:{id:true,name:true,phone:true}}}}},
      orderBy:{createdAt:'desc'},
    });
  }

  async deleteOrder(orderId:string,authorization?:string) {
    await this.requireAdmin(authorization);
    const order=await this.prisma.order.findUnique({where:{id:orderId},select:{id:true,courierId:true}});
    if(!order) throw new NotFoundException('Pedido não encontrado');
    return this.prisma.$transaction(async tx=>{
      await tx.courierLedgerEntry.deleteMany({where:{orderId}});
      await tx.orderItem.deleteMany({where:{orderId}});
      await tx.order.delete({where:{id:orderId}});
      if(order.courierId) await tx.courierProfile.updateMany({where:{id:order.courierId},data:{isOnline:true}});
      return {success:true,id:orderId};
    });
  }

  async deleteUser(userId:string,authorization?:string) {
    await this.requireAdmin(authorization);
    const user=await this.prisma.user.findUnique({where:{id:userId},include:{courierProfile:true}});
    if(!user) throw new NotFoundException('Usuário não encontrado');
    if(user.role===UserRole.ADMIN) throw new ForbiddenException('Administrador não pode ser removido por esta operação');
    if(user.role===UserRole.COURIER && user.courierProfile){
      const active=await this.prisma.order.count({where:{courierId:user.courierProfile.id,status:{notIn:[OrderStatus.DELIVERED,OrderStatus.CANCELED]}}});
      if(active>0) throw new BadRequestException('Este motoboy possui entrega ativa. Finalize ou reatribua antes de remover.');
      await this.prisma.order.updateMany({where:{courierId:user.courierProfile.id},data:{courierId:null}});
    }
    if(user.role===UserRole.CUSTOMER){
      const count=await this.prisma.order.count({where:{customerId:userId}});
      if(count>0) throw new BadRequestException('Cliente possui histórico de pedidos e não pode ser removido por esta operação');
    }
    await this.prisma.user.delete({where:{id:userId}});
    return {success:true,id:userId};
  }

  async setOrderStatus(orderId:string,status:OrderStatus,authorization?:string) {
    await this.requireAdmin(authorization);
    if(!Object.values(OrderStatus).includes(status)) throw new BadRequestException('Status de pedido inválido');
    const order=await this.prisma.order.findUnique({where:{id:orderId}});
    if(!order) throw new NotFoundException('Pedido não encontrado');
    return this.prisma.order.update({where:{id:orderId},data:{status,deliveredAt:status===OrderStatus.DELIVERED?new Date():undefined,canceledAt:status===OrderStatus.CANCELED?new Date():undefined}});
  }

  async assignCourier(orderId:string,courierId:string,authorization?:string) {
    await this.requireAdmin(authorization);
    const courier=await this.prisma.courierProfile.findUnique({where:{id:courierId},include:{user:true}});
    if(!courier || courier.approvalStatus!==CourierStatus.APPROVED || courier.user.status!==UserStatus.ACTIVE) throw new BadRequestException('Motoboy indisponível para atribuição');
    const order=await this.prisma.order.findUnique({where:{id:orderId}});
    if(!order) throw new NotFoundException('Pedido não encontrado');
    return this.prisma.order.update({where:{id:orderId},data:{courierId,status:OrderStatus.COURIER_ASSIGNED}});
  }

  async releaseOrder(orderId:string,authorization?:string) {
    await this.requireAdmin(authorization);
    const order=await this.prisma.order.findUnique({where:{id:orderId}});
    if(!order) throw new NotFoundException('Pedido não encontrado');
    if(order.paymentStatus!==PaymentStatus.PAID) throw new ForbiddenException('O pedido precisa estar pago antes da liberação');
    if(order.status!==OrderStatus.CONFIRMED && order.status!==OrderStatus.PREPARING) throw new ForbiddenException('Pedido não está aguardando liberação');
    // Ao liberar, o pedido entra imediatamente no pool dos motoboys online.
    // A aceitação é atômica: apenas o primeiro motoboy consegue assumir.
    return this.prisma.order.update({where:{id:orderId},data:{courierId:null,status:OrderStatus.READY_FOR_PICKUP}});
  }

  async catalog(authorization?:string) {
    await this.requireAdmin(authorization);
    return this.prisma.category.findMany({include:{products:{orderBy:{name:'asc'}}},orderBy:[{position:'asc'},{name:'asc'}]});
  }

  async createCategory(data:Record<string,unknown>,authorization?:string) {
    await this.requireAdmin(authorization);
    const name=String(data.name??'').trim(); if(!name) throw new BadRequestException('Nome obrigatório');
    const slug=String(data.slug??name.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/[^a-z0-9]+/g,'-').replace(/(^-|-$)/g,''));
    return this.prisma.category.create({data:{name,slug,position:Number(data.position??0),active:data.active!==false}});
  }

  async createProduct(data:Record<string,unknown>,authorization?:string) {
    await this.requireAdmin(authorization);
    const categoryId=String(data.categoryId??''); const name=String(data.name??'').trim(); const price=Number(data.price); const stock=Number(data.stock??0);
    if(!categoryId||!name||!Number.isFinite(price)||price<0||!Number.isInteger(stock)||stock<0) throw new BadRequestException('Dados do produto inválidos');
    return this.prisma.product.create({data:{categoryId,name,description:String(data.description??'').trim()||null,imageUrl:String(data.imageUrl??'').trim()||null,price,stock,active:data.active!==false},include:{category:true}});
  }

  async updateProduct(id:string,data:Record<string,unknown>,authorization?:string) {
    await this.requireAdmin(authorization);
    const product=await this.prisma.product.findUnique({where:{id}}); if(!product) throw new NotFoundException('Produto não encontrado');
    const patch:any={};
    if(data.name!==undefined) patch.name=String(data.name).trim();
    if(data.description!==undefined) patch.description=String(data.description).trim()||null;
    if(data.imageUrl!==undefined) patch.imageUrl=String(data.imageUrl).trim()||null;
    if(data.categoryId!==undefined) patch.categoryId=String(data.categoryId);
    if(data.price!==undefined){const n=Number(data.price);if(!Number.isFinite(n)||n<0)throw new BadRequestException('Preço inválido');patch.price=n}
    if(data.stock!==undefined){const n=Number(data.stock);if(!Number.isInteger(n)||n<0)throw new BadRequestException('Estoque inválido');patch.stock=n}
    if(data.active!==undefined) patch.active=Boolean(data.active);
    return this.prisma.product.update({where:{id},data:patch,include:{category:true}});
  }
}
