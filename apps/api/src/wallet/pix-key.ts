import { BadRequestException } from '@nestjs/common';

type PixType = 'CPF' | 'CNPJ' | 'EMAIL' | 'PHONE' | 'RANDOM';
function validCpf(value: string) {
  if (!/^\d{11}$/.test(value) || /^(\d)\1{10}$/.test(value)) return false;
  return [9, 10].every(size => {
    let sum = 0;
    for (let i = 0; i < size; i++) sum += Number(value[i]) * (size + 1 - i);
    const rest = (sum * 10) % 11;
    return Number(value[size]) === (rest === 10 ? 0 : rest);
  });
}
function validCnpj(value: string) {
  if (!/^\d{14}$/.test(value) || /^(\d)\1{13}$/.test(value)) return false;
  return [12, 13].every(size => {
    let factor = size - 7, sum = 0;
    for (let i = 0; i < size; i++) { sum += Number(value[i]) * factor--; if (factor < 2) factor = 9; }
    const rest = sum % 11;
    return Number(value[size]) === (rest < 2 ? 0 : 11 - rest);
  });
}
export function normalizePix(keyRaw: unknown, typeRaw?: unknown): { key: string; type: PixType } | null {
  const key = String(keyRaw ?? '').trim();
  if (!key) return null;
  const digits = key.replace(/\D/g, '');
  const aliases: Record<string, PixType> = { CPF: 'CPF', CNPJ: 'CNPJ', EMAIL: 'EMAIL', 'E-MAIL': 'EMAIL', PHONE: 'PHONE', CELULAR: 'PHONE', RANDOM: 'RANDOM', 'ALEATÓRIA': 'RANDOM' };
  const specified = String(typeRaw ?? '').trim().toUpperCase();
  const type = specified ? aliases[specified] : key.includes('@') ? 'EMAIL'
    : /^[\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12}$/i.test(key) ? 'RANDOM'
    : validCpf(digits) && !key.startsWith('+') ? 'CPF'
    : digits.length === 14 ? 'CNPJ' : 'PHONE';
  if (type === 'EMAIL' && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(key)) return { key: key.toLowerCase(), type };
  if (type === 'CPF' && validCpf(digits)) return { key: digits, type };
  if (type === 'CNPJ' && validCnpj(digits)) return { key: digits, type };
  if (type === 'RANDOM' && /^[\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12}$/i.test(key)) return { key: key.toLowerCase(), type };
  const phone = digits.length === 11 ? '55' + digits : digits;
  if (type === 'PHONE' && /^55[1-9]\d9\d{8}$/.test(phone)) return { key: '+' + phone, type };
  throw new BadRequestException('Confira a chave PIX e seu tipo antes de solicitar o saque.');
}
