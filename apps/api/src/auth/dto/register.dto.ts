import { IsEmail, IsEnum, IsInt, IsNotEmpty, IsObject, IsOptional, IsString, Min, MinLength } from 'class-validator';
import { Type } from 'class-transformer';
import { UserRole } from '../../generated/prisma/client.js';
export class RegisterDto {
 @IsString() @IsNotEmpty() name!:string;
 @IsEmail() email!:string;
 @IsOptional() @IsString() phone?:string;
 @IsString() @MinLength(8) password!:string;
 @IsEnum(UserRole) role!:UserRole;
 @IsOptional() @IsString() businessName?:string;
 @IsOptional() @IsString() document?:string;
 @IsOptional() @IsString() cnh?:string;
 @IsOptional() @IsString() cnhCategory?:string;
 @IsOptional() @IsString() vehicleBrand?:string;
 @IsOptional() @IsString() vehicleModel?:string;
 @IsOptional() @IsString() vehiclePlate?:string;
 @IsOptional() @Type(()=>Number) @IsInt() @Min(1980) vehicleYear?:number;
 @IsOptional() @IsObject() profileData?:Record<string,unknown>;
}