import { IsString, Matches } from 'class-validator';

export class CourierCpfDto {
  @IsString()
  @Matches(/^(?:\d{11}|\d{3}\.\d{3}\.\d{3}-\d{2})$/)
  cpf!: string;

  @IsString()
  @Matches(/^(?:\d{8}|\d{2}\/\d{2}\/\d{4})$/)
  birthDate!: string;
}
