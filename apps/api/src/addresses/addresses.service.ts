import { RealtimeGateway } from '../realtime/realtime.gateway.js';
import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { UserRole } from '../generated/prisma/client.js';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateAddressDto } from './dto/create-address.dto.js';

@Injectable()
export class AddressesService {
  constructor(private readonly prisma: PrismaService, private readonly auth: AuthService, private readonly realtime: RealtimeGateway) {}

  private coordinates(data: CreateAddressDto) {
    if (data.latitude === undefined && data.longitude === undefined) return null;
    if (typeof data.latitude !== 'number' || typeof data.longitude !== 'number' || !Number.isFinite(data.latitude) || !Number.isFinite(data.longitude) || Math.abs(data.latitude) > 90 || Math.abs(data.longitude) > 180) throw new BadRequestException('Confirme o ponto de entrega no mapa');
    return { latitude: data.latitude, longitude: data.longitude, locationConfirmed: true };
  }
  private changed(userId: string) { this.realtime.emitToUser(userId, 'addresses.updated', { at: new Date().toISOString() }); this.realtime.emitToRole('ADMIN', 'addresses.updated', { at: new Date().toISOString() }); }

  async list(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    return this.prisma.address.findMany({ where: { userId: user.id }, orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }] });
  }

  async create(data: CreateAddressDto, authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Apenas clientes podem cadastrar endereço');

    const coords = this.coordinates(data);
    const saved = await this.prisma.$transaction(async (tx) => {
      if (data.isDefault) await tx.address.updateMany({ where: { userId: user.id }, data: { isDefault: false } });
      const count = await tx.address.count({ where: { userId: user.id } });
      return tx.address.create({
        data: {
          ...(coords ?? {}),
          userId: user.id,
          label: data.label?.trim() || null,
          street: data.street.trim(),
          number: data.number.trim(),
          complement: data.complement?.trim() || null,
          neighborhood: data.neighborhood.trim(),
          city: data.city.trim(),
          state: data.state.trim().toUpperCase(),
          postalCode: data.postalCode.replace(/\D/g, ''),
          isDefault: count === 0 || (data.isDefault ?? false),
        },
      });
    });
    this.changed(user.id);
    return saved;
  }
  async update(id: string, data: CreateAddressDto, authorization?: string) {
    const user=await this.auth.authenticate(authorization);
    const found=await this.prisma.address.findFirst({where:{id,userId:user.id}});
    if(!found) throw new NotFoundException('Endereço não encontrado');
    const coords = this.coordinates(data);
    const moved = ['street','number','neighborhood','city','state','postalCode'].some(k => String((data as any)[k]).replace(k==='postalCode'?/\D/g:/\s/g,'').toLowerCase() !== String((found as any)[k]).replace(k==='postalCode'?/\D/g:/\s/g,'').toLowerCase());
    const location = coords ?? (moved ? { latitude: null, longitude: null, locationConfirmed: false } : {});
    const saved = await this.prisma.$transaction(async tx=>{
      if(data.isDefault) await tx.address.updateMany({where:{userId:user.id,id:{not:id}},data:{isDefault:false}});
      return tx.address.update({where:{id},data:{...location,label:data.label?.trim()||null,street:data.street.trim(),number:data.number.trim(),complement:data.complement?.trim()||null,neighborhood:data.neighborhood.trim(),city:data.city.trim(),state:data.state.trim().toUpperCase(),postalCode:data.postalCode.replace(/\D/g,''),isDefault:data.isDefault??found.isDefault}});
    });
    this.changed(user.id);
    return saved;
  }

  async remove(id:string,authorization?:string){
    const user=await this.auth.authenticate(authorization);
    const found=await this.prisma.address.findFirst({where:{id,userId:user.id},include:{_count:{select:{orders:true}}}});
    if(!found) throw new NotFoundException('Endereço não encontrado');
    if(found._count.orders>0) throw new ForbiddenException('Este endereço está vinculado ao histórico de pedidos e não pode ser excluído. Você pode editá-lo ou cadastrar outro endereço.');
    await this.prisma.address.delete({where:{id}});
    if(found.isDefault){const next=await this.prisma.address.findFirst({where:{userId:user.id},orderBy:{createdAt:'desc'}});if(next)await this.prisma.address.update({where:{id:next.id},data:{isDefault:true}})}
    this.changed(user.id);
    return {success:true};
  }
}
