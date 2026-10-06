import {
  Body,
  Controller,
  Get,
  Headers,
  Post,
  Query,
} from '@nestjs/common';
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
  register(@Body() body: RegisterDto) {
    return this.authService.register(body);
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
  login(@Body() body: LoginDto) {
    return this.authService.login(body);
  }

  @Get('me')
  me(@Headers('authorization') authorization?: string) {
    return this.authService.me(authorization);
  }

  @Post('logout')
  logout(@Headers('authorization') authorization?: string) {
    return this.authService.logout(authorization);
  }
}
