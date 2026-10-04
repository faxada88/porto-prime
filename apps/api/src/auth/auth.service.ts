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

  private digits(value?: string) {
    return (value ?? '').replace(/\D/g, '');
  }

  private normalizeDocument(value?: string) {
    return this.digits(value);
  }

  private validCpf(value: string) {
    const cpf = this.digits(value);
    if (cpf.length !== 11 || /^(\d)\1{10}$/.test(cpf)) return false;
    const calc = (size: number) => {
      let sum = 0;
      for (let i = 0; i < size; i++) sum += Number(cpf[i]) * (size + 1 - i);
      const rest = (sum * 10) % 11;
      return rest === 10 ? 0 : rest;
    };
    return calc(9) === Number(cpf[9]) && calc(10) === Number(cpf[10]);
  }

  private validCnpj(value: string) {
    const cnpj = this.digits(value);
    if (cnpj.length !== 14 || /^(\d)\1{13}$/.test(cnpj)) return false;
    const digit = (base: string) => {
      let factor = base.length - 7, sum = 0;
      for (const n of base) {
        sum += Number(n) * factor--;
        if (factor < 2) factor = 9;
      }
      const rest = sum % 11;
      return rest < 2 ? 0 : 11 - rest;
    };
    return digit(cnpj.slice(0, 12)) === Number(cnpj[12]) &&
      digit(cnpj.slice(0, 13)) === Number(cnpj[13]);
  }

  async postalCode(raw: string) {
    const cep = this.digits(raw);
    if (cep.length !== 8) return { valid: false, reason: 'INVALID_FORMAT' };
    const providers = [
      'https://viacep.com.br/ws/' + cep + '/json/',
      'https://cep.is/ws/' + cep + '/json/',
    ];
    let hadResponse = false;
    for (const url of providers) {
      try {
        const response = await fetch(url, {
          headers: { Accept: 'application/json', 'User-Agent': 'PortoPrimeDelivery/1.0' },
          signal: AbortSignal.timeout(8000),
        });
        if (!response.ok) continue;
        hadResponse = true;
        const data = await response.json() as Record<string, unknown>;
        if (data['erro'] === true || data['erro'] === 'true') continue;
        const city = String(data['localidade'] ?? '').trim();
        const state = String(data['uf'] ?? '').trim().toUpperCase();
        if (!city || !state) continue;
        if (state !== 'BA' || city.toLowerCase() !== 'porto seguro') {
          return { valid: false, reason: 'OUTSIDE_SERVICE_AREA' };
        }
        return {
          valid: true,
          cep,
          street: String(data['logradouro'] ?? '').trim(),
          neighborhood: String(data['bairro'] ?? '').trim(),
          city,
          state,
        };
      } catch {
        continue;
      }
    }
    return { valid: false, reason: hadResponse ? 'NOT_FOUND' : 'LOOKUP_UNAVAILABLE' };
  }

  async availability(field: string, raw: string) {
    const value = raw?.trim() ?? '';
    if (!['email', 'phone', 'cpf', 'cnpj'].includes(field)) {
      throw new BadRequestException('Campo de verificação inválido');
    }
    let normalized = value;
    let valid = true;
    if (field === 'email') {
      normalized = value.toLowerCase();
      valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(normalized);
    } else if (field === 'phone') {
      normalized = this.digits(value);
      valid = normalized.length === 11;
    } else {
      normalized = this.normalizeDocument(value);
      valid = field === 'cpf' ? this.validCpf(normalized) : this.validCnpj(normalized);
    }
    if (!valid) return { valid: false, available: false };
    const exists = field === 'email'
      ? await this.prisma.user.findUnique({ where: { email: normalized }, select: { id: true } })
      : field === 'phone'
        ? await this.prisma.user.findUnique({ where: { phone: normalized }, select: { id: true } })
        : await this.prisma.user.findUnique({ where: { document: normalized }, select: { id: true } });
    return { valid: true, available: !exists };
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
    const phone = this.digits(data.phone);
    const document = data.document ? this.normalizeDocument(data.document) : undefined;
    const documentType = data.role === UserRole.PARTNER ? 'CNPJ' : 'CPF';
    if (data.role !== UserRole.CUSTOMER) {
      if (!document) throw new BadRequestException(documentType + ' obrigatório');
      const documentValid = documentType === 'CNPJ'
        ? this.validCnpj(document)
        : this.validCpf(document);
      if (!documentValid) throw new BadRequestException(documentType + ' inválido');
    }
    if (phone.length !== 11) throw new BadRequestException('Telefone inválido');

    const duplicate = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email },
          { phone },
          ...(document ? [{ document }] : []),
        ],
      },
      select: { email: true, phone: true, document: true },
    });

    if (duplicate?.email === email) {
      throw new ConflictException('Este e-mail já está cadastrado. Entre na sua conta ou use outro e-mail.');
    }
    if (document && duplicate?.document === document) {
      throw new ConflictException('Este ' + documentType + ' já possui cadastro');
    }
    if (duplicate?.phone === phone) {
      throw new ConflictException('Este celular/WhatsApp já está cadastrado. Entre na sua conta ou use outro número.');
    }

    const pending = data.role === UserRole.COURIER || data.role === UserRole.PARTNER;
    const onboardingData = data.profileData
      ? (data.profileData as Prisma.InputJsonObject)
      : undefined;

    let user;
    try {
      user = await this.prisma.user.create({
      data: {
        name: data.name.trim(),
        email,
        phone,
        document,
        passwordHash: this.hashPassword(data.password),
        role: data.role,
        status: pending ? UserStatus.PENDING : UserStatus.ACTIVE,
        customerProfile:
          data.role === UserRole.CUSTOMER ? { create: { onboardingData } } : undefined,
        courierProfile:
          data.role === UserRole.COURIER
            ? { create: { document, onboardingData } }
            : undefined,
        partnerProfile:
          data.role === UserRole.PARTNER
            ? {
                create: {
                  businessName: data.businessName!.trim(),
                  document,
                  onboardingData,
                },
              }
            : undefined,
      },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new ConflictException('E-mail, telefone ou documento já cadastrado');
      }
      throw error;
    }

    return this.publicUser(user);
  }

  async login(data: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: data.email.trim().toLowerCase() },
    });

    if (!user || !this.verifyPassword(data.password, user.passwordHash)) {
      throw new UnauthorizedException('E-mail ou senha inválidos');
    }
    if (user.status === UserStatus.PENDING) {
      throw new UnauthorizedException('Cadastro aguardando aprovação administrativa');
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
