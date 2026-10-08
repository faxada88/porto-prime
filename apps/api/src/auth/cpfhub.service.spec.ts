import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { CpfHubService } from './cpfhub.service.js';

// Mocked provider fixtures: no real CPF query, credential or credit consumption.
const cpf = '52998224725',
  birthDate = '15/06/1990';
const payload = (changes: Record<string, unknown> = {}) => ({
  success: true,
  data: {
    cpf,
    birthDate,
    name: 'NOME DE TESTE',
    situation: 'REGULAR',
    deathYear: null,
    ...changes,
  },
});
const response = (changes: Record<string, unknown> = {}, status = 200) =>
  new Response(JSON.stringify(payload(changes)), { status });

describe('CPFHub registration verification', () => {
  let service: CpfHubService;
  beforeEach(() => {
    service = new CpfHubService();
    vi.stubEnv('CPFHUB_API_KEY', 'test-key-not-a-secret');
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(response()));
  });
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
  });
  it('normalizes input and uses the realtime provider contract', async () => {
    expect(
      await service.lookup('529.982.247-25', '15061990', 'client'),
    ).toEqual({
      cpf,
      birthDate,
      name: 'NOME DE TESTE',
      situation: 'REGULAR',
      regular: true,
    });
    expect(fetch).toHaveBeenCalledWith(
      'https://api.cpfhub.io/cpf/realtime',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ cpf, birthDate }),
        headers: {
          'x-api-key': 'test-key-not-a-secret',
          'Content-Type': 'application/json',
        },
      }),
    );
  });
  it.each([
    'PENDENTE DE REGULARIZAÇÃO',
    'SUSPENSA',
    'CANCELADA',
    'NULA',
    'TITULAR FALECIDO',
    'UNKNOWN',
  ])('blocks %s even with HTTP 200', async (situation) => {
    vi.mocked(fetch).mockResolvedValue(response({ situation }));
    expect((await service.lookup(cpf, birthDate, 'client')).regular).toBe(
      false,
    );
  });
  it('blocks an existing death record', async () => {
    vi.mocked(fetch).mockResolvedValue(response({ deathYear: 2020 }));
    expect((await service.lookup(cpf, birthDate, 'client')).regular).toBe(
      false,
    );
  });
  it.each([
    ['11111111111', birthDate],
    [cpf, '31/02/1990'],
    [cpf, '15/06/2990'],
  ])('validates input without a paid query', async (document, date) => {
    await expect(service.lookup(document, date, 'client')).rejects.toThrow();
    expect(fetch).not.toHaveBeenCalled();
  });
  it.each([
    { cpf: '12345678909' },
    { name: '' },
    { birthDate: '16/06/1990' },
    { deathYear: undefined },
  ])('fails closed on incomplete or mismatched data', async (changes) => {
    vi.mocked(fetch).mockResolvedValue(response(changes));
    await expect(service.lookup(cpf, birthDate, 'client')).rejects.toThrow(
      'Não foi possível consultar',
    );
  });
  it('deduplicates concurrent queries and reuses the server verification at registration', async () => {
    await Promise.all([
      service.lookup(cpf, birthDate, 'client'),
      service.lookup(cpf, birthDate, 'client'),
    ]);
    await service.lookup(cpf, birthDate, 'client');
    expect(fetch).toHaveBeenCalledTimes(1);
  });
  it('does not retry or expose upstream errors', async () => {
    vi.mocked(fetch).mockResolvedValue(
      response({ secret: 'sensitive-upstream-message' }, 403),
    );
    await expect(service.lookup(cpf, birthDate, 'client')).rejects.toThrow(
      'Não foi possível consultar',
    );
    expect(fetch).toHaveBeenCalledTimes(1);
  });
  it('distinguishes incorrect input from irregular registration', async () => {
    vi.mocked(fetch).mockResolvedValue(response({}, 422));
    await expect(service.lookup(cpf, birthDate, 'client')).rejects.toThrow(
      'Confira o CPF e a data',
    );
  });
  it('requires a server-side API key', async () => {
    vi.stubEnv('CPFHUB_API_KEY', '');
    await expect(service.lookup(cpf, birthDate, 'client')).rejects.toThrow(
      'Não foi possível consultar',
    );
    expect(fetch).not.toHaveBeenCalled();
  });
  it('limits new paid attempts', async () => {
    vi.mocked(fetch).mockResolvedValue(response({}, 503));
    for (let i = 0; i < 5; i++)
      await expect(service.lookup(cpf, birthDate, 'client')).rejects.toThrow();
    await expect(service.lookup(cpf, birthDate, 'client')).rejects.toThrow(
      'Muitas consultas',
    );
    expect(fetch).toHaveBeenCalledTimes(5);
  });
});
