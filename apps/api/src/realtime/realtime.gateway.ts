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
  ) {}

  afterInit() {
    this.sessionSweep = setInterval(() => {
      void this.disconnectInvalidSessions();
    }, 30_000);
    this.sessionSweep.unref?.();
  }

  onModuleDestroy() {
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
          user: { status: 'ACTIVE' },
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
        token ? `Bearer ${token}` : undefined,
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

  handleDisconnect(_client: Socket) {
    // O heartbeat persistido por sessão/dispositivo é a fonte de verdade
    // para presença operacional. Oscilações rápidas do socket não forçam
    // OFFLINE imediatamente.
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
