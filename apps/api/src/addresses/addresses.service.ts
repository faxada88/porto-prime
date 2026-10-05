import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { UserRole } from '../generated/prisma/client.js';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateAddressDto } from './dto/create-address.dto.js';

@Injectable()
export class AddressesService {
  constructor(private readonly prisma: PrismaService, private readonly auth: AuthService) {}

  async list(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    return this.prisma.address.findMany({ where: { userId: user.id }, orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }] });
  }

  async create(data: CreateAddressDto, authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== UserRole.CUSTOMER) throw new ForbiddenException('Apenas clientes podem cadastrar endereço');

    return this.prisma.$transaction(async (tx) => {
      if (data.isDefault) await tx.address.updateMany({ where: { userId: user.id }, data: { isDefault: false } });
      const count = await tx.address.count({ where: { userId: user.id } });
      return tx.address.create({
        data: {
          userId: user.id,
          label: data.label?.trim() || null,
          street: data.street.trim(),
          number: data.number.trim(),
          complement: data.complement?.trim() || null,
          neighborhood: data.neighborhood.trim(),
          city: data.city.trim(),
          state: data.state.trim().toUpperCase(),
          postalCode: data.postalCode.replace(/\D/g, ''),
          isDefault: data.isDefault ?? count === 0,
        },
      });
    });
  }
  async update(id: string, data: CreateAddressDto, authorization?: string) {
    const user=await this.auth.authenticate(authorization);
    const found=await this.prisma.address.findFirst({where:{id,userId:user.id}});
    if(!found) throw new NotFoundException('Endereço não encontrado');
    return this.prisma.$transaction(async tx=>{
      if(data.isDefault) await tx.address.updateMany({where:{userId:user.id,id:{not:id}},data:{isDefault:false}});
      return tx.address.update({where:{id},data:{label:data.label?.trim()||null,street:data.street.trim(),number:data.number.trim(),complement:data.complement?.trim()||null,neighborhood:data.neighborhood.trim(),city:data.city.trim(),state:data.state.trim().toUpperCase(),postalCode:data.postalCode.replace(/\\D/g,''),isDefault:data.isDefault??found.isDefault}});
    });
  }

  async remove(id:string,authorization?:string){
    const user=await this.auth.authenticate(authorization);
    const found=await this.prisma.address.findFirst({where:{id,userId:user.id},include:{_count:{select:{orders:true}}}});
    if(!found) throw new NotFoundException('Endereço não encontrado');
    if(found._count.orders>0) throw new ForbiddenException('Este endereço está vinculado ao histórico de pedidos e não pode ser excluído. Você pode editá-lo ou cadastrar outro endereço.');
    await this.prisma.address.delete({where:{id}});
    if(found.isDefault){const next=await this.prisma.address.findFirst({where:{userId:user.id},orderBy:{createdAt:'desc'}});if(next)await this.prisma.address.update({where:{id:next.id},data:{isDefault:true}})}
    return {success:true};
  }
}
