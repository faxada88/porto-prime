import { BadRequestException, ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { createHash, randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';
import { UserRole, UserStatus } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { LoginDto } from './dto/login.dto.js';
import { RegisterDto } from './dto/register.dto.js';
@Injectable()
export class AuthService {
 constructor(private readonly prisma:PrismaService){}
 private hashPassword(p:string){const s=randomBytes(16).toString('hex');return `scrypt:${s}:${scryptSync(p,s,64).toString('hex')}`;}
 private verifyPassword(p:string,stored:string){const [a,s,h]=stored.split(':');if(a!=='scrypt'||!s||!h)return false;const c=scryptSync(p,s,64),e=Buffer.from(h,'hex');return c.length===e.length&&timingSafeEqual(c,e);}
 private tokenHash(t:string){return createHash('sha256').update(t).digest('hex');}
 private publicUser(u:any){return {id:u.id,name:u.name,email:u.email,phone:u.phone,role:u.role,status:u.status};}
 private digits(v?:string){return (v??'').replace(/\D/g,'');}
 async register(data:RegisterDto){
  if(data.role===UserRole.ADMIN)throw new BadRequestException('Cadastro de administrador não é permitido');
  if(data.role===UserRole.PARTNER&&!data.businessName?.trim())throw new BadRequestException('Nome do estabelecimento é obrigatório');
  const email=data.email.trim().toLowerCase(), phone=this.digits(data.phone)||null;
  const exists=await this.prisma.user.findFirst({where:{OR:[{email},...(phone?[{phone}]:[])]}});if(exists)throw new ConflictException(exists.email===email?'E-mail já cadastrado':'Telefone já cadastrado');
  let cpf:string|null=null;
  if(data.role===UserRole.COURIER){cpf=this.digits(data.document);if(cpf.length!==11)throw new BadRequestException('CPF do motoboy deve ter 11 dígitos');if(!data.cnh?.trim())throw new BadRequestException('Número da CNH é obrigatório');if(!data.vehicleModel?.trim())throw new BadRequestException('Modelo da moto é obrigatório');const used=await (this.prisma as any).courierProfile.findUnique({where:{document:cpf}});if(used)throw new ConflictException('CPF já possui candidatura');}
  const pending=data.role===UserRole.COURIER||data.role===UserRole.PARTNER;
  const user=await (this.prisma as any).user.create({data:{name:data.name.trim(),email,phone,passwordHash:this.hashPassword(data.password),role:data.role,status:pending?UserStatus.PENDING:UserStatus.ACTIVE,
   customerProfile:data.role===UserRole.CUSTOMER?{create:{}}:undefined,
   courierProfile:data.role===UserRole.COURIER?{create:{document:cpf,cnh:data.cnh!.trim(),cnhCategory:data.cnhCategory?.trim()||'A',vehicleBrand:data.vehicleBrand?.trim()||null,vehicleModel:data.vehicleModel!.trim(),vehiclePlate:data.vehiclePlate?.trim().toUpperCase()||null,vehicleYear:data.vehicleYear||null}}:undefined,
   partnerProfile:data.role===UserRole.PARTNER?{create:{businessName:data.businessName!.trim(),document:data.document?.trim()||null}}:undefined}});
  return this.publicUser(user);
 }
 async login(data:LoginDto){const u=await this.prisma.user.findUnique({where:{email:data.email.trim().toLowerCase()}});if(!u||!this.verifyPassword(data.password,u.passwordHash))throw new UnauthorizedException('E-mail ou senha inválidos');if(u.status===UserStatus.BLOCKED||u.status===UserStatus.SUSPENDED)throw new UnauthorizedException('Conta indisponível');const token=randomBytes(48).toString('base64url'),expiresAt=new Date(Date.now()+30*24*60*60*1000);await this.prisma.authSession.create({data:{userId:u.id,tokenHash:this.tokenHash(token),expiresAt}});return {token,expiresAt,user:this.publicUser(u)};}
 async authenticate(a?:string){const t=a?.startsWith('Bearer ')?a.slice(7).trim():'';if(!t)throw new UnauthorizedException('Autenticação obrigatória');const s=await this.prisma.authSession.findUnique({where:{tokenHash:this.tokenHash(t)},include:{user:true}});if(!s||s.expiresAt<=new Date())throw new UnauthorizedException('Sessão inválida ou expirada');if(s.user.status===UserStatus.BLOCKED||s.user.status===UserStatus.SUSPENDED)throw new UnauthorizedException('Conta indisponível');return s.user;}
 async me(a?:string){return this.publicUser(await this.authenticate(a));}
 async logout(a?:string){const t=a?.startsWith('Bearer ')?a.slice(7).trim():'';if(t)await this.prisma.authSession.deleteMany({where:{tokenHash:this.tokenHash(t)}});return {success:true};}
}