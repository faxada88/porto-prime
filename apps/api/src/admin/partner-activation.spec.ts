import {describe,it,expect,vi} from 'vitest';
import {AdminService} from './admin.service.js';
describe('Partner administrative activation',()=>{
 it('uses the approval flow instead of changing only the access status',async()=>{const service:any=Object.create(AdminService.prototype);service.requireAdmin=vi.fn();service.prisma={user:{findUnique:vi.fn().mockResolvedValue({id:'partner',role:'PARTNER'})}};service.approve=vi.fn().mockResolvedValue({id:'partner',status:'ACTIVE'});await expect(service.updateUserStatus('partner','ACTIVE','token')).resolves.toEqual({id:'partner',status:'ACTIVE'});expect(service.approve).toHaveBeenCalledWith('partner','token');});
});
