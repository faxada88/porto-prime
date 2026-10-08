import { RealtimeGateway } from '../realtime/realtime.gateway.js';
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateCategoryDto } from './dto/create-category.dto.js';

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService, private readonly realtime?: RealtimeGateway) {}

  findAll() {
    return this.prisma.category.findMany({
      where: { active: true, archived: false },
      include: {
        products: {
          where: { active: true, archived: false },
          orderBy: { name: 'asc' },
        },
      },
      orderBy: [{ position: 'asc' }, { name: 'asc' }],
    });
  }

  async create(data: CreateCategoryDto) {
    const result = await this.prisma.category.create({
      data: {
        name: data.name.trim(),
        slug: data.slug.trim().toLowerCase(),
        imageUrl: data.imageUrl || null,
        position: data.position ?? 0,
      },
    });
    this.realtime?.emitCatalogUpdated();
    return result;
  }
}
