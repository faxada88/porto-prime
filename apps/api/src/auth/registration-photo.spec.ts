import {describe,it,expect,vi} from 'vitest';
vi.mock('../prisma/prisma.service.js',()=>({PrismaService:class{}}));
vi.mock('./cpfhub.service.js',()=>({CpfHubService:class{}}));
vi.mock('./dto/login.dto.js',()=>({LoginDto:class{}}));
vi.mock('./dto/bootstrap-admin.dto.js',()=>({BootstrapAdminDto:class{}}));
vi.mock('./dto/register.dto.js',()=>({RegisterDto:class{}}));
vi.mock('./dto/reset-password.dto.js',()=>({ForgotPasswordDto:class{},ResetPasswordDto:class{}}));
vi.mock('../generated/prisma/client.js',()=>({Prisma:{},UserRole:{ADMIN:'ADMIN',CUSTOMER:'CUSTOMER',COURIER:'COURIER',PARTNER:'PARTNER'},UserStatus:{PENDING:'PENDING',ACTIVE:'ACTIVE'}}));
import {AuthService} from './auth.service.js';
const photo='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=';
function fixture(){const prisma:any={user:{findFirst:async()=>null,create:vi.fn(async({data}:any)=>({id:'u',...data}))},courierProfile:{findFirst:async()=>null}};const cpf:any={lookup:vi.fn(async()=>({regular:true,name:'Verified Name',cpf:'52998224725',birthDate:'1990-01-01',situation:'REGULAR'}))};return{prisma,cpf,service:new AuthService(prisma,cpf)}};
const base:any={role:'COURIER',name:'Name',email:'user@example.test',phone:'73999999999',password:'Password123!',document:'52998224725',cnh:'12345678901',vehicleModel:'CG 160',profileData:{birthDate:'1990-01-01'}};
describe('Photo required at registration',()=>{
 it('rejects a missing photo before CPF lookup and user creation',async()=>{const f=fixture();await expect(f.service.register(base)).rejects.toThrow('selfie');expect(f.cpf.lookup).not.toHaveBeenCalled();expect(f.prisma.user.create).not.toHaveBeenCalled()});
 it('rejects invalid photo before charging a CPF lookup',async()=>{const f=fixture();await expect(f.service.register({...base,profileData:{...base.profileData,profilePhoto:'invalid'}})).rejects.toThrow('JPEG');expect(f.cpf.lookup).not.toHaveBeenCalled()});
 it('stores a valid photo with the pending courier registration',async()=>{const f=fixture();await f.service.register({...base,profileData:{...base.profileData,profilePhoto:photo}});const data=f.prisma.user.create.mock.calls[0][0].data;expect(data.status).toBe('PENDING');expect(data.courierProfile.create.onboardingData.profilePhoto).toBe(photo)});
 it('keeps customer registration independent of courier photos',async()=>{const f=fixture();await f.service.register({...base,role:'CUSTOMER',profileData:{}});expect(f.prisma.user.create).toHaveBeenCalled();expect(f.cpf.lookup).not.toHaveBeenCalled()});
});
