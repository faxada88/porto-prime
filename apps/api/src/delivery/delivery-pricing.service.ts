import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RealtimeGateway } from '../realtime/realtime.gateway.js';
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
  locationConfirmed?: boolean;
  latitude?: unknown;
  longitude?: unknown;
};

@Injectable()
export class DeliveryPricingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly realtime: RealtimeGateway,
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

    const data: Record<string, unknown> = {};
    for (const key of ['baseFee', 'includedKm', 'pricePerAdditionalKm']) {
      if (body[key] === undefined) continue;
      const raw = body[key];
      const value = Number(raw);
      if ((typeof raw !== 'number' && typeof raw !== 'string') || String(raw).trim() === '' || !Number.isFinite(value) || value < 0 || value > 1000 || Math.abs(value * 100 - Math.round(value * 100)) > 0.000001) {
        throw new BadRequestException('Informe valores positivos, com até duas casas decimais');
      }
      data[key] = value;
    }
    if (data.baseFee === 0 || data.pricePerAdditionalKm === 0) throw new BadRequestException('A taxa e o adicional precisam ser maiores que zero');
    const lat = body.distributorLatitude, lng = body.distributorLongitude;
    if (lat !== undefined || lng !== undefined) {
      if (!this.validPoint(lat, lng)) throw new BadRequestException('Selecione a localização da distribuidora no mapa');
      data.distributorLatitude = Number(lat);
      data.distributorLongitude = Number(lng);
    }
    if (body.distributorName !== undefined) data.distributorName = String(body.distributorName).trim() || 'Porto Prime';
    if (body.distributorAddress !== undefined) data.distributorAddress = String(body.distributorAddress).trim() || null;
    // A tarifa tem uma única fórmula; não há adicionais ocultos nem comissão.
    data.platformCommissionPercent = 0;
    await this.config();
    const saved = await (this.prisma as any).deliveryPricingConfig.update({
      where: { id: 'default' }, data: { ...data, pricingRevision: { increment: 1 } },
    });
    this.realtime.emitCatalogUpdated('delivery.pricing.updated');
    return saved;
  }

  private streets?: Array<{ street: string; number: string; city: string; neighborhood?: string; postalCode?: string; latitude: number; longitude: number }>;
  private normalize(value: unknown) {
    return String(value ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9 ]/g, ' ').replace(/\b(rua|avenida|av|r|estrada|rodovia)\b/g, '').replace(/\s+/g, ' ').trim();
  }
  private async streetRows() {
    if (!this.streets) {
      try { this.streets = JSON.parse(await readFile(process.env.STREET_INDEX_PATH || resolve(process.cwd(), '../../.routing/streets.json'), 'utf8')); }
      catch { throw new BadRequestException('A consulta de endereços está temporariamente indisponível. Tente novamente em instantes'); }
    }
    return this.streets!;
  }
  async locate(body: Record<string, unknown>, authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (!['CUSTOMER', 'ADMIN'].includes(user.role)) throw new ForbiddenException('Acesso não permitido');
    const street = this.normalize(body.street);
    if (street.length < 3 || street.length > 150) throw new BadRequestException('Informe o nome completo da rua');
    const wanted = this.normalize(body.city), number = String(body.number ?? '').trim();
    const scored = (await this.streetRows()).filter(row => {
      const name = this.normalize(row.street);
      return (name === street || name.includes(street)) && (!row.city || !wanted || this.normalize(row.city) === wanted);
    }).map(row=>({row,score:(this.normalize(row.street)===street?10:0)+(number&&row.number===number?20:0)})).sort((a,b)=>b.score-a.score);
    const results: NonNullable<typeof this.streets> = [];
    for(const {row} of scored){if(!results.some(r=>r.street===row.street && r.number===row.number)) results.push(row);if(results.length===5)break;}
    return { results, attribution: '© OpenStreetMap contributors', requiresConfirmation: false };
  }

  // CEP preenche o endereço; a localização vem do índice local, sem enviar
  // endereços residenciais para serviços públicos de geocodificação.
  private async resolveAddress(address: AddressLike) {
    if (address.locationConfirmed && this.validPoint(address.latitude, address.longitude)) {
      return { latitude: Number(address.latitude), longitude: Number(address.longitude), accuracy: 'CONFIRMED_POINT' };
    }
    const city = this.normalize(address.city), street = this.normalize(address.street);
    if (city !== 'porto seguro' || String(address.state).toUpperCase() !== 'BA') throw new BadRequestException('No momento, atendemos endereços em Porto Seguro/BA');
    if (street.length < 3 || !String(address.number ?? '').trim()) throw new BadRequestException('Informe a rua e o número para calcular a entrega');
    const rows = (await this.streetRows()).filter(row => this.normalize(row.street) === street && this.validPoint(row.latitude, row.longitude) && (row.city ? this.normalize(row.city) === city : row.latitude > -16.6 && row.latitude < -16.3 && row.longitude > -39.2 && row.longitude < -38.95));
    const neighborhood = this.normalize(address.neighborhood);
    const local = rows.filter(row => row.neighborhood && this.normalize(row.neighborhood) === neighborhood);
    const candidates = local.length ? local : rows;
    if (!candidates.length) throw new BadRequestException('Não encontramos esta rua. Confira o nome completo, bairro e número do endereço');
    const numbered = candidates.filter(row => row.number && this.normalize(row.number) === this.normalize(address.number));
    const points = numbered.length ? numbered : candidates.filter(row => !row.number);
    if (!points.length) throw new BadRequestException('Não foi possível localizar este número. Confira os dados do endereço');
    const lat = points.reduce((sum,row)=>sum+row.latitude,0)/points.length;
    const lng = points.reduce((sum,row)=>sum+row.longitude,0)/points.length;
    // Ruas homônimas em regiões distantes precisam de bairro identificável.
    if (points.some(row => Math.hypot((row.latitude-lat)*111,(row.longitude-lng)*106)>2)) throw new BadRequestException('Encontramos trechos distantes com este nome. Informe o bairro correto e o nome completo da rua');
    const point = points.slice().sort((a,b)=>Math.hypot(a.latitude-lat,a.longitude-lng)-Math.hypot(b.latitude-lat,b.longitude-lng))[0];
    return { latitude: point.latitude, longitude: point.longitude, accuracy: numbered.length ? 'ADDRESS_NUMBER' : 'STREET_ESTIMATE' };
  }

  async preview(address: Omit<AddressLike, 'id'>, authorization?: string) {
    const user = await this.auth.authenticate(authorization);
    if (user.role !== 'CUSTOMER') throw new ForbiddenException('Acesso exclusivo de cliente');
    // Coordenadas recebidas no preview nunca substituem a busca pelo endereço.
    return this.quoteForAddress({ ...address, id: 'preview', latitude: undefined, longitude: undefined, locationConfirmed: false });
  }

  private validPoint(lat: unknown, lng: unknown) {
    return typeof lat !== 'boolean' && typeof lng !== 'boolean' && lat !== null && lat !== undefined && lat !== '' && lng !== null && lng !== undefined && lng !== '' &&
      Number.isFinite(Number(lat)) && Number.isFinite(Number(lng)) && Math.abs(Number(lat)) <= 90 && Math.abs(Number(lng)) <= 180;
  }

  private routeCache = new Map<string, { at: number; value: { distanceKm: number; durationMinutes: number } }>();
  private routeRequests = new Map<string, Promise<{ distanceKm: number; durationMinutes: number }>>();

  private async cachedRoute(from: { latitude: number; longitude: number }, to: { latitude: number; longitude: number }) {
    const key = `${from.latitude},${from.longitude};${to.latitude},${to.longitude}`;
    const cached = this.routeCache.get(key);
    if (cached && Date.now() - cached.at < 300000) return cached.value;
    const pending = this.routeRequests.get(key);
    if (pending) return pending;
    const request = this.roadRoute(from, to).then(value => {
      if (this.routeCache.size >= 1000) this.routeCache.delete(this.routeCache.keys().next().value!);
      this.routeCache.set(key, { at: Date.now(), value });
      return value;
    }).finally(() => this.routeRequests.delete(key));
    this.routeRequests.set(key, request);
    return request;
  }

  private async roadRoute(
    from: { latitude: number; longitude: number },
    to: { latitude: number; longitude: number },
  ) {
    const base =
      process.env.ROUTING_BASE_URL?.replace(/\/$/, '') ||
      'http://127.0.0.1:5000';

    const coordinates =
      `${from.longitude},${from.latitude};${to.longitude},${to.latitude}`;
    const url = new URL(
      `${base}/route/v1/driving/${coordinates}`,
    );
    url.searchParams.set('overview', 'false');
    url.searchParams.set('alternatives', 'false');
    url.searchParams.set('steps', 'false');
    url.searchParams.set('radiuses', '100;100');

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
      !Number.isFinite(route.duration) || Number(route.distance) < 0 || Number(route.duration) < 0
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

  async quoteForAddress(address: AddressLike) {
    const cfg = await this.config();
    if (!this.validPoint(cfg.distributorLatitude, cfg.distributorLongitude)) {
      throw new BadRequestException('A loja precisa configurar o ponto de retirada antes de oferecer entregas');
    }
    const destination = await this.resolveAddress(address);
    const route = await this.cachedRoute(
      { latitude: Number(cfg.distributorLatitude), longitude: Number(cfg.distributorLongitude) },
      destination,
    );
    const current = await this.config();
    if (current.pricingRevision !== cfg.pricingRevision) throw new BadRequestException('Os valores de entrega foram atualizados. Confirme a entrega novamente');
    if (route.distanceKm > Number(cfg.maxDistanceKm)) {
      throw new BadRequestException('Este endereço está fora da área atendida pela loja');
    }
    const baseFee = Number(cfg.baseFee), includedKm = Number(cfg.includedKm), pricePerKm = Number(cfg.pricePerAdditionalKm);
    const extraKm = Math.max(0, route.distanceKm - includedKm);
    const deliveryFee = Math.round((baseFee + extraKm * pricePerKm + Number.EPSILON) * 100) / 100;
    return {
      addressId: address.id, deliveryFee, distanceKm: Number(route.distanceKm.toFixed(3)),
      durationMinutes: route.durationMinutes, withinServiceArea: true, pricingMode: 'ROAD_ROUTE',
      baseFee, includedKm, pricePerAdditionalKm: pricePerKm, excessKm: Number(extraKm.toFixed(3)),
      pricingRevision: cfg.pricingRevision, courierSharePercent: 100, locationAccuracy: destination.accuracy,
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
