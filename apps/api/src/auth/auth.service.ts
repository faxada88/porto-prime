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
import {
  Prisma,
  UserRole,
  UserStatus,
} from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { validateProfilePhoto } from '../couriers/profile-photo.js';
import { normalizePix } from '../wallet/pix-key.js';
import { CpfHubService } from './cpfhub.service.js';
import type { VerifiedCpf } from './cpfhub.service.js';
import { LoginDto } from './dto/login.dto.js';
import { BootstrapAdminDto } from './dto/bootstrap-admin.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import {
  ForgotPasswordDto,
  ResetPasswordDto,
} from './dto/reset-password.dto.js';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService, private readonly cpfHub: CpfHubService) {}

  private hashPassword(password: string) {
    const salt = randomBytes(16).toString('hex');
    const hash = scryptSync(password, salt, 64).toString('hex');
    return 'scrypt:' + salt + ':' + hash;
  }

  private verifyPassword(password: string, stored: string) {
    const [algorithm, salt, hash] = stored.split(':');
    if (algorithm !== 'scrypt' || !salt || !hash) return false;

    const candidate = scryptSync(password, salt, 64);
    const expected = Buffer.from(hash, 'hex');

    return (
      candidate.length === expected.length &&
      timingSafeEqual(candidate, expected)
    );
  }

  private tokenHash(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private digits(value?: string) {
    return (value ?? '').replace(/\D/g, '');
  }

  private validCpf(value: string) {
    const cpf = this.digits(value);
    if (cpf.length !== 11 || /^(\d)\1{10}$/.test(cpf)) return false;

    const calc = (size: number) => {
      let sum = 0;
      for (let i = 0; i < size; i++) {
        sum += Number(cpf[i]) * (size + 1 - i);
      }
      const rest = (sum * 10) % 11;
      return rest === 10 ? 0 : rest;
    };

    return (
      calc(9) === Number(cpf[9]) &&
      calc(10) === Number(cpf[10])
    );
  }

  private validCnpj(value: string) {
    const cnpj = this.digits(value);
    if (cnpj.length !== 14 || /^(\d)\1{13}$/.test(cnpj)) return false;

    const digit = (base: string) => {
      let factor = base.length - 7;
      let sum = 0;

      for (const number of base) {
        sum += Number(number) * factor--;
        if (factor < 2) factor = 9;
      }

      const rest = sum % 11;
      return rest < 2 ? 0 : 11 - rest;
    };

    return (
      digit(cnpj.slice(0, 12)) === Number(cnpj[12]) &&
      digit(cnpj.slice(0, 13)) === Number(cnpj[13])
    );
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

  async availability(field: string, raw: string) {
    const value = (raw ?? '').trim();

    if (!['email', 'phone', 'cpf', 'cnpj'].includes(field)) {
      throw new BadRequestException('Campo de verificação inválido');
    }

    if (field === 'email') {
      const email = value.toLowerCase();
      const valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
      if (!valid) return { valid: false, available: false };

      const exists = await this.prisma.user.findUnique({
        where: { email },
        select: { id: true },
      });

      return { valid: true, available: !exists };
    }

    if (field === 'phone') {
      const phone = this.digits(value);
      const valid = phone.length === 11;
      if (!valid) return { valid: false, available: false };

      const exists = await this.prisma.user.findUnique({
        where: { phone },
        select: { id: true },
      });

      return { valid: true, available: !exists };
    }

    const document = this.digits(value);
    const valid =
      field === 'cpf'
        ? this.validCpf(document)
        : this.validCnpj(document);

    if (!valid) return { valid: false, available: false };

    if (field === 'cpf') {
      const exists = await this.prisma.courierProfile.findFirst({
        where: { document },
        select: { id: true },
      });
      return { valid: true, available: !exists };
    }

    const exists = await this.prisma.partnerProfile.findFirst({
      where: { document },
      select: { id: true },
    });

    return { valid: true, available: !exists };
  }

  async lookupCourierCpf(cpf: string, birthDate: string, client: string) {
    const availability = await this.availability('cpf', cpf);
    if (!availability.valid) throw new BadRequestException('CPF inválido');
    if (!availability.available) throw new ConflictException('Este CPF já possui cadastro');
    return this.cpfHub.lookup(cpf, birthDate, client);
  }

  async verifyCourierIdentityForAdmin(cpf: string, birthDate: string) {
    const digits = this.digits(cpf);
    if (!this.validCpf(digits)) throw new BadRequestException('CPF inválido');
    const verified = await this.cpfHub.lookup(digits, birthDate, 'admin-courier-profile');
    if (!verified.regular) throw new BadRequestException(`CPF com situação cadastral ${verified.situation}. Solicite a regularização antes de alterar a identidade.`);
    return verified;
  }

  async postalCode(raw: string) {
    const cep = this.digits(raw);

    if (cep.length !== 8) {
      return { valid: false, reason: 'INVALID_FORMAT' };
    }

    const providers = [
      'https://viacep.com.br/ws/' + cep + '/json/',
      'https://cep.is/ws/' + cep + '/json/',
    ];

    let hadResponse = false;

    for (const url of providers) {
      try {
        const response = await fetch(url, {
          headers: {
            Accept: 'application/json',
            'User-Agent': 'PortoPrimeDelivery/1.0',
          },
          signal: AbortSignal.timeout(8000),
        });

        if (!response.ok) continue;

        hadResponse = true;
        const data = (await response.json()) as Record<string, unknown>;

        if (data['erro'] === true || data['erro'] === 'true') continue;

        const city = String(
          data['localidade'] ?? data['city'] ?? '',
        ).trim();
        const state = String(
          data['uf'] ?? data['state'] ?? '',
        )
          .trim()
          .toUpperCase();

        if (!city || !state) continue;

        if (
          state !== 'BA' ||
          city.toLowerCase() !== 'porto seguro'
        ) {
          return {
            valid: false,
            reason: 'OUTSIDE_SERVICE_AREA',
          };
        }

        return {
          valid: true,
          cep,
          street: String(
            data['logradouro'] ?? data['address'] ?? '',
          ).trim(),
          neighborhood: String(
            data['bairro'] ?? data['district'] ?? '',
          ).trim(),
          city,
          state,
        };
      } catch {
        continue;
      }
    }

    return {
      valid: false,
      reason: hadResponse ? 'NOT_FOUND' : 'LOOKUP_UNAVAILABLE',
    };
  }

  async bootstrapStatus() {
    const admin = await this.prisma.user.findFirst({
      where: { role: UserRole.ADMIN },
      select: { id: true },
    });

    return { available: !admin };
  }

  async bootstrapAdmin(data: BootstrapAdminDto) {
    const email = data.email.trim().toLowerCase();

    const user = await this.prisma.$transaction(async (tx) => {
      const existingAdmin = await tx.user.findFirst({
        where: { role: UserRole.ADMIN },
        select: { id: true },
      });

      if (existingAdmin) {
        throw new ConflictException(
          'O administrador inicial já foi configurado',
        );
      }

      const emailInUse = await tx.user.findUnique({
        where: { email },
        select: { id: true },
      });

      if (emailInUse) {
        throw new ConflictException(
          'Este e-mail já está cadastrado',
        );
      }

      return tx.user.create({
        data: {
          name: data.name.trim(),
          email,
          passwordHash: this.hashPassword(data.password),
          role: UserRole.ADMIN,
          status: UserStatus.ACTIVE,
        },
      });
    });

    return this.publicUser(user);
  }

  async register(data: RegisterDto, client = 'internal') {
    if (data.role === UserRole.ADMIN) {
      throw new BadRequestException(
        'Cadastro de administrador não é permitido',
      );
    }

    if (
      data.role === UserRole.PARTNER &&
      !data.businessName?.trim()
    ) {
      throw new BadRequestException(
        'Nome do estabelecimento é obrigatório',
      );
    }

    const email = data.email.trim().toLowerCase();
    const phone = this.digits(data.phone) || null;

    if (phone && phone.length !== 11) {
      throw new BadRequestException('Telefone inválido');
    }

    const existingIdentity = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email },
          ...(phone ? [{ phone }] : []),
        ],
      },
      select: {
        email: true,
        phone: true,
      },
    });

    if (existingIdentity?.email === email) {
      throw new ConflictException('E-mail já cadastrado');
    }

    if (phone && existingIdentity?.phone === phone) {
      throw new ConflictException('Telefone já cadastrado');
    }

    let verifiedCpf: VerifiedCpf | undefined;
    let courierPhoto: string | undefined;
    let courierDocument: string | null = null;
    let partnerDocument: string | null = null;

    if (data.role === UserRole.COURIER) {
      if(!data.profileData?.profilePhoto) throw new BadRequestException('Adicione uma selfie ou foto da galeria para concluir o cadastro de motoboy.');
      courierPhoto = validateProfilePhoto(data.profileData.profilePhoto);
      courierDocument = this.digits(data.document);

      if (!this.validCpf(courierDocument)) {
        throw new BadRequestException('CPF inválido');
      }

      if (!data.cnh?.trim()) {
        throw new BadRequestException('Número da CNH é obrigatório');
      }

      if (!data.vehicleModel?.trim()) {
        throw new BadRequestException('Modelo da moto é obrigatório');
      }

      const usedCpf = await this.prisma.courierProfile.findFirst({
        where: { document: courierDocument },
        select: { id: true },
      });

      if (usedCpf) {
        throw new ConflictException('CPF já possui candidatura');
      }
      verifiedCpf = await this.cpfHub.lookup(courierDocument, String(data.profileData?.birthDate ?? ''), client);
      if (!verifiedCpf.regular) {
        throw new BadRequestException(`CPF com situação cadastral ${verifiedCpf.situation}. Entre em contato com a Receita Federal para regularizar seu CPF antes de continuar.`);
      }
    }

    if (data.role === UserRole.PARTNER) {
      partnerDocument = this.digits(data.document);

      if (!this.validCnpj(partnerDocument)) {
        throw new BadRequestException('CNPJ inválido');
      }

      const usedCnpj = await this.prisma.partnerProfile.findFirst({
        where: { document: partnerDocument },
        select: { id: true },
      });

      if (usedCnpj) {
        throw new ConflictException('CNPJ já possui cadastro');
      }
    }

    const pending =
      data.role === UserRole.COURIER ||
      data.role === UserRole.PARTNER;

    const onboardingData = verifiedCpf
      ? ({ ...data.profileData, cpf: verifiedCpf.cpf, name: verifiedCpf.name, birthDate: verifiedCpf.birthDate, profilePhoto:courierPhoto, cpfSituation: verifiedCpf.situation } as Prisma.InputJsonObject)
      : data.profileData
        ? (data.profileData as Prisma.InputJsonObject)
        : undefined;

    const pix = data.role === UserRole.COURIER ? normalizePix(data.profileData?.pixKey, data.profileData?.pixKeyType) : null;

    const user = await this.prisma.user.create({
      data: {
        name: verifiedCpf?.name ?? data.name.trim(),
        email,
        phone,
        passwordHash: this.hashPassword(data.password),
        role: data.role,
        status: pending
          ? UserStatus.PENDING
          : UserStatus.ACTIVE,
        customerProfile:
          data.role === UserRole.CUSTOMER
            ? { create: { onboardingData } }
            : undefined,
        courierProfile:
          data.role === UserRole.COURIER
            ? {
                create: {
                  document: courierDocument,
                  pixKey: pix?.key ?? null,
                  pixKeyType: pix?.type ?? null,
                  cnh: data.cnh!.trim(),
                  cnhCategory:
                    data.cnhCategory?.trim() || 'A',
                  vehicleBrand:
                    data.vehicleBrand?.trim() || null,
                  vehicleModel: data.vehicleModel!.trim(),
                  vehiclePlate:
                    data.vehiclePlate
                      ?.trim()
                      .toUpperCase() || null,
                  vehicleYear:
                    data.vehicleYear || null,
                  onboardingData,
                },
              }
            : undefined,
        partnerProfile:
          data.role === UserRole.PARTNER
            ? {
                create: {
                  businessName:
                    data.businessName!.trim(),
                  document: partnerDocument,
                  onboardingData,
                },
              }
            : undefined,
      },
    });

    return this.publicUser(user);
  }

  async forgotPassword(data: ForgotPasswordDto) {
    const email = data.email.trim().toLowerCase();

    const user = await this.prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });

    // Resposta neutra para não revelar se o e-mail existe.
    if (!user) return { success: true };

    const rawToken = randomBytes(32).toString('base64url');

    await this.prisma.$transaction([
      this.prisma.passwordResetToken.deleteMany({
        where: { userId: user.id },
      }),
      this.prisma.passwordResetToken.create({
        data: {
          userId: user.id,
          tokenHash: this.tokenHash(rawToken),
          expiresAt: new Date(Date.now() + 30 * 60 * 1000),
        },
      }),
    ]);

    return {
      success: true,
      resetToken:
        process.env.NODE_ENV === 'production'
          ? undefined
          : rawToken,
    };
  }

  async resetPassword(data: ResetPasswordDto) {
    const row = await this.prisma.passwordResetToken.findUnique({
      where: {
        tokenHash: this.tokenHash(data.token),
      },
    });

    if (
      !row ||
      row.usedAt ||
      row.expiresAt <= new Date()
    ) {
      throw new BadRequestException(
        'Link de recuperação inválido ou expirado',
      );
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: row.userId },
        data: {
          passwordHash: this.hashPassword(data.password),
        },
      }),
      this.prisma.passwordResetToken.update({
        where: { id: row.id },
        data: { usedAt: new Date() },
      }),
      this.prisma.authSession.deleteMany({
        where: { userId: row.userId },
      }),
    ]);

    return { success: true };
  }

  private async issueSession(
    user: {
      id: string;
      name: string;
      email: string;
      phone: string | null;
      role: UserRole;
      status: UserStatus;
    },
    meta?: {
      deviceId?: string;
      deviceName?: string;
      userAgent?: string;
      ipAddress?: string;
    },
  ) {
    const accessToken = randomBytes(48).toString('base64url');
    const refreshToken = randomBytes(64).toString('base64url');
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);
    const refreshExpiresAt = new Date(
      Date.now() + 30 * 24 * 60 * 60 * 1000,
    );

    const session = await this.prisma.authSession.create({
      data: {
        userId: user.id,
        tokenHash: this.tokenHash(accessToken),
        refreshTokenHash: this.tokenHash(refreshToken),
        deviceId: meta?.deviceId?.trim() || null,
        deviceName: meta?.deviceName?.trim() || null,
        userAgent: meta?.userAgent?.slice(0, 500) || null,
        ipAddress: meta?.ipAddress?.slice(0, 120) || null,
        expiresAt,
        refreshExpiresAt,
        lastSeenAt: new Date(),
      },
      select: { id: true },
    });

    return {
      token: accessToken,
      accessToken,
      refreshToken,
      sessionId: session.id,
      expiresAt,
      refreshExpiresAt,
      user: this.publicUser(user),
    };
  }

  async login(
    data: LoginDto,
    meta?: {
      deviceId?: string;
      deviceName?: string;
      userAgent?: string;
      ipAddress?: string;
    },
  ) {
    const user = await this.prisma.user.findUnique({
      where: { email: data.email.trim().toLowerCase() },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        passwordHash: true,
        role: true,
        status: true,
      },
    });

    if (!user || !this.verifyPassword(data.password, user.passwordHash)) {
      throw new UnauthorizedException('E-mail ou senha inválidos');
    }

    if (user.status === UserStatus.PENDING) {
      throw new UnauthorizedException(
        'Cadastro aguardando aprovação administrativa',
      );
    }

    if (
      user.status === UserStatus.BLOCKED ||
      user.status === UserStatus.SUSPENDED
    ) {
      throw new UnauthorizedException('Conta indisponível');
    }

    await this.prisma.authSession.deleteMany({
      where: {
        OR: [
          { refreshExpiresAt: { lte: new Date() } },
          {
            refreshExpiresAt: null,
            expiresAt: { lte: new Date() },
          },
        ],
      },
    });

    return this.issueSession(user, meta);
  }

  private bearer(authorization?: string) {
    return authorization?.startsWith('Bearer ')
      ? authorization.slice(7).trim()
      : '';
  }

  async authenticateSession(authorization?: string) {
    const token = this.bearer(authorization);
    if (!token) {
      throw new UnauthorizedException('Autenticação obrigatória');
    }

    const session = await this.prisma.authSession.findUnique({
      where: { tokenHash: this.tokenHash(token) },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            role: true,
            status: true,
          },
        },
      },
    });

    if (
      !session ||
      session.revokedAt ||
      session.expiresAt <= new Date()
    ) {
      throw new UnauthorizedException('Sessão inválida ou expirada');
    }

    if (session.user.status === UserStatus.PENDING) {
      throw new UnauthorizedException(
        'Cadastro aguardando aprovação administrativa',
      );
    }

    if (
      session.user.status === UserStatus.BLOCKED ||
      session.user.status === UserStatus.SUSPENDED
    ) {
      throw new UnauthorizedException('Conta indisponível');
    }

    const now = new Date();
    if (now.getTime() - session.lastSeenAt.getTime() > 60_000) {
      await this.prisma.authSession.update({
        where: { id: session.id },
        data: { lastSeenAt: now },
      });
    }

    return session;
  }

  async authenticate(authorization?: string) {
    return (await this.authenticateSession(authorization)).user;
  }

  async refresh(
    refreshToken: string,
    meta?: {
      deviceId?: string;
      deviceName?: string;
      userAgent?: string;
      ipAddress?: string;
    },
  ) {
    const raw = refreshToken?.trim();
    if (!raw) throw new UnauthorizedException('Refresh token obrigatório');

    const session = await this.prisma.authSession.findUnique({
      where: { refreshTokenHash: this.tokenHash(raw) },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            role: true,
            status: true,
          },
        },
      },
    });

    if (
      !session ||
      session.revokedAt ||
      !session.refreshExpiresAt ||
      session.refreshExpiresAt <= new Date()
    ) {
      throw new UnauthorizedException('Refresh token inválido ou expirado');
    }

    if (session.user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Conta indisponível');
    }

    if (
      meta?.deviceId &&
      session.deviceId &&
      meta.deviceId !== session.deviceId
    ) {
      throw new UnauthorizedException('Sessão pertence a outro dispositivo');
    }

    const accessToken = randomBytes(48).toString('base64url');
    const nextRefreshToken = randomBytes(64).toString('base64url');
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);
    const refreshExpiresAt = new Date(
      Date.now() + 30 * 24 * 60 * 60 * 1000,
    );

    await this.prisma.authSession.update({
      where: { id: session.id },
      data: {
        tokenHash: this.tokenHash(accessToken),
        refreshTokenHash: this.tokenHash(nextRefreshToken),
        expiresAt,
        refreshExpiresAt,
        lastSeenAt: new Date(),
        userAgent: meta?.userAgent?.slice(0, 500) ?? session.userAgent,
        ipAddress: meta?.ipAddress?.slice(0, 120) ?? session.ipAddress,
      },
    });

    return {
      token: accessToken,
      accessToken,
      refreshToken: nextRefreshToken,
      sessionId: session.id,
      expiresAt,
      refreshExpiresAt,
      user: this.publicUser(session.user),
    };
  }

  async me(authorization?: string) {
    return this.publicUser(await this.authenticate(authorization));
  }

  async sessions(authorization?: string) {
    const current = await this.authenticateSession(authorization);
    const rows = await this.prisma.authSession.findMany({
      where: {
        userId: current.userId,
        revokedAt: null,
        refreshExpiresAt: { gt: new Date() },
      },
      select: {
        id: true,
        deviceId: true,
        deviceName: true,
        userAgent: true,
        ipAddress: true,
        createdAt: true,
        lastSeenAt: true,
        expiresAt: true,
        refreshExpiresAt: true,
      },
      orderBy: { lastSeenAt: 'desc' },
    });

    return rows.map((row) => ({
      ...row,
      current: row.id === current.id,
    }));
  }

  async revokeSession(
    sessionId: string,
    authorization?: string,
  ) {
    const current = await this.authenticateSession(authorization);
    const target = await this.prisma.authSession.findFirst({
      where: { id: sessionId, userId: current.userId },
      select: { id: true },
    });

    if (!target) {
      throw new UnauthorizedException('Sessão não encontrada');
    }

    await this.prisma.$transaction([
      this.prisma.authSession.update({
        where: { id: target.id },
        data: {
          revokedAt: new Date(),
          revokedReason: 'USER_REVOKED',
        },
      }),
      (this.prisma as any).courierDevicePresence.updateMany({
        where: { sessionId: target.id },
        data: { onlineRequested: false },
      }),
    ]);

    return { success: true };
  }

  async logout(authorization?: string) {
    const token = this.bearer(authorization);
    if (!token) return { success: true };

    const session = await this.prisma.authSession.findUnique({
      where: { tokenHash: this.tokenHash(token) },
      select: { id: true },
    });

    if (!session) return { success: true };

    await this.prisma.$transaction([
      this.prisma.authSession.updateMany({
        where: {
          id: session.id,
          revokedAt: null,
        },
        data: {
          revokedAt: new Date(),
          revokedReason: 'LOGOUT',
        },
      }),
      (this.prisma as any).courierDevicePresence.updateMany({
        where: { sessionId: session.id },
        data: { onlineRequested: false },
      }),
    ]);

    return { success: true };
  }

  async logoutAll(authorization?: string) {
    const current = await this.authenticateSession(authorization);
    const sessions = await this.prisma.authSession.findMany({
      where: {
        userId: current.userId,
        revokedAt: null,
      },
      select: { id: true },
    });
    const ids = sessions.map((row) => row.id);

    await this.prisma.$transaction([
      this.prisma.authSession.updateMany({
        where: {
          id: { in: ids },
          revokedAt: null,
        },
        data: {
          revokedAt: new Date(),
          revokedReason: 'LOGOUT_ALL',
        },
      }),
      (this.prisma as any).courierDevicePresence.updateMany({
        where: { sessionId: { in: ids } },
        data: { onlineRequested: false },
      }),
    ]);

    return { success: true };
  }

}