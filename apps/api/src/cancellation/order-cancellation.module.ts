import {Module} from '@nestjs/common';
import {AuthModule} from '../auth/auth.module.js';
import {OrderCancellationService} from './order-cancellation.service.js';
import {OrderCancellationController} from './order-cancellation.controller.js';
@Module({imports:[AuthModule],providers:[OrderCancellationService],controllers:[OrderCancellationController]})
export class OrderCancellationModule{}
