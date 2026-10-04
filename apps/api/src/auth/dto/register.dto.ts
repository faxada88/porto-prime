import { IsEmail, IsEnum, IsNotEmpty, IsObject, IsOptional, IsString, MinLength } from 'class-validator';
import { UserRole } from '../../generated/prisma/client.js';

export class RegisterDto {
  @IsString() @IsNotEmpty() name!: string;
  @IsEmail() email!: string;
  @IsString() @IsNotEmpty() phone!: string;
  @IsString() @MinLength(8) password!: string;
  @IsEnum(UserRole) role!: UserRole;
  @IsOptional() @IsString() businessName?: string;
  @IsOptional() @IsString() document?: string;
  @IsOptional() @IsObject() profileData?: Record<string, unknown>;
}
