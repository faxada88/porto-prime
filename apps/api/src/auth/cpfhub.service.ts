import {
  BadRequestException,
  HttpException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { createHash } from 'node:crypto';

export type VerifiedCpf = {
  cpf: string;
  name: string;
  birthDate: string;
  situation: string;
  regular: boolean;
};

@Injectable()
export class CpfHubService {
  private readonly cache = new Map<
    string,
    { expires: number; result: VerifiedCpf }
  >();
  private readonly pending = new Map<string, Promise<VerifiedCpf>>();
  private readonly limits = new Map<
    string,
    { expires: number; count: number }
  >();

  private validate(cpf: string, birthDate: string) {
    if (!/^\d{11}$/.test(cpf) || /^(\d)\1{10}$/.test(cpf))
      throw new BadRequestException('CPF inválido');
    for (const size of [9, 10]) {
      let sum = 0;
      for (let i = 0; i < size; i++) sum += Number(cpf[i]) * (size + 1 - i);
      const rest = (sum * 10) % 11;
      if ((rest === 10 ? 0 : rest) !== Number(cpf[size]))
        throw new BadRequestException('CPF inválido');
    }
    const digits = birthDate.replace(/\D/g, '');
    const day = Number(digits.slice(0, 2)),
      month = Number(digits.slice(2, 4)),
      year = Number(digits.slice(4));
    const date = new Date(Date.UTC(year, month - 1, day));
    if (
      digits.length !== 8 ||
      year < 1900 ||
      date.getUTCFullYear() !== year ||
      date.getUTCMonth() !== month - 1 ||
      date.getUTCDate() !== day ||
      date.getTime() > Date.now()
    ) {
      throw new BadRequestException('Informe uma data de nascimento válida');
    }
    return `${digits.slice(0, 2)}/${digits.slice(2, 4)}/${digits.slice(4)}`;
  }

  async lookup(
    rawCpf: string,
    rawBirthDate: string,
    client: string,
  ): Promise<VerifiedCpf> {
    const cpf = rawCpf.replace(/\D/g, '');
    const birthDate = this.validate(cpf, rawBirthDate);
    const now = Date.now();
    for (const [key, value] of this.cache)
      if (value.expires <= now) this.cache.delete(key);
    for (const [key, value] of this.limits)
      if (value.expires <= now) this.limits.delete(key);
    // Hash keys so CPF and date of birth never appear in logs or map keys.
    const key = createHash('sha256')
      .update(`${cpf}:${birthDate}`)
      .digest('hex');
    const cached = this.cache.get(key);
    if (cached) return cached.result;
    const inFlight = this.pending.get(key);
    if (inFlight) return inFlight;
    const clientKey = createHash('sha256').update(client).digest('hex');
    const limit = this.limits.get(clientKey) ?? {
      expires: now + 60_000,
      count: 0,
    };
    if (
      limit.count >= 5 ||
      this.pending.size >= 5 ||
      this.limits.size >= 1000
    ) {
      throw new HttpException(
        'Muitas consultas. Aguarde um minuto antes de tentar novamente.',
        429,
      );
    }
    limit.count++;
    this.limits.set(clientKey, limit);
    const promise = this.query(cpf, birthDate)
      .then((result) => {
        if (this.cache.size >= 1000)
          this.cache.delete(this.cache.keys().next().value!);
        // Reuse during the same registration; never persist a provider proof or API key.
        this.cache.set(key, { expires: Date.now() + 10 * 60_000, result });
        return result;
      })
      .finally(() => this.pending.delete(key));
    this.pending.set(key, promise);
    return promise;
  }

  private async query(cpf: string, birthDate: string): Promise<VerifiedCpf> {
    const apiKey = process.env.CPFHUB_API_KEY?.trim();
    const unavailable = () =>
      new ServiceUnavailableException(
        'Não foi possível consultar a Receita Federal agora. Tente novamente mais tarde.',
      );
    if (!apiKey) throw unavailable();
    let response: Response;
    try {
      response = await fetch('https://api.cpfhub.io/cpf/realtime', {
        method: 'POST',
        headers: { 'x-api-key': apiKey, 'Content-Type': 'application/json' },
        body: JSON.stringify({ cpf, birthDate }),
        signal: AbortSignal.timeout(60_000),
        redirect: 'error',
      });
    } catch {
      throw unavailable();
    }
    if (response.status === 400 || response.status === 422)
      throw new BadRequestException(
        'Confira o CPF e a data de nascimento. Os dados não foram confirmados pela Receita Federal.',
      );
    if (response.status === 429)
      throw new HttpException(
        'Consulta temporariamente limitada. Aguarde um minuto e tente novamente.',
        429,
      );
    if (!response.ok) throw unavailable();
    let payload: { success?: boolean; data?: Record<string, unknown> };
    try {
      payload = (await response.json()) as typeof payload;
    } catch {
      throw unavailable();
    }
    const data = payload.data;
    if (
      payload.success !== true ||
      !data ||
      data.cpf !== cpf ||
      typeof data.name !== 'string' ||
      !data.name.trim() ||
      typeof data.situation !== 'string' ||
      data.birthDate !== birthDate ||
      !(data.deathYear === null || Number.isInteger(data.deathYear))
    )
      throw unavailable();
    const situation = data.situation.trim().toUpperCase();
    return {
      cpf,
      name: data.name.trim(),
      birthDate,
      situation,
      regular: situation === 'REGULAR' && data.deathYear === null,
    };
  }
}
