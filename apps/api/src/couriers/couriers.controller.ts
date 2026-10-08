import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { CouriersService } from './couriers.service.js';

@Controller('couriers')
export class CouriersController {
  constructor(private readonly service: CouriersService) {}

  @Post('application/status')
  status(@Body('document') document: string) {
    return this.service.status(document);
  }

  @Post('application/requirements/:id/respond')
  publicRespond(
    @Param('id') id: string,
    @Body() body: { document: string; response: string },
  ) {
    return this.service.publicRespond(
      id,
      body.document,
      body.response,
    );
  }

  @Get('application/me')
  me(@Headers('authorization') authorization?: string) {
    return this.service.me(authorization);
  }

  @Patch('profile/photo')
  photo(@Body('photo') photo: string, @Headers('authorization') authorization?: string) {
    return this.service.savePhoto(photo, authorization);
  }

  @Patch('application')
  update(
    @Body() body: Record<string, unknown>,
    @Headers('authorization') authorization?: string,
  ) {
    return this.service.update(body, authorization);
  }

  @Post('requirements/:id/respond')
  respond(
    @Param('id') id: string,
    @Body('response') response: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.service.respond(
      id,
      response,
      authorization,
    );
  }
}
