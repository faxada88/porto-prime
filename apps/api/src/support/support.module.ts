import {PublicSupportController} from './public-support.controller.js';
import {PublicSupportService} from './public-support.service.js';
import {DeliveryChatService} from './delivery-chat.service.js';
import {Module} from '@nestjs/common';
import {AuthModule} from '../auth/auth.module.js';
import {SupportController} from './support.controller.js';
import {SupportService} from './support.service.js';
@Module({imports:[AuthModule],controllers:[SupportController,PublicSupportController],providers:[SupportService,DeliveryChatService,PublicSupportService]})
export class SupportModule {}
