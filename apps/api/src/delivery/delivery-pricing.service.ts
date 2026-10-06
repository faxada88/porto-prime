import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuthService } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';

type AddressLike = {
  id: string;
  street: string;
  number: string;
  complement?: string | null;
  neighborhood: string;
  city: string;
  state: string;
  postalCode: string;
  latitude?: unknown;
  longitude?: unknown;
};

@Injectable()
export class DeliveryPricingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
  ) {}

  async config() {
    return (this.prisma as any).deliveryPricingConfig.upsert({
      where: { id: 'default' },
      create: { id: 'default' },
      update: {},
    });
  }

  async adminConfig(authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== 'ADMIN') {
      throw new ForbiddenException('Acesso exclusivo de administrador');
    }
    return this.config();
  }

  async updateAdminConfig(
    body: Record<string, unknown>,
    authorization?: string,
  ) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== 'ADMIN') {
      throw new ForbiddenException('Acesso exclusivo de administrador');
    }

    const numeric = [
      'distributorLatitude',
      'distributorLongitude',
      'baseFee',
      'includedKm',
      'pricePerAdditionalKm',
      'maxDistanceKm',
      'minDeliveryFee',
      'maxDeliveryFee',
      'platformCommissionPercent',
    ];

    const data: Record<string, unknown> = {};
    for (const key of numeric) {
      if (body[key] === undefined || body[key] === null || body[key] === '') {
        continue;
      }
      const value = Number(body[key]);
      if (!Number.isFinite(value)) {
        throw new BadRequestException(`Valor inválido para ${key}`);
      }
      data[key] = value;
    }

    for (const key of ['offerTimeoutSeconds', 'heartbeatTimeoutSeconds']) {
      if (body[key] === undefined) continue;
      const value = Number(body[key]);
      if (!Number.isInteger(value) || value < 10 || value > 600) {
        throw new BadRequestException(`Valor inválido para ${key}`);
      }
      data[key] = value;
    }

    if (body['distributorName'] !== undefined) {
      data['distributorName'] =
        String(body['distributorName']).trim() || 'Porto Prime Delivery';
    }
    if (body['distributorAddress'] !== undefined) {
      data['distributorAddress'] =
        String(body['distributorAddress']).trim() || null;
    }
    if (body['regionRules'] !== undefined) {
      if (
        body['regionRules'] !== null &&
        !Array.isArray(body['regionRules'])
      ) {
        throw new BadRequestException(
          'Regras por região devem ser uma lista',
        );
      }
      data['regionRules'] = body['regionRules'] ?? null;
    }

    const baseFee = Number(data['baseFee'] ?? (await this.config()).baseFee);
    const minFee = Number(
      data['minDeliveryFee'] ?? (await this.config()).minDeliveryFee,
    );
    const maxFee = Number(
      data['maxDeliveryFee'] ?? (await this.config()).maxDeliveryFee,
    );

    if (baseFee < 0 || minFee < 0 || maxFee < minFee) {
      throw new BadRequestException(
        'Configuração de valores de entrega inválida',
      );
    }

    return (this.prisma as any).deliveryPricingConfig.update({
      where: { id: 'default' },
      data,
    });
  }

  private fullAddress(address: AddressLike) {
    return [
      address.street,
      address.number,
      address.complement,
      address.neighborhood,
      address.city,
      address.state,
      address.postalCode,
      'Brasil',
    ]
      .filter(Boolean)
      .join(', ');
  }

  private number(value: unknown) {
    if (value === null || value === undefined) return null;
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  private async geocode(address: AddressLike) {
    const currentLat = this.number(address.latitude);
    const currentLng = this.number(address.longitude);
    if (currentLat !== null && currentLng !== null) {
      return { latitude: currentLat, longitude: currentLng };
    }

    const base =
      process.env.GEOCODING_BASE_URL?.replace(/\/$/, '') ||
      'https://nominatim.openstreetmap.org';
    const url = new URL(base + '/search');
    url.searchParams.set('format', 'jsonv2');
    url.searchParams.set('limit', '1');
    url.searchParams.set('countrycodes', 'br');
    url.searchParams.set('q', this.fullAddress(address));

    let response: Response;
    try {
      response = await fetch(url, {
        headers: {
          Accept: 'application/json',
          'User-Agent':
            process.env.GEOCODING_USER_AGENT ||
            'PortoPrimeDelivery/1.0 contact@portoprimedelivery.com.br',
        },
        signal: AbortSignal.timeout(10_000),
      });
    } catch {
      throw new BadRequestException(
        'Não foi possível localizar o endereço agora',
      );
    }

    if (!response.ok) {
      throw new BadRequestException(
        'Serviço de localização indisponível',
      );
    }

    const rows = (await response.json()) as Array<{
      lat?: string;
      lon?: string;
    }>;
    const latitude = Number(rows[0]?.lat);
    const longitude = Number(rows[0]?.lon);

    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      throw new BadRequestException(
        'Não foi possível localizar este endereço com precisão',
      );
    }

    await this.prisma.address.update({
      where: { id: address.id },
      data: { latitude, longitude },
    });

    return { latitude, longitude };
  }

  private async roadRoute(
    from: { latitude: number; longitude: number },
    to: { latitude: number; longitude: number },
  ) {
    const base =
      process.env.ROUTING_BASE_URL?.replace(/\/$/, '') ||
      'https://router.project-osrm.org';

    const coordinates =
      `${from.longitude},${from.latitude};${to.longitude},${to.latitude}`;
    const url = new URL(
      `${base}/route/v1/driving/${coordinates}`,
    );
    url.searchParams.set('overview', 'false');
    url.searchParams.set('alternatives', 'false');
    url.searchParams.set('steps', 'false');

    let response: Response;
    try {
      response = await fetch(url, {
        headers: {
          Accept: 'application/json',
          'User-Agent': 'PortoPrimeDelivery/1.0',
        },
        signal: AbortSignal.timeout(12_000),
      });
    } catch {
      throw new BadRequestException(
        'Não foi possível calcular a rota de entrega agora',
      );
    }

    if (!response.ok) {
      throw new BadRequestException(
        'Serviço de rotas indisponível',
      );
    }

    const data = (await response.json()) as {
      code?: string;
      routes?: Array<{ distance?: number; duration?: number }>;
    };

    const route = data.routes?.[0];
    if (
      data.code !== 'Ok' ||
      !route ||
      !Number.isFinite(route.distance) ||
      !Number.isFinite(route.duration)
    ) {
      throw new BadRequestException(
        'Não encontramos uma rota viária válida para este endereço',
      );
    }

    return {
      distanceKm: Number(route.distance) / 1000,
      durationMinutes: Math.max(
        1,
        Math.round(Number(route.duration) / 60),
      ),
    };
  }

  private regionalAdditionalFee(
    rules: unknown,
    address: AddressLike,
  ) {
    if (!Array.isArray(rules)) return 0;

    const neighborhood = address.neighborhood
      .trim()
      .toLocaleLowerCase('pt-BR');

    for (const raw of rules) {
      if (!raw || typeof raw !== 'object') continue;
      const rule = raw as Record<string, unknown>;
      const ruleNeighborhood = String(
        rule['neighborhood'] ?? '',
      )
        .trim()
        .toLocaleLowerCase('pt-BR');

      if (!ruleNeighborhood || ruleNeighborhood !== neighborhood) {
        continue;
      }

      const fee = Number(rule['additionalFee'] ?? 0);
      return Number.isFinite(fee) ? fee : 0;
    }

    return 0;
  }

  async quoteForAddress(address: AddressLike) {
    const cfg = await this.config();
    const baseFee = Number(cfg.baseFee);
    const minFee = Number(cfg.minDeliveryFee);
    const maxFee = Number(cfg.maxDeliveryFee);

    const pickupLat = this.number(cfg.distributorLatitude);
    const pickupLng = this.number(cfg.distributorLongitude);

    // Preserva checkout existente até o Admin informar a base real.
    // Não inventamos distância nem coordenadas.
    if (pickupLat === null || pickupLng === null) {
      const fee = Math.min(maxFee, Math.max(minFee, baseFee));
      return {
        deliveryFee: Number(fee.toFixed(2)),
        distanceKm: null,
        durationMinutes: null,
        withinServiceArea: true,
        pricingMode: 'BASE_ONLY_NOT_CONFIGURED',
      };
    }

    const destination = await this.geocode(address);
    const route = await this.roadRoute(
      { latitude: pickupLat, longitude: pickupLng },
      destination,
    );

    const maxDistanceKm = Number(cfg.maxDistanceKm);
    if (route.distanceKm > maxDistanceKm) {
      throw new BadRequestException(
        `Endereço fora da área atendida. Limite atual: ${maxDistanceKm.toFixed(1)} km por rota.`,
      );
    }

    const includedKm = Number(cfg.includedKm);
    const pricePerKm = Number(cfg.pricePerAdditionalKm);
    const extraKm = Math.max(0, route.distanceKm - includedKm);
    const regional = this.regionalAdditionalFee(
      cfg.regionRules,
      address,
    );

    const calculated =
      baseFee + extraKm * pricePerKm + regional;
    const fee = Math.min(
      maxFee,
      Math.max(minFee, calculated),
    );

    return {
      deliveryFee: Number(fee.toFixed(2)),
      distanceKm: Number(route.distanceKm.toFixed(3)),
      durationMinutes: route.durationMinutes,
      withinServiceArea: true,
      pricingMode: 'ROAD_ROUTE',
      regionalAdditionalFee: Number(regional.toFixed(2)),
    };
  }

  async customerQuote(
    addressId: string,
    authorization?: string,
  ) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== 'CUSTOMER') {
      throw new ForbiddenException('Acesso exclusivo de cliente');
    }

    const address = await this.prisma.address.findFirst({
      where: { id: addressId, userId: user.id },
    });
    if (!address) throw new NotFoundException('Endereço não encontrado');

    return this.quoteForAddress(address);
  }
}
