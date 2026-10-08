import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  Post,
  Query,
  Req,
} from '@nestjs/common';
import type { Request } from 'express';
import { CourierCpfDto } from './dto/courier-cpf.dto.js';
import { AuthService } from './auth.service.js';
import { LoginDto } from './dto/login.dto.js';
import { BootstrapAdminDto } from './dto/bootstrap-admin.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import {
  ForgotPasswordDto,
  ResetPasswordDto,
} from './dto/reset-password.dto.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Get('availability')
  availability(
    @Query('field') field: string,
    @Query('value') value: string,
  ) {
    return this.authService.availability(field, value);
  }

  @Post('courier-cpf')
  courierCpf(@Body() body: CourierCpfDto, @Req() request: Request) {
    return this.authService.lookupCourierCpf(body.cpf, body.birthDate, request.ip ?? request.socket.remoteAddress ?? 'unknown');
  }

  @Get('postal-code')
  postalCode(@Query('cep') cep: string) {
    return this.authService.postalCode(cep);
  }

  @Get('bootstrap-admin')
  bootstrapAdminStatus() {
    return this.authService.bootstrapStatus();
  }

  @Post('bootstrap-admin')
  bootstrapAdmin(@Body() body: BootstrapAdminDto) {
    return this.authService.bootstrapAdmin(body);
  }

  @Post('register')
  register(@Body() body: RegisterDto, @Req() request: Request) {
    return this.authService.register(body, request.ip ?? request.socket.remoteAddress ?? 'unknown');
  }

  @Post('forgot-password')
  forgotPassword(@Body() body: ForgotPasswordDto) {
    return this.authService.forgotPassword(body);
  }

  @Post('reset-password')
  resetPassword(@Body() body: ResetPasswordDto) {
    return this.authService.resetPassword(body);
  }

  @Post('login')
  login(
    @Body() body: LoginDto,
    @Headers('x-device-id') deviceId?: string,
    @Headers('x-device-name') deviceName?: string,
    @Headers('user-agent') userAgent?: string,
  ) {
    return this.authService.login(body, {
      deviceId,
      deviceName,
      userAgent,
    });
  }

  @Post('refresh')
  refresh(
    @Body('refreshToken') refreshToken: string,
    @Headers('x-device-id') deviceId?: string,
    @Headers('x-device-name') deviceName?: string,
    @Headers('user-agent') userAgent?: string,
  ) {
    return this.authService.refresh(refreshToken, {
      deviceId,
      deviceName,
      userAgent,
    });
  }

  @Get('me')
  me(@Headers('authorization') authorization?: string) {
    return this.authService.me(authorization);
  }

  @Get('sessions')
  sessions(@Headers('authorization') authorization?: string) {
    return this.authService.sessions(authorization);
  }

  @Delete('sessions/:id')
  revokeSession(
    @Param('id') id: string,
    @Headers('authorization') authorization?: string,
  ) {
    return this.authService.revokeSession(id, authorization);
  }

  @Post('logout')
  logout(@Headers('authorization') authorization?: string) {
    return this.authService.logout(authorization);
  }

  @Post('logout-all')
  logoutAll(@Headers('authorization') authorization?: string) {
    return this.authService.logoutAll(authorization);
  }
}
