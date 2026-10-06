import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
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
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly auth: AuthService,
    private readonly prisma: PrismaService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token =
        String(client.handshake.auth?.token ?? '').trim() ||
        String(client.handshake.headers.authorization ?? '')
          .replace(/^Bearer\s+/i, '')
          .trim();

      const user = await this.auth.authenticate(
        token ? `Bearer ${token}` : undefined,
      );

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
        userId: user.id,
        role: user.role,
      });
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(_client: Socket) {
    // Presença operacional é controlada por heartbeat persistido no banco.
    // Desconectar o socket não muda o estado imediatamente para evitar
    // falsos OFFLINE em reconexões rápidas de rede.
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
