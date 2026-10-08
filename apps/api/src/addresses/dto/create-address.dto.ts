import { IsBoolean, IsNotEmpty, IsOptional, IsPostalCode, IsString, IsNumber, Min, Max } from 'class-validator';

export class CreateAddressDto {
  @IsOptional() @IsNumber() @Min(-90) @Max(90) latitude?: number;
  @IsOptional() @IsNumber() @Min(-180) @Max(180) longitude?: number;
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
