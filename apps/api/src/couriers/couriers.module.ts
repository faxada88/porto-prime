import { Module } from '@nestjs/common';
import { CouriersController } from './couriers.controller.js';
import { CouriersService } from './couriers.service.js';
import { AuthModule } from '../auth/auth.module.js';
@Module({imports:[AuthModule],controllers:[CouriersController],providers:[CouriersService]})
export class CouriersModule {}