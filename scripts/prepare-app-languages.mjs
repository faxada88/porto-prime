import { isCompleteTranslation, translateKeepingPlaceholders } from './translation-placeholders.mjs';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
const directory = fileURLToPath(new URL('../apps/mobile/assets/localization/', import.meta.url));
const source = JSON.parse(await readFile(directory + 'source.json', 'utf8'));
const hash = createHash('sha256').update(JSON.stringify(source)).digest('hex');
if (process.argv.includes('--check')) {
  let complete = false;
  try {
    const version = JSON.parse(await readFile(directory + 'version.json', 'utf8'));
    complete = version.sourceSha256 === hash;
    for (const language of ['es', 'en']) {
      const dictionary = JSON.parse(await readFile(directory + language + '.json', 'utf8'));
      complete = complete && source.every(phrase => isCompleteTranslation(phrase, dictionary[phrase]));
    }
  } catch { complete = false; }
  console.log(complete ? 'Arquivos de idioma completos.' : 'Arquivos de idioma precisam ser concluidos. Retomando o cache salvo.');
  process.exit(complete ? 0 : 2);
}
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
    if (isCompleteTranslation(phrase, cache[phrase])) { output[phrase] = cache[phrase]; continue; }
    let translated;
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        translated = await translateKeepingPlaceholders(phrase, async query => {
          const response = await fetch(base + '/translate', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ q: query, source: 'pt', target: language, format: 'text' }),
            signal: AbortSignal.timeout(180000),
          });
          if (!response.ok) throw new Error(`Translator HTTP ${response.status}`);
          return (await response.json()).translatedText;
        });
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
