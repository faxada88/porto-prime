import {BadRequestException,NotFoundException} from '@nestjs/common';
const fields=['name','email','phone','cpf','birthDate','postalCode','cep','street','number','complement','neighborhood','city','state'];
const protectedField=/(password|senha|token|secret|role|status|verified|approval|balance|credit|payment|commission|permission|session)/i;
function validCpf(value:string){if(!/^\d{11}$/.test(value)||/^(\d)\1{10}$/.test(value))return false;return [9,10].every(n=>{let sum=0;for(let i=0;i<n;i++)sum+=Number(value[i])*(n+1-i);const digit=(sum*10)%11;return Number(value[n])===(digit===10?0:digit);});}
export async function editCustomerProfile(db:any,id:string,body:Record<string,unknown>){
 if(!body||typeof body!=='object'||Object.keys(body).some(k=>!fields.includes(k)&&k!=='extraData'))throw new BadRequestException('Campo não permitido para edição');
 const input:Record<string,string>={};
 for(const [k,v]of Object.entries(body)){if(k==='extraData')continue;if(typeof v!=='string'||v.trim().length>250)throw new BadRequestException('Dados de cadastro inválidos');input[k]=v.trim();}
 if('name'in input&&input.name.length<2)throw new BadRequestException('Informe o nome completo');
 if('email'in input){input.email=input.email.toLowerCase();if(!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(input.email))throw new BadRequestException('E-mail inválido');}
 if('phone'in input){input.phone=input.phone.replace(/\D/g,'');if(input.phone&&input.phone.length!==11)throw new BadRequestException('Telefone inválido');}
 if('cpf'in input){input.cpf=input.cpf.replace(/\D/g,'');if(!validCpf(input.cpf))throw new BadRequestException('CPF inválido');}
 if(input.birthDate){const raw=input.birthDate;const iso=/^\d{2}\/\d{2}\/\d{4}$/.test(raw)?raw.split('/').reverse().join('-'):raw;const date=new Date(iso+'T00:00:00Z');if(!/^\d{4}-\d{2}-\d{2}$/.test(iso)||!Number.isFinite(date.getTime())||date.toISOString().slice(0,10)!==iso||date>new Date())throw new BadRequestException('Data de nascimento inválida');}
 try{return await db.$transaction(async(tx:any)=>{
  await tx.$queryRawUnsafe('SELECT pg_advisory_xact_lock(hashtext($1))::text AS profile_lock','customer-profile-edits');
  const user=await tx.user.findUnique({where:{id},include:{customerProfile:true}});if(!user||user.role!=='CUSTOMER')throw new NotFoundException('Cliente não encontrado');
  if(input.cpf){const duplicate=await tx.customerProfile.findFirst({where:{userId:{not:id},onboardingData:{path:['cpf'],equals:input.cpf}},select:{id:true}});if(duplicate)throw new BadRequestException('Este CPF já possui cadastro');}
  const stored=user.customerProfile?.onboardingData||{};const extra=body.extraData??{};
  if(!extra||typeof extra!=='object'||Array.isArray(extra)||JSON.stringify(extra).length>20000)throw new BadRequestException('Dados adicionais inválidos');
  for(const [k,v]of Object.entries(extra)){if(!Object.prototype.hasOwnProperty.call(stored,k)||fields.includes(k)||protectedField.test(k)||typeof v!==typeof stored[k]||Array.isArray(v)!==Array.isArray(stored[k]))throw new BadRequestException('Campo adicional não permitido ou formato inválido');if(v&&typeof v==='object'&&Object.keys(v).some(protectedField.test.bind(protectedField)))throw new BadRequestException('Campo adicional protegido');}
  const account:Record<string,string|null>={};for(const k of ['name','email','phone'])if(k in input)account[k]=input[k]||null;
  if(Object.keys(account).length)await tx.user.update({where:{id},data:account});
  const onboardingData={...stored,...extra,...input};await tx.customerProfile.upsert({where:{userId:id},create:{userId:id,onboardingData},update:{onboardingData}});
  return {success:true};
 });}catch(e:any){if(e.code==='P2002')throw new BadRequestException('Este e-mail ou telefone já está cadastrado');throw e;}
}
export async function editCustomerAddress(db:any,id:string,addressId:string,data:any){
 return db.$transaction(async(tx:any)=>{
  const customer=await tx.user.findUnique({where:{id},select:{role:true}});if(customer?.role!=='CUSTOMER')throw new NotFoundException('Cliente não encontrado');
  const found=await tx.address.findFirst({where:{id:addressId,userId:id}});if(!found)throw new NotFoundException('Endereço não encontrado');
  const moved=['street','number','neighborhood','city','state','postalCode'].some(k=>String(data[k]).replace(k==='postalCode'?/\D/g:/\s/g,'').toLowerCase()!==String(found[k]).replace(k==='postalCode'?/\D/g:/\s/g,'').toLowerCase());
  if(data.isDefault)await tx.address.updateMany({where:{userId:id,id:{not:addressId}},data:{isDefault:false}});
  return tx.address.update({where:{id:addressId},data:{label:data.label?.trim()||null,street:data.street.trim(),number:data.number.trim(),complement:data.complement?.trim()||null,neighborhood:data.neighborhood.trim(),city:data.city.trim(),state:data.state.trim().toUpperCase(),postalCode:data.postalCode.replace(/\D/g,''),isDefault:data.isDefault??found.isDefault,...(moved?{latitude:null,longitude:null,locationConfirmed:false,locationRef:null}:{})}});
 });
}
