import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('./cpfhub.service.js',()=>({CpfHubService:class{}}));
import {AuthService} from './auth.service.js';
describe('Porto Seguro address validation',()=>{
 const local={postalCode:'45810-000',city:'Porto Seguro',state:'BA'};
 function fixture(result:any){const service=Object.create(AuthService.prototype) as AuthService;service.postalCode=vi.fn(async()=>result);return service;}
 it('accepts confirmed local CEPs and normalizes municipality case',async()=>{
  const service=fixture({valid:true});await expect(service.assertPortoSeguroAddress({...local,city:'PORTO SEGURO'})).resolves.toBeUndefined();
  expect(service.postalCode).toHaveBeenCalledWith(local.postalCode);
 });
 it('rejects an outside CEP even when the submitted city claims Porto Seguro',async()=>{
  await expect(fixture({valid:false,reason:'OUTSIDE_SERVICE_AREA'}).assertPortoSeguroAddress({...local,postalCode:'01001000'})).rejects.toThrow('CEP válido de Porto Seguro');
 });
 it('rejects other cities and states even with a local CEP',async()=>{
  const service=fixture({valid:true});await expect(service.assertPortoSeguroAddress({...local,city:'Eunápolis'})).rejects.toThrow('somente');
  await expect(service.assertPortoSeguroAddress({...local,state:'SP'})).rejects.toThrow('somente');expect(service.postalCode).not.toHaveBeenCalled();
 });
 it('does not accept unverified CEPs while the providers are unavailable',async()=>{
  await expect(fixture({valid:false,reason:'LOOKUP_UNAVAILABLE'}).assertPortoSeguroAddress(local)).rejects.toThrow('validar o CEP');
 });
});
