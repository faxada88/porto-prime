import { parsePhoneNumberFromString } from 'libphonenumber-js/max';

export interface RegistrationPhone {
  stored: string;
  e164: string;
  aliases: string[];
}

/** Brazilian accounts keep their legacy national key; foreign numbers keep +DDI. */
export function normalizeRegistrationPhone(raw: string | null | undefined): RegistrationPhone | null {
  const value = raw?.trim();
  if (!value || value.length > 80) return null;
  const phone = parsePhoneNumberFromString(value, { defaultCountry: 'BR', extract: false });
  if (!phone || phone.ext || !phone.isValid() || !/^\+[1-9]\d{1,14}$/.test(phone.number)) return null;
  const e164 = phone.number;
  const stored = phone.countryCallingCode === '55' ? phone.nationalNumber : e164;
  // Never compare a foreign number without +DDI against a Brazilian legacy key.
  const aliases = [...new Set([stored, e164])];
  return { stored, e164, aliases };
}
