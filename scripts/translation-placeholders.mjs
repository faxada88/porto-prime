const tokens = text => [...text.matchAll(/\{\d+\}/g)].map(match => match[0]).sort();

export function isCompleteTranslation(source, target) {
  return typeof target === 'string' && target.trim().length > 0
    && JSON.stringify(tokens(source)) === JSON.stringify(tokens(target));
}

export async function translateKeepingPlaceholders(source, translate) {
  const protectedSource = source.replace(/\{(\d+)\}/g, (_, id) => `ZXQ${id}QXZ`);
  let target = await translate(protectedSource);
  if (typeof target === 'string') {
    target = target.replace(/ZXQ\s*(\d+)\s*QXZ/gi, (_, id) => `{${id}}`);
    if (isCompleteTranslation(source, target)) return target;
  }
  if (!/\{\d+\}/.test(source)) throw new Error('Empty or invalid translation');
  // A model may rewrite protected tokens. Translate only literal segments in
  // that case; interpolation markers never enter the translator in this path.
  const parts = source.split(/(\{\d+\})/g);
  const translated = [];
  for (const part of parts) {
    if (/^\{\d+\}$/.test(part) || !/[\p{L}]/u.test(part)) {
      translated.push(part);
      continue;
    }
    const [, leading, core, trailing] = part.match(/^(\s*)([\s\S]*?)(\s*)$/);
    const value = await translate(core);
    if (typeof value !== 'string' || !value.trim()) throw new Error('Empty translation segment');
    translated.push(leading + value.trim() + trailing);
  }
  target = translated.join('');
  if (!isCompleteTranslation(source, target)) throw new Error('Translation changed a dynamic placeholder');
  return target;
}
