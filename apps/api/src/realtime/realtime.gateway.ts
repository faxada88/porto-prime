import { CatalogGateway } from './catalog.gateway.js';
import { OnModuleDestroy } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

@WebSocketGateway({
  cors: { origin: true, credentials: false },
  transports: ['websocket', 'polling'],
  pingInterval: 5_000,
  pingTimeout: 5_000,
})
export class RealtimeGateway
  implements
    OnGatewayInit,
    OnGatewayConnection,
    OnGatewayDisconnect,
    OnModuleDestroy
{
  @WebSocketServer()
  server!: Server;

  private sessionSweep?: NodeJS.Timeout;
  private sweeping = false;

  constructor(
    private readonly auth: AuthService,
    private readonly prisma: PrismaService,
    private readonly catalog?: CatalogGateway,
  ) {}

  private readonly onPresence = (result: any) => {
    const payload = { courierId: result.id, isOnline: result.isOnline, presenceStatus: result.presenceStatus, at: new Date().toISOString() };
    this.emitToRole('ADMIN', 'courier.presence', payload);
    this.emitToCourier(result.id, 'courier.presence', payload);
    for (const offer of result.closed) {
      const closed = { orderId: offer.orderId, offerId: offer.id, reason: 'UNAVAILABLE' };
      this.emitToCourier(result.id, 'delivery.offer.closed', closed);
      this.emitToRole('ADMIN', 'dispatch.offer.closed', closed);
    }
  };

  syncCourierPresence(courierId: string) { return this.auth.syncCourierPresence(courierId); }

  afterInit() {
    this.auth.presenceEvents.on('changed', this.onPresence);
    this.sessionSweep = setInterval(() => {
      void this.disconnectInvalidSessions().catch(() => undefined);
    }, 2_000);
    this.sessionSweep.unref?.();
  }

  onModuleDestroy() {
    this.auth.presenceEvents.off('changed', this.onPresence);
    if (this.sessionSweep) clearInterval(this.sessionSweep);
  }

  private async disconnectInvalidSessions() {
    if (this.sweeping || !this.server) return;
    this.sweeping = true;

    try {
      const sockets = [...this.server.sockets.sockets.values()];
      const sessionIds = [
        ...new Set(
          sockets
            .map((socket) => String(socket.data.sessionId ?? ''))
            .filter(Boolean),
        ),
      ];
      if (!sessionIds.length) return;

      const validRows = await this.prisma.authSession.findMany({
        where: {
          id: { in: sessionIds },
          revokedAt: null,
          refreshExpiresAt: { gt: new Date() },
          user: { OR: [{ status: 'ACTIVE' }, { role: 'COURIER' }] },
        },
        select: { id: true },
      });

      const valid = new Set(validRows.map((row) => row.id));
      for (const socket of sockets) {
        const sessionId = String(socket.data.sessionId ?? '');
        if (sessionId && !valid.has(sessionId)) {
          socket.emit('session.revoked', {
            reason: 'SESSION_INVALID',
          });
          socket.disconnect(true);
        }
      }
    } finally {
      this.sweeping = false;
    }
  }

  async handleConnection(client: Socket) {
    try {
      const token =
        String(client.handshake.auth?.token ?? '').trim() ||
        String(client.handshake.headers.authorization ?? '')
          .replace(/^Bearer\s+/i, '')
          .trim();

      const session = await this.auth.authenticateSession(
        token ? `Bearer ${token}` : undefined, true,
      );
      const user = session.user;

      client.data.sessionId = session.id;
      client.data.userId = user.id;
      client.data.role = user.role;

      await client.join(`user:${user.id}`);
      await client.join(`role:${user.role}`);

      if (user.role === 'COURIER') {
        const courier = await this.prisma.courierProfile.findUnique({
          where: { userId: user.id },
          select: { id: true },
        });
        if (courier) {
          client.data.courierId = courier.id;
          await client.join(`courier:${courier.id}`);
        }
      }

      client.emit('session.ready', {
        sessionId: session.id,
        userId: user.id,
        role: user.role,
      });
    } catch {
      client.disconnect(true);
    }
  }

  async handleDisconnect(client: Socket) {
    const sessionId = client.data.sessionId;
    if (!sessionId || !client.data.courierId) return;
    // Another socket of this same session may already have reconnected.
    if ([...this.server.sockets.sockets.values()].some(socket => socket.id !== client.id && socket.data.sessionId === sessionId)) return;
    try {
      await this.prisma.courierDevicePresence.updateMany({ where: { sessionId }, data: { onlineRequested: false } });
      await this.auth.syncSessionPresence(sessionId);
    } catch { /* The bounded presence sweep retries after transient DB failures. */ }
  }

  @SubscribeMessage('ping')
  ping(
    @ConnectedSocket() client: Socket,
    @MessageBody() body?: Record<string, unknown>,
  ) {
    client.emit('pong', {
      at: new Date().toISOString(),
      echo: body ?? null,
    });
  }

  emitCatalogUpdated(event = 'catalog.updated', store?: { storeOpen: boolean; storeMessage?: string; updatedAt?: unknown }) {
    const payload = { at: new Date().toISOString(), ...(store ? { storeOpen: store.storeOpen, storeMessage: store.storeMessage, updatedAt: store.updatedAt } : {}) };
    this.server?.emit(event, payload);
    this.catalog?.updated(event, payload);
  }

  emitDemandUpdated(payload: {enabled: boolean; revision: number; updatedAt: unknown}) {
    this.catalog?.updated('demand.updated', {at:new Date().toISOString(), ...payload});
  }

  emitToUser(userId: string, event: string, payload: unknown) {
    this.server?.to(`user:${userId}`).emit(event, payload);
  }

  emitToRole(role: string, event: string, payload: unknown) {
    this.server?.to(`role:${role}`).emit(event, payload);
  }

  emitToCourier(courierId: string, event: string, payload: unknown) {
    this.server?.to(`courier:${courierId}`).emit(event, payload);
  }

  emitOrderUpdated(order: {
    id: string;
    customerId?: string | null;
    courierId?: string | null;
    status?: unknown;
  }) {
    const payload = {
      orderId: order.id,
      status: order.status,
      at: new Date().toISOString(),
    };

    if (order.customerId) {
      this.emitToUser(order.customerId, 'order.updated', payload);
    }
    if (order.courierId) {
      this.emitToCourier(order.courierId, 'order.updated', payload);
    }
    this.emitToRole('ADMIN', 'order.updated', payload);
  }
}

