import {Module} from '@nestjs/common';
import {AuthModule} from '../auth/auth.module.js';
import {ItemAvailabilityController} from './item-availability.controller.js';
import {ItemAvailabilityService} from './item-availability.service.js';
@Module({imports:[AuthModule],controllers:[ItemAvailabilityController],providers:[ItemAvailabilityService]})
export class ItemAvailabilityModule{}
