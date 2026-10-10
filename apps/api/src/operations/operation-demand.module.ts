import {Module} from '@nestjs/common';
import {AuthModule} from '../auth/auth.module.js';
import {OperationDemandController} from './operation-demand.controller.js';
import {OperationDemandService} from './operation-demand.service.js';
@Module({imports:[AuthModule],controllers:[OperationDemandController],providers:[OperationDemandService]})
export class OperationDemandModule {}
