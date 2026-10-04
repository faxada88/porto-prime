import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import {
  createHash,
  randomBytes,
  scryptSync,
  timingSafeEqual,
} from 'node:crypto';
import { Prisma, UserRole, UserStatus } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { LoginDto } from './dto/login.dto.js';
import { RegisterDto } from './dto/register.dto.js';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  private hashPassword(password: string) {
    const salt = randomBytes(16).toString('hex');
    const hash = scryptSync(password, salt, 64).toString('hex');
    return `scrypt:${salt}:${hash}`;
  }

  private verifyPassword(password: string, stored: string) {
    const [algorithm, salt, hash] = stored.split(':');
    if (algorithm !== 'scrypt' || !salt || !hash) return false;
    const candidate = scryptSync(password, salt, 64);
    const expected = Buffer.from(hash, 'hex');
    return candidate.length === expected.length && timingSafeEqual(candidate, expected);
  }

  private tokenHash(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private publicUser(user: {
    id: string;
    name: string;
    email: string;
    phone: string | null;
    role: UserRole;
    status: UserStatus;
  }) {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
    };
  }

  async register(data: RegisterDto) {
    if (data.role === UserRole.ADMIN) {
      throw new BadRequestException('Cadastro de administrador não é permitido');
    }
    if (data.role === UserRole.PARTNER && !data.businessName?.trim()) {
      throw new BadRequestException('Nome do estabelecimento é obrigatório');
    }

    const email = data.email.trim().toLowerCase();
    const phone = data.phone?.trim() || null;

    const duplicate = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email },
          ...(phone ? [{ phone }] : []),
        ],
      },
      select: { email: true, phone: true },
    });

    if (duplicate?.email === email) {
      throw new ConflictException('Este e-mail já está cadastrado. Entre na sua conta ou use outro e-mail.');
    }
    if (phone && duplicate?.phone === phone) {
      throw new ConflictException('Este celular/WhatsApp já está cadastrado. Entre na sua conta ou use outro número.');
    }

    const pending = data.role === UserRole.COURIER || data.role === UserRole.PARTNER;
    const onboardingData = data.profileData
      ? (data.profileData as Prisma.InputJsonObject)
      : undefined;

    const user = await this.prisma.user.create({
      data: {
        name: data.name.trim(),
        email,
        phone,
        passwordHash: this.hashPassword(data.password),
        role: data.role,
        status: pending ? UserStatus.PENDING : UserStatus.ACTIVE,
        customerProfile:
          data.role === UserRole.CUSTOMER ? { create: { onboardingData } } : undefined,
        courierProfile:
          data.role === UserRole.COURIER
            ? { create: { document: data.document?.trim() || null, onboardingData } }
            : undefined,
        partnerProfile:
          data.role === UserRole.PARTNER
            ? {
                create: {
                  businessName: data.businessName!.trim(),
                  document: data.document?.trim() || null,
                  onboardingData,
                },
              }
            : undefined,
      },
    });

    return this.publicUser(user);
  }

  async login(data: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: data.email.trim().toLowerCase() },
    });

    if (!user || !this.verifyPassword(data.password, user.passwordHash)) {
      throw new UnauthorizedException('E-mail ou senha inválidos');
    }
    if (user.status === UserStatus.BLOCKED || user.status === UserStatus.SUSPENDED) {
      throw new UnauthorizedException('Conta indisponível');
    }

    const token = randomBytes(48).toString('base64url');
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    await this.prisma.authSession.create({
      data: { userId: user.id, tokenHash: this.tokenHash(token), expiresAt },
    });

    return { token, expiresAt, user: this.publicUser(user) };
  }

  async authenticate(authorization?: string) {
    const token = authorization?.startsWith('Bearer ')
      ? authorization.slice(7).trim()
      : '';

    if (!token) throw new UnauthorizedException('Autenticação obrigatória');

    const session = await this.prisma.authSession.findUnique({
      where: { tokenHash: this.tokenHash(token) },
      include: { user: true },
    });

    if (!session || session.expiresAt <= new Date()) {
      throw new UnauthorizedException('Sessão inválida ou expirada');
    }
    if (
      session.user.status === UserStatus.BLOCKED ||
      session.user.status === UserStatus.SUSPENDED
    ) {
      throw new UnauthorizedException('Conta indisponível');
    }

    return session.user;
  }

  async me(authorization?: string) {
    return this.publicUser(await this.authenticate(authorization));
  }

  async logout(authorization?: string) {
    const token = authorization?.startsWith('Bearer ')
      ? authorization.slice(7).trim()
      : '';
    if (token) {
      await this.prisma.authSession.deleteMany({
        where: { tokenHash: this.tokenHash(token) },
      });
    }
    return { success: true };
  }
}
