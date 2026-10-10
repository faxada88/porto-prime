import { Type } from 'class-transformer';
import { ArrayMinSize, IsArray, IsInt, IsNotEmpty, IsOptional, IsNumber, IsString, Min, ValidateNested } from 'class-validator';

export class CreateOrderItemDto {
  @IsString()
  @IsNotEmpty()
  productId!: string;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  quantity!: number;
}

export class CreateOrderDto {
  @IsOptional() @IsNumber() @Min(0) expectedTotal?: number;
  @IsOptional() @IsInt() @Min(1) pricingRevision?: number;
  @IsOptional() @IsNumber() @Min(0) expectedDeliveryFee?: number;
  @IsString()
  @IsNotEmpty()
  addressId!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items!: CreateOrderItemDto[];
}
