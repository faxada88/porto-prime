import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client.js';

function isLocalPrismaDev(connectionString: string) {
  try {
    const url = new URL(connectionString);
    const localHost =
      url.hostname === 'localhost' ||
      url.hostname === '127.0.0.1' ||
      url.hostname === '::1';

    return localHost && /^512\d+$/.test(url.port);
  } catch {
    return false;
  }
}

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    const connectionString = process.env.DATABASE_URL;

    if (!connectionString) {
      throw new Error('DATABASE_URL não configurada');
    }

    const localPrismaDev = isLocalPrismaDev(connectionString);
    const configuredPoolMax = Number(process.env.DATABASE_POOL_MAX);
    const max =
      Number.isInteger(configuredPoolMax) && configuredPoolMax > 0
        ? configuredPoolMax
        : localPrismaDev
          ? 1
          : 10;

    const adapter = new PrismaPg({
      connectionString,
      max,
      connectionTimeoutMillis: 0,
      idleTimeoutMillis: localPrismaDev ? 1_000 : 10_000,
      maxLifetimeSeconds: 0,
    });

    super({ adapter });
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
