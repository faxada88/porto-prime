import { INestApplication } from '@nestjs/common';
import { setMaxListeners } from 'node:events';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module.js';
import { DispatchService } from '../src/dispatch/dispatch.service.js';
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
  let dispatch: DispatchService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    setMaxListeners(100, app.getHttpServer());
    await app.init();
    prisma = moduleFixture.get(PrismaService);
    dispatch = moduleFixture.get(DispatchService);
  });

  afterAll(async () => {
    await app.close();
  }, 30_000);

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
    const customers = [];
    for (let i = 0; i < 20; i++) {
      customers.push(await registerCustomer(i));
    }
    const userIds = customers.map((x) => x.id);

    try {
      const sessions = [];
      for (let i = 0; i < customers.length; i++) {
        const customer = customers[i];
        sessions.push(
          await login(
            customer.email,
            customer.password,
            `customer-device-${i}-${customer.tag}`,
          ),
        );
      }

      for (let i = 0; i < customers.length; i++) {
        const customer = customers[i];
        await request(app.getHttpServer())
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
          .expect(201);
      }

      const addressLists = [];
      for (const session of sessions) {
        addressLists.push(
          await request(app.getHttpServer())
            .get('/addresses')
            .set('Authorization', `Bearer ${session.accessToken}`)
            .expect(200),
        );
      }

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

  it('despacha vários pedidos entre 10 motoboys e reencaminha recusa/expiração', async () => {
    const customer = await registerCustomer(5000);
    const couriers = [];
    for (let i = 0; i < 10; i++) {
      couriers.push(await registerCourier(5100 + i));
    }
    const userIds = [customer.id, ...couriers.map((x) => x.id)];

    try {
      const sessions = [];
      for (let i = 0; i < couriers.length; i++) {
        const courier = couriers[i];
        sessions.push(
          await login(
            courier.email,
            courier.password,
            'dispatch-device-' + i + '-' + courier.tag,
          ),
        );
      }

      for (let i = 0; i < sessions.length; i++) {
        await request(app.getHttpServer())
          .patch('/orders/courier/heartbeat')
          .set(
            'Authorization',
            `Bearer ${sessions[i].accessToken}`,
          )
          .send({
            online: true,
            latitude: -16.449 + i * 0.0002,
            longitude: -39.064 + i * 0.0002,
          })
          .expect(200);
      }

      const available = await prisma.courierProfile.count({
        where: {
          id: { in: couriers.map((x) => x.courierId) },
          presenceStatus: 'AVAILABLE',
        },
      });
      expect(available).toBe(10);

      const address = await prisma.address.create({
        data: {
          userId: customer.id,
          label: 'Carga',
          street: 'Avenida Operacional',
          number: '200',
          neighborhood: 'Centro',
          city: 'Porto Seguro',
          state: 'BA',
          postalCode: '45810000',
          latitude: -16.444,
          longitude: -39.065,
          isDefault: true,
        },
      });

      const orders = [];
      for (let i = 0; i < 5; i++) {
        orders.push(
          await prisma.order.create({
            data: {
              customerId: customer.id,
              addressId: address.id,
              status: 'READY_FOR_PICKUP',
              paymentStatus: 'PAID',
              paymentMethod: 'CARD',
              subtotal: 80 + i,
              deliveryFee: 18.5 + i,
              total: 98.5 + i * 2,
              deliveryPin: String(6000 + i),
            },
          }),
        );
      }

      for (const order of orders) {
        await dispatch.startDispatch(order.id);
      }

      const initialOffers = await (prisma as any).deliveryOffer.findMany({
        where: {
          orderId: { in: orders.map((x) => x.id) },
          status: 'PENDING',
        },
      });

      expect(initialOffers).toHaveLength(5);
      expect(
        new Set(initialOffers.map((x: any) => x.courierId)).size,
      ).toBe(5);

      const sessionByCourier = new Map(
        couriers.map((courier, i) => [
          courier.courierId,
          sessions[i],
        ]),
      );

      const declined = initialOffers[0];
      const declineSession = sessionByCourier.get(declined.courierId)!;

      await request(app.getHttpServer())
        .patch(
          `/orders/${declined.orderId}/courier/reject`,
        )
        .set(
          'Authorization',
          `Bearer ${declineSession.accessToken}`,
        )
        .expect(200);

      await dispatch.dispatchOrder(declined.orderId);

      const replacementAfterDecline =
        await (prisma as any).deliveryOffer.findFirst({
          where: {
            orderId: declined.orderId,
            status: 'PENDING',
          },
          orderBy: { offeredAt: 'desc' },
        });

      expect(replacementAfterDecline).toBeTruthy();
      expect(replacementAfterDecline.courierId).not.toBe(
        declined.courierId,
      );

      const expiring = initialOffers[1];
      await (prisma as any).deliveryOffer.update({
        where: { id: expiring.id },
        data: { expiresAt: new Date(Date.now() - 1000) },
      });

      await (dispatch as any).expireOffers();
      await dispatch.dispatchOrder(expiring.orderId);

      const replacementAfterExpiry =
        await (prisma as any).deliveryOffer.findFirst({
          where: {
            orderId: expiring.orderId,
            status: 'PENDING',
          },
          orderBy: { offeredAt: 'desc' },
        });

      expect(replacementAfterExpiry).toBeTruthy();
      expect(replacementAfterExpiry.courierId).not.toBe(
        expiring.courierId,
      );

      const expiredRow = await (prisma as any).deliveryOffer.findUnique({
        where: { id: expiring.id },
      });
      expect(expiredRow.status).toBe('EXPIRED');

      const declinedRow = await (prisma as any).deliveryOffer.findUnique({
        where: { id: declined.id },
      });
      expect(declinedRow.status).toBe('DECLINED');
    } finally {
      await cleanupUsers(userIds);
    }
  });

});
