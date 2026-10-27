import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { validateProfilePhoto } from './profile-photo.js';
import { RealtimeGateway } from '../realtime/realtime.gateway.js';
import { UserRole } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { AuthService } from '../auth/auth.service.js';

@Injectable()
export class CouriersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly realtime: RealtimeGateway,
  ) {}

  private digits(value: unknown) {
    return String(value ?? '').replace(/\D/g, '');
  }

  private publicAnswer(response: string | null) {
    if (!response) return null;
    try { const parsed = JSON.parse(response); return typeof parsed?.text === 'string' ? parsed.text : null; }
    catch { return response; }
  }

  private validCpf(value: unknown) {
    const cpf = this.digits(value);

    if (cpf.length !== 11 || /^(\d)\1{10}$/.test(cpf)) {
      return false;
    }

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

  private safe(profile: any) {
    return {
      id: profile.id,
      name: profile.user.name,
      profilePhoto: profile.onboardingData?.profilePhoto ?? null,
      onboardingData: profile.onboardingData,
      pixKey: profile.pixKey,
      pixKeyType: profile.pixKeyType,
      document: profile.document,
      approvalStatus: profile.approvalStatus,
      userStatus: profile.user.status,
      restrictionReason: profile.user.status === 'ACTIVE' ? null : profile.onboardingData?.restrictionReason ?? null,
      cnh: profile.cnh,
      cnhCategory: profile.cnhCategory,
      vehicleBrand: profile.vehicleBrand,
      vehicleModel: profile.vehicleModel,
      vehiclePlate: profile.vehiclePlate,
      vehicleYear: profile.vehicleYear,
      requirements: profile.requirements ?? [],
      updatedAt: profile.updatedAt,
    };
  }

  async status(document: string) {
    const cpf = this.digits(document);

    if (!this.validCpf(cpf)) {
      throw new BadRequestException('Informe um CPF válido');
    }

    const profile = await (this.prisma as any).courierProfile.findUnique({
      where: { document: cpf },
      include: {
        user: {
          select: {
            name: true,
            status: true,
          },
        },
        requirements: {
          where: {
            status: { in: ['OPEN', 'ANSWERED'] },
          },
          orderBy: { requestedAt: 'desc' },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException(
        'Nenhuma candidatura encontrada para este CPF',
      );
    }

    const parts = profile.user.name
      .trim()
      .split(/\s+/);

    const maskedName =
      parts.length > 1
        ? parts[0] +
          ' ' +
          parts.at(-1)!.slice(0, 1) +
          '.'
        : parts[0];

    return {
      found: true,
      name: maskedName,
      document:
        '***.***.***-' + cpf.slice(-2),
      approvalStatus: profile.approvalStatus,
      userStatus: profile.user.status,
      hasPendingRequirements:
        profile.requirements.some(
          (requirement: any) =>
            requirement.status === 'OPEN',
        ),
      requirements: profile.requirements.map(
        (requirement: any) => ({
          id: requirement.id,
          title: requirement.title,
          description: requirement.description,
          response: this.publicAnswer(requirement.response), // Never expose document images through the public CPF lookup.
          status: requirement.status,
          requestedAt: requirement.requestedAt,
          answeredAt: requirement.answeredAt,
        }),
      ),
    };
  }

  async publicRespond(
    requirementId: string,
    document: string,
    response: string,
  ) {
    const cpf = this.digits(document);
    const answer = String(response ?? '').trim();

    if (!this.validCpf(cpf)) {
      throw new BadRequestException('CPF inválido');
    }

    if (answer.length < 3) {
      throw new BadRequestException(
        'Informe a resposta solicitada',
      );
    }

    const requirement =
      await (this.prisma as any).courierRequirement.findFirst({
        where: {
          id: requirementId,
          courier: {
            document: cpf,
            user: { status: { in: ['ACTIVE', 'PENDING'] } },
            approvalStatus: { notIn: ['REJECTED', 'SUSPENDED'] },
          },
        },
      });

    if (!requirement) {
      throw new NotFoundException(
        'Pendência não encontrada para este CPF',
      );
    }

    if (requirement.status === 'RESOLVED') {
      throw new BadRequestException(
        'Esta pendência já foi concluída',
      );
    }

    return this.answerRequirement(requirementId, {
        response: answer,
        status: 'ANSWERED',
        answeredAt: new Date(),
      });
  }

  async profile(authorization?: string) {
    const user =
      await this.auth.authenticate(authorization, true);

    if (user.role !== UserRole.COURIER) {
      throw new BadRequestException(
        'Conta não é de motoboy',
      );
    }

    const profile =
      await (this.prisma as any).courierProfile.findUnique({
        where: { userId: user.id },
        include: {
          user: {
            select: { name: true, status: true },
          },
          requirements: {
            orderBy: { requestedAt: 'desc' },
          },
        },
      });

    if (!profile) {
      throw new NotFoundException(
        'Perfil do motoboy não encontrado',
      );
    }

    return profile;
  }

  async me(authorization?: string) {
    return this.safe(
      await this.profile(authorization),
    );
  }

  async savePhoto(raw: unknown, authorization?: string) {
    const profile = await this.profile(authorization);
    this.assertCanEdit(profile);
    const photo = validateProfilePhoto(raw);
    await this.prisma.$transaction(async tx => {
      await tx.$queryRawUnsafe('SELECT "id" FROM "CourierProfile" WHERE "id" = $1 FOR UPDATE', profile.id);
      const current = await tx.courierProfile.findUnique({ where: { id: profile.id } });
      if (!current) throw new NotFoundException('Perfil de motoboy não encontrado');
      await tx.courierProfile.update({ where: { id: profile.id }, data: { onboardingData: { ...(current.onboardingData as any || {}), profilePhoto: photo } } });
    });
    this.realtime.emitToUser(profile.userId,'courier.profile.updated',{ courierId:profile.id });
    this.realtime.emitToRole('ADMIN','courier.profile.updated',{ courierId:profile.id });
    const active = await this.prisma.order.findMany({ where:{ courierId:profile.id,status:{ notIn:['DELIVERED','CANCELED'] } },select:{ id:true,customerId:true,status:true } });
    for(const order of active)this.realtime.emitOrderUpdated(order);
    return { profilePhoto:photo };
  }

  async update(
    body: Record<string, unknown>,
    authorization?: string,
  ) {
    const profile =
      await this.profile(authorization);

    const allowed: any = {};
    this.assertCanEdit(profile);

    for (const key of [
      'cnh',
      'cnhCategory',
      'vehicleBrand',
      'vehicleModel',
      'vehiclePlate',
    ]) {
      if (body[key] != null) {
        allowed[key] = String(body[key]).trim();
      }
    }

    if (body.vehicleYear != null) {
      allowed.vehicleYear = Number(body.vehicleYear);
    }

    const updated =
      await (this.prisma as any).courierProfile.update({
        where: { id: profile.id },
        data: allowed,
        include: {
          user: {
            select: { name: true, status: true },
          },
          requirements: {
            orderBy: { requestedAt: 'desc' },
          },
        },
      });

    return this.safe(updated);
  }

  async respond(
    id: string,
    response: string,
    authorization?: string,
    documentPhoto?: string,
  ) {
    if (typeof response !== 'string' || !response.trim()) {
      throw new BadRequestException(
        'Escreva a resposta ou informação solicitada',
      );
    }

    const profile =
      await this.profile(authorization);

    const requirement =
      await (this.prisma as any).courierRequirement.findFirst({
        where: {
          id,
          courierId: profile.id,
        },
      });

    if (!requirement) {
      throw new NotFoundException(
        'Pendência não encontrada',
      );
    }

    if (profile.user.status === 'BLOCKED' || profile.user.status === 'SUSPENDED' || ['REJECTED', 'SUSPENDED'].includes(profile.approvalStatus)) {
      throw new BadRequestException('Envio indisponível enquanto a conta está suspensa ou bloqueada. Entre em contato com o suporte.');
    }
    if (response.length > 4000) throw new BadRequestException('Use até 4.000 caracteres.');
    const photo = documentPhoto ? validateProfilePhoto(documentPhoto) : undefined;
    return this.answerRequirement(id, {
        response: photo ? JSON.stringify({ text: response.trim(), documentPhoto: photo }) : response.trim(),
        status: 'ANSWERED',
        answeredAt: new Date(),
      });
  }

  private async answerRequirement(id: string, data: Record<string, unknown>) {
    const changed = await (this.prisma as any).courierRequirement.updateMany({where: {id, status: {not: 'RESOLVED'}, canceledAt: null}, data});
    if (!changed.count) throw new BadRequestException('Esta pendência foi concluída ou cancelada. Atualize a consulta.');
    const result = await (this.prisma as any).courierRequirement.findUnique({where: {id}, include: {courier: {select: {userId: true}}}});
    if (result) {
      this.realtime.emitToUser(result.courier.userId, 'courier.profile.updated', {courierId: result.courierId});
      this.realtime.emitToRole('ADMIN', 'courier.profile.updated', {courierId: result.courierId});
    }
    return { success: true };

  }

  private assertCanEdit(profile: any) {
    if (['BLOCKED', 'SUSPENDED'].includes(profile.user.status) || ['REJECTED', 'SUSPENDED'].includes(profile.approvalStatus)) {
      throw new BadRequestException('A conta está restrita a consulta e atendimento.');
    }
  }
}

