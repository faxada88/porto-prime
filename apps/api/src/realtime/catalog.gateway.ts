import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import type { Server } from 'socket.io';
// Public read-only channel: no identity, order, payment or customer data.
@WebSocketGateway({ namespace: '/catalog', cors: { origin: true }, transports: ['websocket', 'polling'] })
export class CatalogGateway {
  @WebSocketServer() server!: Server;
  updated(event: string, payload: { at: string; storeOpen?: boolean; storeMessage?: string; updatedAt?: unknown }) { this.server?.emit(event, payload); }
}
