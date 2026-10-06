import { Global, Module } from '@nestjs/common';
import { DispatchService } from './dispatch.service.js';

@Global()
@Module({
  providers: [DispatchService],
  exports: [DispatchService],
})
export class DispatchModule {}
