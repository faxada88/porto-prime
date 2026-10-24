import { describe, it, expect, vi } from 'vitest';
import { getCountries, getCountryCallingCode } from 'libphonenumber-js/max';
import examples from 'libphonenumber-js/mobile/examples';
vi.mock('../prisma/prisma.service.js', () => ({ PrismaService: class {} }));
vi.mock('./cpfhub.service.js', () => ({ CpfHubService: class {} }));
import { AuthService } from './auth.service.js';
import { normalizeRegistrationPhone } from './international-phone.js';

describe('International registration phones', () => {
 it('preserves Brazilian legacy identities and matches international aliases', () => {
  const local = normalizeRegistrationPhone('(73) 99999-9999')!;
  const global = normalizeRegistrationPhone('+55 73 99999-9999')!;
  expect(local).toEqual(global);
  expect(global.stored).toBe('73999999999');
  expect(global.aliases).toEqual(['73999999999', '+5573999999999']);
 });
 it.each(['+12025550123', '+447400123456', '+34612345678', '+33612345678', '+390669821', '+5491123456789'])(
  'accepts and retains the country calling code in %s', (number) => {
   const normalized = normalizeRegistrationPhone(number)!;
   expect(normalized.stored).toBe(number);
   expect(normalized.aliases).toEqual([number]);
  });
 it('retains the significant Italian zero', () => {
  expect(normalizeRegistrationPhone('+39 06 69821')?.e164).toBe('+390669821');
 });
 it('rejects unknown calling codes, invalid lengths, prose and extensions', () => {
  for (const value of ['+999123456789', '+1', '123', '+12025550123123456789', 'call +12025550123', '+12025550123 ext. 5']) {
   expect(normalizeRegistrationPhone(value)).toBeNull();
  }
 });
 it('covers valid mobile examples across all available country metadata', () => {
  for (const country of getCountries()) {
   const national = examples[country];
   if (national) expect(normalizeRegistrationPhone('+' + getCountryCallingCode(country) + national),
    country).not.toBeNull();
  }
 });
 function service(rows: {phone: string; email: string}[]) {
  const findFirst = vi.fn(async (query: any) => {
   const aliases = query.where.phone?.in ?? query.where.OR?.find((p: any) => p.phone)?.phone?.in ?? [];
   return rows.find((row) => aliases.includes(row.phone)) ?? null;
  });
  const instance = Object.create(AuthService.prototype) as AuthService;
  Object.assign(instance, { prisma: { user: { findFirst } } });
  return { instance, findFirst };
 }
 it('does not let +55 create a duplicate of an existing national Brazilian number', async () => {
  const { instance, findFirst } = service([{ phone: '73999999999', email: 'existing@example.test' }]);
  await expect(instance.availability('phone', '+5573999999999')).resolves.toEqual({ valid: true, available: false });
  expect(findFirst).toHaveBeenCalledWith({ where: { phone: { in: ['73999999999', '+5573999999999'] } }, select: { id: true } });
 });
 it('keeps US +1 identities distinct from an unrelated 11-digit Brazilian legacy key', async () => {
  const { instance } = service([{ phone: '12025550123', email: 'existing@example.test' }]);
  await expect(instance.availability('phone', '+12025550123')).resolves.toEqual({ valid: true, available: true });
 });
 it('also enforces the alias check when registering, not just in availability', async () => {
  const { instance } = service([{ phone: '73999999999', email: 'existing@example.test' }]);
  await expect(instance.register({ name: 'Visitor', email: 'new@example.test', phone: '+5573999999999',
   password: 'Example123', role: 'CUSTOMER' } as any)).rejects.toThrow('Telefone já cadastrado');
 });
});
