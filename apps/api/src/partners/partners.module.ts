import {Module} from '@nestjs/common';
import {AuthModule} from '../auth/auth.module.js';
import {PartnersService} from './partners.service.js';
import {PartnersController} from './partners.controller.js';
@Module({imports:[AuthModule],providers:[PartnersService],controllers:[PartnersController]})
export class PartnersModule{}
