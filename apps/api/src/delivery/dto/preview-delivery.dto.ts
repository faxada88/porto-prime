import { IsBoolean, IsNotEmpty, IsOptional, IsPostalCode, IsString, IsNumber, Min, Max, MaxLength } from 'class-validator';

export class PreviewDeliveryDto {
  @IsOptional() @IsString() @MaxLength(64) locationRef?: string;
  @IsOptional() @IsNumber() @Min(-90) @Max(90) latitude?: number;
  @IsOptional() @IsNumber() @Min(-180) @Max(180) longitude?: number;
  @IsOptional() @IsString() label?: string;
  @IsString() @IsNotEmpty() street!: string;
  @IsString() number: string = '';
  @IsOptional() @IsString() complement?: string;
  @IsString() neighborhood: string = '';
  @IsString() @IsNotEmpty() city!: string;
  @IsString() @IsNotEmpty() state!: string;
  @IsPostalCode('BR') postalCode!: string;
  @IsOptional() @IsBoolean() isDefault?: boolean;
}
