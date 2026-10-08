import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const html = fs.readFileSync(fileURLToPath(new URL('../web/index.html', import.meta.url)), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
assert.doesNotThrow(() => new vm.Script(script));
assert.ok(!script.includes('Pagamento confirmado'));

async function fixture(result) {
  const nodes = new Map();
  function node(id) {
    const value = { id, dataset: {}, style: {}, disabled: false, hidden: false, textContent: '', listeners: {}, addEventListener(event, fn) { this.listeners[event] = fn; } };
    nodes.set(id, value);
    return value;
  }
  const host = node('checkout');
  Object.defineProperty(host, 'innerHTML', { set(value) {
    assert.equal((value.match(/<button /g) || []).length, 1);
    for (const id of value.matchAll(/id="([^"]+)"/g)) node(id[1]);
  } });
  const ready = [];
  const paymentElement = { on(event, fn) { if (event === 'ready') ready.push(fn); }, mount() {} };
  let calls = 0;
  const stripe = {
    elements() { return { create() { return paymentElement; } }; },
    async confirmPayment() { calls++; if (result instanceof Error) throw result; return result; },
  };
  const window = { Stripe: () => stripe, dispatchEvent() {}, location: { href: 'https://example.test/' }, setTimeout };
  const context = vm.createContext({ window, document: { getElementById(id) { return nodes.get(id); } }, CustomEvent: class {} });
  vm.runInContext(script, context);
  const states = [];
  await window.portoPrimeStripeMount('checkout', 'pk_test', 'test_client_secret', 0, state => states.push(state));
  const button = nodes.get('checkout-pay');
  assert.equal(button.disabled, true);
  ready.forEach(fn => fn());
  assert.equal(button.disabled, false);
  await button.listeners.click();
  return { button, states, calls, nodes };
}

for (const status of ['succeeded', 'processing']) {
  const f = await fixture({ paymentIntent: { status } });
  assert.equal(f.button.hidden, true);
  assert.equal(f.button.disabled, true);
  assert.deepEqual(f.states, ['submitting', status]);
  await f.button.listeners.click();
  assert.equal(f.calls, 1);
}
for (const result of [{ error: { message: 'Cartão recusado' } }, new Error('Falha de rede'), { paymentIntent: { status: 'requires_action' } }]) {
  const f = await fixture(result);
  assert.equal(f.button.hidden, false);
  assert.equal(f.button.disabled, false);
  assert.equal(f.button.textContent, 'Pagar');
  assert.deepEqual(f.states, ['submitting', 'error']);
  assert.equal(f.nodes.get('checkout-error').style.display, 'block');
}
console.log('5 cenários Stripe.js passaram: botão único, sucesso, processamento, recusa, rede e confirmação incompleta. Sem transações reais.');
