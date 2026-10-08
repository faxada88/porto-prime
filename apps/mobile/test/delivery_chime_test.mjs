import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
const html = fs.readFileSync(new URL('../web/index.html', import.meta.url), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const events = {}, oscillators = [];
let contexts = 0;
class AudioContext {
  state = 'running'; currentTime = 0; destination = {};
  constructor() { contexts++; }
  createOscillator() { const oscillator = { frequency: {}, connect() {}, disconnect() {}, start(at) { this.started = at; }, stop(at) { this.stopped = at; } }; oscillators.push(oscillator); return oscillator; }
  createGain() { return { connect() {}, disconnect() {}, gain: { setValueAtTime() {}, linearRampToValueAtTime() {}, exponentialRampToValueAtTime() {} } }; }
}
const window = { AudioContext, addEventListener(name, fn) { events[name] = fn; } };
vm.runInNewContext(script, { window });
window.portoPrimePlayDeliveryChime();
assert.equal(contexts, 0);
events.pointerdown(); events.keydown();
assert.equal(contexts, 1);
window.portoPrimePlayDeliveryChime();
assert.equal(oscillators.length, 3);
assert.deepEqual(oscillators.map(o => o.frequency.value), [659.25, 830.61, 987.77]);
assert.ok(oscillators.every(o => o.stopped - o.started < 0.5));
oscillators.forEach(o => o.onended());
console.log('Toque: ativação por gesto, contexto único, três notas curtas e descarte verificados.');
