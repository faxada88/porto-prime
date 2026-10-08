import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller.js';
import { CpfHubService } from './cpfhub.service.js';
import { AuthService } from './auth.service.js';

@Module({
  controllers: [AuthController],
  providers: [AuthService, CpfHubService],
  exports: [AuthService],
})
export class AuthModule {}
