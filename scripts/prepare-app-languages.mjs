import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
const directory = fileURLToPath(new URL('../apps/mobile/assets/localization/', import.meta.url));
const source = JSON.parse(await readFile(directory + 'source.json', 'utf8'));
const hash = createHash('sha256').update(JSON.stringify(source)).digest('hex');
const base = process.env.PORTO_TRANSLATOR_URL || 'http://127.0.0.1:5040';
const overrides = {
  'Idioma': ['Idioma', 'Language'], 'Início': ['Inicio', 'Home'], 'Pedidos': ['Pedidos', 'Orders'],
  'Carrinho': ['Carrito', 'Cart'], 'Conta': ['Cuenta', 'Account'],
  'Pix': ['Pix', 'Pix'], 'CPF': ['CPF', 'CPF'], 'Porto Prime': ['Porto Prime', 'Porto Prime'],
  'Nome completo': ['Nombre completo', 'Full name'], 'Celular / WhatsApp': ['Teléfono / WhatsApp', 'Phone / WhatsApp'],
};
await mkdir(directory, { recursive: true });
for (const [index, language] of ['es', 'en'].entries()) {
  let cache = {};
  try { const previous = JSON.parse(await readFile(directory + language + '.json', 'utf8')); cache = previous; } catch {}
  const output = {};
  let completed = 0;
  for (const phrase of source) {
    if (overrides[phrase]) { output[phrase] = overrides[phrase][index]; continue; }
    if (typeof cache[phrase] === 'string' && cache[phrase].length) { output[phrase] = cache[phrase]; continue; }
    const protectedText = phrase.replace(/\{(\d+)\}/g, (_, id) => `ZXQ${id}QXZ`);
    let translated;
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const response = await fetch(base + '/translate', {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ q: protectedText, source: 'pt', target: language, format: 'text' }),
          signal: AbortSignal.timeout(180000),
        });
        if (!response.ok) throw new Error(`Translator HTTP ${response.status}`);
        const result = await response.json();
        translated = result.translatedText;
        if (typeof translated !== 'string' || !translated.trim()) throw new Error('Empty translation');
        translated = translated.replace(/ZXQ\s*(\d+)\s*QXZ/gi, (_, id) => `{${id}}`);
        const expected = [...phrase.matchAll(/\{\d+\}/g)].map(x => x[0]).sort();
        const actual = [...translated.matchAll(/\{\d+\}/g)].map(x => x[0]).sort();
        if (JSON.stringify(expected) !== JSON.stringify(actual)) throw new Error('Translation changed a dynamic placeholder');
        break;
      } catch (error) { if (attempt === 2) throw new Error(`${language}: ${phrase}: ${error.message}`); }
    }
    output[phrase] = translated;
    if (++completed % 25 === 0) {
      await writeFile(directory + language + '.json', JSON.stringify({ ...cache, ...output }, null, 2));
      console.log(`${language}: ${Object.keys(output).length}/${source.length}`);
    }
  }
  await writeFile(directory + language + '.json', JSON.stringify(output, null, 2) + '\n');
}
await writeFile(directory + 'version.json', JSON.stringify({ sourceSha256: hash, count: source.length }) + '\n');
console.log(`Interface: ${source.length} phrases available in Portuguese, Spanish and English.`);
