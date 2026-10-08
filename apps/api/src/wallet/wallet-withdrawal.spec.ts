import { describe, expect, it, vi } from 'vitest';
vi.mock('../prisma/prisma.service.js', () => ({ PrismaService: class {} }));
vi.mock('../auth/auth.service.js', () => ({ AuthService: class {} }));
vi.mock('../realtime/realtime.gateway.js', () => ({ RealtimeGateway: class {} }));
import { WalletService } from './wallet.service.js';
import { normalizePix } from './pix-key.js';

function fixture(role = 'COURIER') {
  const courier: any = { id: 'courier', userId: 'user', pixKey: null, pixKeyType: null, onboardingData: { pixKey: 'driver@example.test' } };
  let withdrawal: any;
  const entries: any[] = [];
  const tx: any = {
    $queryRawUnsafe: vi.fn(async () => []),
    courierProfile: { findUnique: async () => courier, update: async ({ data }: any) => Object.assign(courier, data) },
    courierLedgerEntry: {
      aggregate: async () => ({ _sum: { amount: 50 } }),
      create: async ({ data }: any) => { entries.push(data); return data; },
      findUnique: async ({ where }: any) => entries.find(e => e.idempotencyKey === where.idempotencyKey),
    },
    withdrawal: {
      create: async ({ data }: any) => { withdrawal = data; return data; },
      findUnique: async () => withdrawal,
      update: async ({ data }: any) => Object.assign(withdrawal, data),
    },
  };
  tx.$transaction = async (fn: any) => fn(tx);
  const auth: any = { authenticate: async () => ({ id: 'user', role }) };
  const realtime: any = { emitToUser: vi.fn(), emitToRole: vi.fn() };
  return { service: new WalletService(tx, auth, realtime), courier, tx, entries, get withdrawal() { return withdrawal; } };
}
describe('PIX and manual withdrawal flow', () => {
  it.each([
    ['529.982.247-25', 'CPF', '52998224725'],
    ['DRIVER@example.test', 'E-mail', 'driver@example.test'],
    ['(73) 99999-9999', 'Celular', '+5573999999999'],
    ['d9d3152e-1290-4f5e-a332-96ccf1f7db41', 'Aleatória', 'd9d3152e-1290-4f5e-a332-96ccf1f7db41'],
  ])('normalizes %s without losing its type', (key, type, expected) => {
    expect(normalizePix(key, type)?.key).toBe(expected);
  });
  it('rejects an invalid explicit CPF and allows an omitted optional PIX', () => {
    expect(() => normalizePix('11111111111', 'CPF')).toThrow();
    expect(normalizePix('')).toBeNull();
  });
  it('recovers an existing registration PIX, saves it, snapshots it and reserves only once', async () => {
    const f = fixture();
    await f.service.requestWithdrawal(20, 'test');
    expect(f.courier.pixKeyType).toBe('EMAIL');
    expect(f.withdrawal.pixKey).toBe('driver@example.test');
    expect(f.entries).toHaveLength(1);
    expect(f.entries[0].amount).toBe(-20);
  });
  it('lets a courier explicitly register a missing PIX while requesting a withdrawal', async () => {
    const f = fixture(); f.courier.onboardingData = {};
    await f.service.requestWithdrawal(20, 'test', { key: 'new@example.test', type: 'EMAIL' });
    expect(f.courier.pixKey).toBe('new@example.test');
    expect(f.withdrawal.pixKey).toBe('new@example.test');
    expect(f.entries[0].amount).toBe(-20);
  });
  it('rejects invalid replacement PIX without reserving funds or changing the saved key', async () => {
    const f = fixture();
    await expect(f.service.requestWithdrawal(20, 'test', { key: '11111111111', type: 'CPF' })).rejects.toThrow('Confira');
    expect(f.courier.pixKey).toBeNull();
    expect(f.entries).toHaveLength(0);
  });
  it('requires sufficient balance and rejects absent PIX', async () => {
    const f = fixture();
    await expect(f.service.requestWithdrawal(51, 'test')).rejects.toThrow('Saldo');
    f.courier.pixKey = null; f.courier.pixKeyType = null; f.courier.onboardingData = {};
    await expect(f.service.requestWithdrawal(20, 'test')).rejects.toThrow('Cadastre');
    expect(f.entries).toHaveLength(0);
  });
  it('requires admin access and processing before paid; final status cannot be reversed', async () => {
    const f = fixture(); await f.service.requestWithdrawal(20, 'test');
    await expect(f.service.updateWithdrawalStatus(f.withdrawal.id, 'PROCESSING', 'test')).rejects.toThrow('administrador');
    const admin: any = f.service; admin.auth.authenticate = async () => ({ id: 'admin', role: 'ADMIN' });
    await expect(f.service.updateWithdrawalStatus(f.withdrawal.id, 'PAID', 'test')).rejects.toThrow('processamento');
    await f.service.updateWithdrawalStatus(f.withdrawal.id, 'PROCESSING', 'test');
    await f.service.updateWithdrawalStatus(f.withdrawal.id, 'PAID', 'test');
    await expect(f.service.updateWithdrawalStatus(f.withdrawal.id, 'REJECTED', 'test')).rejects.toThrow('encerrado');
    expect(f.tx.$queryRawUnsafe).toHaveBeenCalledWith(expect.stringContaining('"Withdrawal"'), f.withdrawal.id);
    expect(f.entries).toHaveLength(1);
  });
  it('rejecting returns funds once, including repeated admin submissions', async () => {
    const f = fixture(); await f.service.requestWithdrawal(20, 'test');
    const admin: any = f.service; admin.auth.authenticate = async () => ({ id: 'admin', role: 'ADMIN' });
    await f.service.updateWithdrawalStatus(f.withdrawal.id, 'REJECTED', 'test');
    await f.service.updateWithdrawalStatus(f.withdrawal.id, 'REJECTED', 'test');
    expect(f.entries.filter(e => e.type === 'REVERSAL')).toHaveLength(1);
    expect(f.entries[1].amount).toBe(20);
  });
});
