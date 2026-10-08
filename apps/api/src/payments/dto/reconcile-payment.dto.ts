import { IsNotEmpty, IsString } from 'class-validator';

export class ReconcilePaymentDto {
  @IsString()
  @IsNotEmpty()
  orderId!: string;
}
