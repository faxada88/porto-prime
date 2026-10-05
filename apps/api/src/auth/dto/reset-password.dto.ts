import { IsEmail, IsString, Length, MinLength } from 'class-validator';

export class ForgotPasswordDto {
  @IsEmail()
  email!: string;
}

export class ResetPasswordDto {
  @IsString()
  @Length(32, 256)
  token!: string;

  @IsString()
  @MinLength(8)
  password!: string;
}
