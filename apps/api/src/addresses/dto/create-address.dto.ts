import { IsBoolean, IsNotEmpty, IsOptional, IsPostalCode, IsString } from 'class-validator';

export class CreateAddressDto {
  @IsOptional() @IsString() label?: string;
  @IsString() @IsNotEmpty() street!: string;
  @IsString() @IsNotEmpty() number!: string;
  @IsOptional() @IsString() complement?: string;
  @IsString() @IsNotEmpty() neighborhood!: string;
  @IsString() @IsNotEmpty() city!: string;
  @IsString() @IsNotEmpty() state!: string;
  @IsPostalCode('BR') postalCode!: string;
  @IsOptional() @IsBoolean() isDefault?: boolean;
}
