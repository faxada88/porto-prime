import {describe,it,expect,vi} from 'vitest';
import {PartnersService} from './partners.service.js';
const fixture=(role='ADMIN')=>{const db:any={partnerProfile:{findFirst:vi.fn().mockResolvedValue(null)},$transaction:vi.fn()},auth:any={authenticate:vi.fn().mockResolvedValue({id:'actor',role}),availability:vi.fn().mockResolvedValue({valid:true})};return {db,service:new PartnersService(db,auth,{} as any,{} as any)};};
describe('Partner profile authorization and editing',()=>{
 it('blocks customer access to admin records',async()=>{const {service}=fixture('CUSTOMER');await expect(service.adminRecord('other','token')).rejects.toThrow('Acesso exclusivo');});
 it('blocks admin access to the partner self endpoint',async()=>{const {service}=fixture();await expect(service.mine('token')).rejects.toThrow('Acesso exclusivo');});
 for(const percent of [-1,101,NaN,5.001,'5'])it('rejects invalid commission '+String(percent),async()=>{const {service,db}=fixture();await expect(service.edit('p',{commissionPercent:percent},'token')).rejects.toThrow('Comissão');expect(db.$transaction).not.toHaveBeenCalled();});
 it('rejects client attempts to change approval or balances',async()=>{const {service}=fixture();await expect(service.edit('p',{approved:true},'token')).rejects.toThrow('Campo não permitido');});
 it('does not reveal disabled partners in public lookups',async()=>{const {service,db}=fixture();await expect(service.publicReferral('PP-12345678')).rejects.toThrow('Indicação indisponível');expect(db.partnerProfile.findFirst).toHaveBeenCalledWith(expect.objectContaining({where:{referralCode:'PP-12345678',approved:true,user:{status:'ACTIVE',role:'PARTNER'}}}));});
 it('rejects malformed codes without querying the database',async()=>{const {service,db}=fixture();await expect(service.publicReferral('../invalid')).rejects.toThrow();expect(db.partnerProfile.findFirst).not.toHaveBeenCalled();});
});
