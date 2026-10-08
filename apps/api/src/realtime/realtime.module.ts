import { CatalogGateway } from './catalog.gateway.js';
import { Global, Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { RealtimeGateway } from './realtime.gateway.js';

@Global()
@Module({
  imports: [AuthModule],
  providers: [CatalogGateway, RealtimeGateway],
  exports: [RealtimeGateway],
})
export class RealtimeModule {}
