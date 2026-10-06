import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { PrismaService } from '../src/prisma/prisma.service.js';

const unique = () =>
  Date.now().toString(36) + Math.random().toString(36).slice(2, 8);

function cpfFromSeed(seed: number) {
  const base = String(100000000 + (seed % 899999999)).padStart(9, '0');
  const calc = (digits: string, factor: number) => {
    let sum = 0;
    for (const char of digits) sum += Number(char) * factor--;
    const mod = (sum * 10) % 11;
    return mod === 10 ? 0 : mod;
  };
  const d1 = calc(base, 10);
  const d2 = calc(base + d1, 11);
  return base + d1 + d2;
}

describe('Arquitetura escalável Porto Prime (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    prisma = moduleFixture.get(PrismaService);
  });

  afterAll(async () => {
    await app.close();
  });

  async function registerCustomer(index = 0) {
    const tag = unique();
    const email = `scale.customer.${tag}@example.com`;
    const phone =
      '77' +
      String(
        900000000 + ((Date.now() + index * 7919) % 99999999),
      ).slice(0, 9);
    const password = 'PortoPrime123';

    const response = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        name: `Cliente Escala ${tag}`,
        email,
        phone,
        password,
        role: 'CUSTOMER',
        profileData: { test: true, tag },
      })
      .expect(201);

    return {
      id: response.body.id as string,
      email,
      phone,
      password,
      tag,
    };
  }

  async function registerCourier(index: number) {
    const tag = unique();
    const email = `scale.courier.${tag}@example.com`;
    const phone =
      '73' +
      String(
        900000000 + ((Date.now() + index * 3571) % 99999999),
      ).slice(0, 9);
    const password = 'PortoPrime123';
    const document = cpfFromSeed(
      Number(String(Date.now()).slice(-7)) + index * 97,
    );

    const response = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        name: `Motoboy Escala ${tag}`,
        email,
        phone,
        password,
        role: 'COURIER',
        document,
        cnh: `CNH${Date.now()}${index}`,
        cnhCategory: 'A',
        vehicleBrand: 'Honda',
        vehicleModel: 'CG 160',
        vehiclePlate: `TST${String(index).padStart(4, '0')}`.slice(0, 7),
        vehicleYear: 2025,
        profileData: {
          test: true,
          cpf: document,
          pixKey: email,
        },
      })
      .expect(201);

    await prisma.user.update({
      where: { id: response.body.id },
      data: { status: 'ACTIVE' },
    });
    const profile = await prisma.courierProfile.update({
      where: { userId: response.body.id },
      data: {
        approvalStatus: 'APPROVED',
        pixKeyType: 'EMAIL',
        pixKey: email,
      },
    });

    return {
      id: response.body.id as string,
      courierId: profile.id,
      email,
      phone,
      password,
      document,
      tag,
    };
  }

  async function login(
    email: string,
    password: string,
    deviceId: string,
  ) {
    const response = await request(app.getHttpServer())
      .post('/auth/login')
      .set('X-Device-Id', deviceId)
      .set('X-Device-Name', 'Vitest')
      .send({ email, password })
      .expect(201);

    return response.body as {
      accessToken: string;
      refreshToken: string;
      sessionId: string;
    };
  }

  async function cleanupUsers(userIds: string[]) {
    const couriers = await prisma.courierProfile.findMany({
      where: { userId: { in: userIds } },
      select: { id: true },
    });
    const courierIds = couriers.map((x) => x.id);

    if (courierIds.length) {
      await prisma.courierLedgerEntry.deleteMany({
        where: { courierId: { in: courierIds } },
      });
      await prisma.withdrawal.deleteMany({
        where: { courierId: { in: courierIds } },
      });
      await (prisma as any).deliveryOffer.deleteMany({
        where: { courierId: { in: courierIds } },
      });
      await (prisma as any).courierDevicePresence.deleteMany({
        where: { courierId: { in: courierIds } },
      });
    }

    const orders = await prisma.order.findMany({
      where: {
        OR: [
          { customerId: { in: userIds } },
          ...(courierIds.length
            ? [{ courierId: { in: courierIds } }]
            : []),
        ],
      },
      select: { id: true },
    });
    const orderIds = orders.map((x) => x.id);

    if (orderIds.length) {
      await prisma.courierLedgerEntry.deleteMany({
        where: { orderId: { in: orderIds } },
      });
      await (prisma as any).dispatchEvent.deleteMany({
        where: { orderId: { in: orderIds } },
      });
      await (prisma as any).deliveryOffer.deleteMany({
        where: { orderId: { in: orderIds } },
      });
      await prisma.orderItem.deleteMany({
        where: { orderId: { in: orderIds } },
      });
      await prisma.order.deleteMany({
        where: { id: { in: orderIds } },
      });
    }

    await prisma.address.deleteMany({
      where: { userId: { in: userIds } },
    });
    await prisma.authSession.deleteMany({
      where: { userId: { in: userIds } },
    });
    await prisma.user.deleteMany({
      where: { id: { in: userIds } },
    });
  }

  it('mantém 20 clientes simultâneos com dados completamente isolados', async () => {
    const customers = await Promise.all(
      Array.from({ length: 20 }, (_, i) => registerCustomer(i)),
    );
    const userIds = customers.map((x) => x.id);

    try {
      const sessions = await Promise.all(
        customers.map((customer, i) =>
          login(
            customer.email,
            customer.password,
            `customer-device-${i}-${customer.tag}`,
          ),
        ),
      );

      await Promise.all(
        customers.map((customer, i) =>
          request(app.getHttpServer())
            .post('/addresses')
            .set('Authorization', `Bearer ${sessions[i].accessToken}`)
            .send({
              label: 'Casa',
              street: `Rua Isolada ${customer.tag}`,
              number: String(i + 1),
              neighborhood: 'Centro',
              city: 'Porto Seguro',
              state: 'BA',
              postalCode: '45810000',
              isDefault: true,
            })
            .expect(201),
        ),
      );

      const addressLists = await Promise.all(
        sessions.map((session) =>
          request(app.getHttpServer())
            .get('/addresses')
            .set('Authorization', `Bearer ${session.accessToken}`)
            .expect(200),
        ),
      );

      for (let i = 0; i < addressLists.length; i++) {
        expect(addressLists[i].body).toHaveLength(1);
        expect(addressLists[i].body[0].userId).toBe(customers[i].id);
        expect(addressLists[i].body[0].street).toContain(
          customers[i].tag,
        );
      }

      expect(
        new Set(sessions.map((x) => x.sessionId)).size,
      ).toBe(20);
      expect(
        new Set(sessions.map((x) => x.accessToken)).size,
      ).toBe(20);
    } finally {
      await cleanupUsers(userIds);
    }
  });

  it('mantém duas sessões do mesmo motoboy sem um dispositivo derrubar o outro', async () => {
    const courier = await registerCourier(1001);

    try {
      const a = await login(
        courier.email,
        courier.password,
        'courier-phone-a-' + courier.tag,
      );
      const b = await login(
        courier.email,
        courier.password,
        'courier-phone-b-' + courier.tag,
      );

      expect(a.sessionId).not.toBe(b.sessionId);

      await request(app.getHttpServer())
        .patch('/orders/courier/heartbeat')
        .set('Authorization', `Bearer ${a.accessToken}`)
        .send({ online: true })
        .expect(200);

      await request(app.getHttpServer())
        .patch('/orders/courier/heartbeat')
        .set('Authorization', `Bearer ${b.accessToken}`)
        .send({ online: true })
        .expect(200);

      const first = await prisma.courierProfile.findUniqueOrThrow({
        where: { id: courier.courierId },
      });
      expect(first.presenceStatus).toBe('AVAILABLE');

      await request(app.getHttpServer())
        .patch('/orders/courier/heartbeat')
        .set('Authorization', `Bearer ${a.accessToken}`)
        .send({ online: false })
        .expect(200);

      const stillAvailable =
        await prisma.courierProfile.findUniqueOrThrow({
          where: { id: courier.courierId },
        });
      expect(stillAvailable.presenceStatus).toBe('AVAILABLE');

      await request(app.getHttpServer())
        .post('/auth/logout')
        .set('Authorization', `Bearer ${a.accessToken}`)
        .expect(201);

      await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', `Bearer ${b.accessToken}`)
        .expect(200);

      await request(app.getHttpServer())
        .patch('/orders/courier/heartbeat')
        .set('Authorization', `Bearer ${b.accessToken}`)
        .send({ online: true })
        .expect(200);
    } finally {
      await cleanupUsers([courier.id]);
    }
  });

  it('permite somente uma aceitação concorrente e um único crédito de carteira', async () => {
    const customer = await registerCustomer(3001);
    const courierA = await registerCourier(3002);
    const courierB = await registerCourier(3003);
    const userIds = [customer.id, courierA.id, courierB.id];

    try {
      const [sessionA, sessionB] = await Promise.all([
        login(
          courierA.email,
          courierA.password,
          'race-a-' + courierA.tag,
        ),
        login(
          courierB.email,
          courierB.password,
          'race-b-' + courierB.tag,
        ),
      ]);

      const address = await prisma.address.create({
        data: {
          userId: customer.id,
          label: 'Teste concorrência',
          street: 'Avenida Teste',
          number: '100',
          neighborhood: 'Centro',
          city: 'Porto Seguro',
          state: 'BA',
          postalCode: '45810000',
          isDefault: true,
        },
      });

      const order = await prisma.order.create({
        data: {
          customerId: customer.id,
          addressId: address.id,
          status: 'SEARCHING_COURIER',
          paymentStatus: 'PAID',
          paymentMethod: 'CARD',
          subtotal: 100,
          deliveryFee: 18.5,
          total: 118.5,
          deliveryPin: '4821',
        },
      });

      const expiresAt = new Date(Date.now() + 60_000);
      const offerA = await (prisma as any).deliveryOffer.create({
        data: {
          orderId: order.id,
          courierId: courierA.courierId,
          status: 'PENDING',
          expiresAt,
        },
      });
      await (prisma as any).deliveryOffer.create({
        data: {
          orderId: order.id,
          courierId: courierB.courierId,
          status: 'PENDING',
          expiresAt,
        },
      });
      await prisma.order.update({
        where: { id: order.id },
        data: { activeOfferId: offerA.id },
      });
      await (prisma as any).courierProfile.updateMany({
        where: {
          id: { in: [courierA.courierId, courierB.courierId] },
        },
        data: { presenceStatus: 'OFFERED' },
      });

      const acceptResults = await Promise.all([
        request(app.getHttpServer())
          .patch(`/orders/${order.id}/courier/accept`)
          .set('Authorization', `Bearer ${sessionA.accessToken}`),
        request(app.getHttpServer())
          .patch(`/orders/${order.id}/courier/accept`)
          .set('Authorization', `Bearer ${sessionB.accessToken}`),
      ]);

      expect(
        acceptResults.filter((r) => r.status === 200).length,
      ).toBe(1);
      expect(
        acceptResults.filter((r) => r.status >= 400).length,
      ).toBe(1);

      const assigned = await prisma.order.findUniqueOrThrow({
        where: { id: order.id },
      });
      expect([
        courierA.courierId,
        courierB.courierId,
      ]).toContain(assigned.courierId);

      const winnerSession =
        assigned.courierId === courierA.courierId
          ? sessionA
          : sessionB;

      await prisma.order.update({
        where: { id: order.id },
        data: { status: 'OUT_FOR_DELIVERY' },
      });

      const finishResults = await Promise.all([
        request(app.getHttpServer())
          .patch(`/orders/${order.id}/courier/status`)
          .set(
            'Authorization',
            `Bearer ${winnerSession.accessToken}`,
          )
          .send({ status: 'DELIVERED', pin: '4821' }),
        request(app.getHttpServer())
          .patch(`/orders/${order.id}/courier/status`)
          .set(
            'Authorization',
            `Bearer ${winnerSession.accessToken}`,
          )
          .send({ status: 'DELIVERED', pin: '4821' }),
      ]);

      expect(
        finishResults.filter((r) => r.status === 200).length,
      ).toBe(1);

      const credits = await prisma.courierLedgerEntry.findMany({
        where: {
          orderId: order.id,
          type: 'DELIVERY_CREDIT',
        },
      });

      expect(credits).toHaveLength(1);
      expect(Number(credits[0].amount)).toBe(18.5);

      const audit = await (prisma as any).dispatchEvent.findMany({
        where: { orderId: order.id },
      });
      expect(
        audit.filter((event: any) => event.type === 'WALLET_CREDITED'),
      ).toHaveLength(1);
    } finally {
      await cleanupUsers(userIds);
    }
  });
});
