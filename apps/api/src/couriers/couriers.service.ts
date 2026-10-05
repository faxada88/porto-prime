import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { UserRole } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { AuthService } from '../auth/auth.service.js';
@Injectable()
export class CouriersService {
 constructor(private readonly prisma:PrismaService,private readonly auth:AuthService){}
 private digits(v:unknown){return String(v??'').replace(/\D/g,'');}
 private safe(p:any){return {id:p.id,name:p.user.name,document:p.document,approvalStatus:p.approvalStatus,cnh:p.cnh,cnhCategory:p.cnhCategory,vehicleBrand:p.vehicleBrand,vehicleModel:p.vehicleModel,vehiclePlate:p.vehiclePlate,vehicleYear:p.vehicleYear,requirements:p.requirements??[],updatedAt:p.updatedAt};}
 async status(document:string){
  const cpf=this.digits(document); if(cpf.length!==11) throw new BadRequestException('Informe um CPF válido com 11 dígitos');
  const p=await (this.prisma as any).courierProfile.findUnique({where:{document:cpf},include:{user:{select:{name:true}},requirements:{where:{status:{in:['OPEN','ANSWERED']}},orderBy:{requestedAt:'desc'}}}});
  if(!p) throw new NotFoundException('Nenhuma candidatura encontrada para este CPF');
  const parts=p.user.name.trim().split(/\s+/); const masked=parts.length>1?parts[0]+' '+parts.at(-1)!.slice(0,1)+'.':parts[0];
  return {found:true,name:masked,document:'***.***.***-'+cpf.slice(-2),approvalStatus:p.approvalStatus,hasPendingRequirements:p.requirements.some((r:any)=>r.status==='OPEN'),requirements:p.requirements.map((r:any)=>({id:r.id,title:r.title,description:r.description,status:r.status,requestedAt:r.requestedAt}))};
 }
 async profile(authorization?:string){const u=await this.auth.authenticate(authorization);if(u.role!==UserRole.COURIER)throw new BadRequestException('Conta não é de motoboy');const p=await (this.prisma as any).courierProfile.findUnique({where:{userId:u.id},include:{user:{select:{name:true}},requirements:{orderBy:{requestedAt:'desc'}}}});if(!p)throw new NotFoundException('Perfil do motoboy não encontrado');return p;}
 async me(authorization?:string){return this.safe(await this.profile(authorization));}
 async update(body:Record<string,unknown>,authorization?:string){const p=await this.profile(authorization);const allowed:any={};for(const k of ['cnh','cnhCategory','vehicleBrand','vehicleModel','vehiclePlate'])if(body[k]!=null)allowed[k]=String(body[k]).trim();if(body.vehicleYear!=null)allowed.vehicleYear=Number(body.vehicleYear);const updated=await (this.prisma as any).courierProfile.update({where:{id:p.id},data:allowed,include:{user:{select:{name:true}},requirements:{orderBy:{requestedAt:'desc'}}}});return this.safe(updated);}
 async respond(id:string,response:string,authorization?:string){if(!response?.trim())throw new BadRequestException('Escreva a resposta ou informação solicitada');const p=await this.profile(authorization);const r=await (this.prisma as any).courierRequirement.findFirst({where:{id,courierId:p.id}});if(!r)throw new NotFoundException('Pendência não encontrada');return (this.prisma as any).courierRequirement.update({where:{id},data:{response:response.trim(),status:'ANSWERED',answeredAt:new Date()}});}
}