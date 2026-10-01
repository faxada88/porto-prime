import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateCategoryDto } from './dto/create-category.dto.js';

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.category.findMany({
      where: { active: true },
      include: {
        products: {
          where: { active: true },
          orderBy: { name: 'asc' },
        },
      },
      orderBy: [{ position: 'asc' }, { name: 'asc' }],
    });
  }

  create(data: CreateCategoryDto) {
    return this.prisma.category.create({
      data: {
        name: data.name.trim(),
        slug: data.slug.trim().toLowerCase(),
        imageUrl: data.imageUrl || null,
        position: data.position ?? 0,
      },
    });
  }
}
