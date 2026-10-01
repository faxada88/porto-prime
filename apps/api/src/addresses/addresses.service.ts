import { ForbiddenException, Injectable } from '@nestjs/common';
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
}
