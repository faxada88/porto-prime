import { IsNotEmpty, IsString, IsUrl } from 'class-validator';

export class CreateCheckoutDto {
  @IsString()
  @IsNotEmpty()
  orderId!: string;

  @IsUrl({ require_tld: false })
  successUrl!: string;

  @IsUrl({ require_tld: false })
  cancelUrl!: string;
}
