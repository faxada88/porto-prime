import { Body, Controller, Get, Headers, Post, Query } from '@nestjs/common';
import { AuthService } from './auth.service.js';
import { LoginDto } from './dto/login.dto.js';
import { RegisterDto } from './dto/register.dto.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Get('availability')
  availability(@Query('field') field: string, @Query('value') value: string) {
    return this.authService.availability(field, value);
  }

  @Post('register')
  register(@Body() body: RegisterDto) { return this.authService.register(body); }

  @Post('login')
  login(@Body() body: LoginDto) { return this.authService.login(body); }

  @Get('me')
  me(@Headers('authorization') authorization?: string) { return this.authService.me(authorization); }

  @Post('logout')
  logout(@Headers('authorization') authorization?: string) { return this.authService.logout(authorization); }
}
