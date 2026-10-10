import {Body,Controller,Get,Headers,Patch} from '@nestjs/common';
import {OperationDemandService} from './operation-demand.service.js';
@Controller()
export class OperationDemandController {
 constructor(private readonly service:OperationDemandService){}
 @Get('operations/demand')
 publicRead(){return this.service.publicRead();}
 @Get('admin/operations/demand')
 admin(@Headers('authorization') authorization?:string){return this.service.read(authorization,'ADMIN');}
 @Get('couriers/operations/demand')
 courier(@Headers('authorization') authorization?:string){return this.service.read(authorization,'COURIER');}
 @Patch('admin/operations/demand')
 set(@Body() body:unknown,@Headers('authorization') authorization?:string){return this.service.set(body,authorization);}
}
