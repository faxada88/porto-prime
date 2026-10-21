import { jsonForScript } from './secure-checkout.js';

export function secureCheckoutPage(config: {
  publishableKey: string; clientSecret: string; amount: number; testMode: boolean;
  name: string; email: string; nonce: string;
}) {
  const { nonce, ...publicConfig } = config;
  return `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="referrer" content="no-referrer"><meta name="theme-color" content="#17130f">
<title>Pagamento seguro · Porto Prime</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#faf8f3;color:#211c16;font:15px/1.55 system-ui,-apple-system,sans-serif}
header{background:#17130f;color:#f1c46b;padding:24px max(20px,calc((100vw - 580px)/2));letter-spacing:3px;font-weight:800;font-size:13px}
main{max-width:620px;margin:auto;padding:24px 20px max(32px,env(safe-area-inset-bottom))}
h1{font-size:28px;line-height:1.2;letter-spacing:-1px;margin:6px 0 12px}h2{font-size:18px;margin:0 0 10px}
p{margin:8px 0}.muted{color:#70675c;font-size:13px}.eyebrow{font-size:11px;letter-spacing:1.5px;color:#715019;font-weight:800}
.total{font-size:38px;font-weight:800;letter-spacing:-1px}.card{background:white;border:1px solid #e8dfd1;border-radius:22px;padding:22px;margin:18px 0}
.note{border-radius:12px;padding:12px;background:#f8eacb;color:#715019;font-size:12px;margin:16px 0}
button,.button{display:block;width:100%;padding:17px 20px;background:#17130f;color:#f1c46b;border:0;border-radius:14px;font:800 15px system-ui;cursor:pointer;text-align:center;text-decoration:none}
button:disabled{opacity:.5;cursor:wait}button.secondary{background:#f7eacd;color:#715019;margin-top:12px}
#error{color:#a63220;background:#fff1ed;padding:14px;border-radius:12px;margin:14px 0}
[hidden]{display:none!important}#pending{padding:20px;border:1px solid #dfc28c;border-radius:18px;background:#fffaf0}
#qr{display:block;max-width:240px;width:100%;margin:16px auto;background:white}
#pix-code{width:100%;font:12px monospace;min-height:90px;border:1px solid #d4c2a3;border-radius:10px;padding:10px;background:white;color:#211c16}
footer{text-align:center;color:#70675c;font-size:12px;padding-top:20px}.success{background:#eaf6ef!important;border-color:#7ba88e!important}
.back{background:transparent!important;color:#70675c!important;font-size:13px;margin-top:8px}
</style><script src="https://js.stripe.com/v3/" defer></script></head>
<body><header>♛ PORTO PRIME <span style="float:right;letter-spacing:0;font-weight:500">Pagamento seguro</span></header>
<main><div class="eyebrow">ÚLTIMA ETAPA</div><h1>Do seu jeito.<br>Com segurança.</h1>
<p class="muted">Escolha entre as formas disponíveis para sua compra. Seus dados são tratados diretamente pelo Stripe.</p>
<div class="card"><div class="eyebrow">TOTAL A PAGAR</div><div class="total" id="total"></div><p class="muted">O saldo Porto Prime escolhido já foi descontado deste valor.</p></div>
<div id="test" class="note" hidden>Ambiente de teste. Nenhuma cobrança real será realizada.</div>
<section class="card" id="form"><h2>Como você prefere pagar?</h2>
<p class="muted">Pix em primeiro lugar. Cartões, boleto e carteiras compatíveis aparecem abaixo conforme a disponibilidade do Stripe.</p>
<div id="express"></div><div id="payment" style="margin-top:18px"></div>
<div id="error" role="alert" hidden></div><button id="pay" disabled style="margin-top:20px">Carregando pagamento…</button>
<p class="muted" style="margin-top:14px">Boleto não confirma na hora. Seu pedido só será liberado após a confirmação do pagamento.</p></section>
<section id="pending" role="status" aria-live="polite" hidden><h2 id="status-title">Aguardando pagamento</h2><p id="status-text"></p>
<div id="pix" hidden><img id="qr" alt="Código QR Pix"><textarea id="pix-code" readonly aria-label="Código Pix Copia e Cola"></textarea><button id="copy" class="secondary">Copiar código Pix</button><p id="expires" class="muted"></p></div>
<a id="voucher" class="button" target="_blank" rel="noopener noreferrer" hidden style="margin-top:16px">Abrir boleto</a>
<button id="check" class="secondary">Verificar pagamento</button>
<button id="change" class="back">Revisar forma de pagamento</button></section>
<button id="back" class="back">Voltar</button>
<footer>Fechou o pagamento? Retorne ao app Porto Prime.<br>O pedido é atualizado após a confirmação.</footer></main>
<script nonce="${nonce}">
window.addEventListener('DOMContentLoaded',async function(){
 const config=${jsonForScript(publicConfig)};
 const el=id=>document.getElementById(id);
 el('total').textContent=new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(config.amount);
 el('test').hidden=!config.testMode;
 el('back').onclick=()=>{if(history.length>1)history.back();else{el('back').textContent='Retorne ao aplicativo Porto Prime';}};
 let stripe,elements,payment,express,timer,busy=false,requesting=false,completed=false,mounted=false;
 const returnUrl=location.origin+location.pathname+'?'+new URLSearchParams({
  orderId:new URLSearchParams(location.search).get('orderId')||'',
  expires:new URLSearchParams(location.search).get('expires')||'',
  token:new URLSearchParams(location.search).get('token')||''
 }).toString();
 // Remove Stripe redirect secrets from browser history; never send them to our server.
 history.replaceState(null,'',returnUrl);
 const fail=message=>{el('error').hidden=false;el('error').textContent=message;el('form').hidden=false;};
 const validStripeUrl=value=>{try{const u=new URL(value);return u.protocol==='https:'&&(u.hostname==='stripe.com'||u.hostname.endsWith('.stripe.com'));}catch(_){return false;}};
 const poll=()=>{if(!timer&&!completed)timer=setInterval(()=>{if(!document.hidden)check();},5000);};
 async function showIntent(intent){
  if(!intent)return false;
  const action=intent.next_action||{};
  const pix=action.pix_display_qr_code,voucher=action.boleto_display_details;
  if(intent.status==='succeeded'){
   completed=true;clearInterval(timer);timer=null;
   el('form').hidden=true;el('pending').hidden=false;el('pending').classList.add('success');
   el('status-title').textContent='Pagamento recebido';
   el('status-text').textContent='Retorne ao aplicativo para acompanhar seu pedido. A confirmação será verificada pela Porto Prime.';
   ['pix','voucher','check','change'].forEach(id=>el(id).hidden=true);return true;
  }
  if(intent.status==='processing'||pix||voucher){
   el('form').hidden=true;el('pending').hidden=false;
   el('status-title').textContent=pix?'Pague com Pix':voucher?'Seu boleto está pronto':'Pagamento em processamento';
   el('status-text').textContent=pix?'Copie o código ou leia o QR Code no aplicativo do seu banco. A geração do código ainda não é um pagamento.':voucher?'Pague o boleto e aguarde a compensação. O pedido ainda não foi liberado para preparação.':'Estamos aguardando a confirmação. Não é necessário pagar novamente.';
   el('pix').hidden=!pix;el('voucher').hidden=!voucher;
   if(pix){
    el('pix-code').value=pix.data||'';
    el('qr').hidden=!validStripeUrl(pix.image_url_png);
    if(!el('qr').hidden)el('qr').src=pix.image_url_png;
    el('expires').textContent=pix.expires_at?'Válido até '+new Date(pix.expires_at*1000).toLocaleString('pt-BR'):'';
   }
   if(voucher&&validStripeUrl(voucher.hosted_voucher_url))el('voucher').href=voucher.hosted_voucher_url;
   else el('voucher').hidden=true;
   el('change').hidden=intent.status==='processing';poll();return true;
  }
  el('pending').hidden=true;el('form').hidden=false;return false;
 }
 async function check(){
  if(requesting||busy||completed||!stripe)return;
  requesting=true;
  try{const result=await stripe.retrievePaymentIntent(config.clientSecret);if(result.error)throw result.error;const pending=await showIntent(result.paymentIntent);if(!pending&&!mounted)mount();}
  catch(error){if(!el('pending').hidden)el('status-text').textContent='Não foi possível verificar agora. Seu pagamento foi preservado. Tente verificar novamente.';else fail(error.message||'Não foi possível verificar o pagamento.');}
  finally{requesting=false;}
 }
 async function confirm(event){
  if(busy||completed)return;
  busy=true;el('pay').disabled=true;el('pay').textContent='Processando…';el('error').hidden=true;
  try{
   const result=await stripe.confirmPayment({elements,redirect:'if_required',confirmParams:{return_url:returnUrl}});
   if(result.error){if(event&&event.paymentFailed)event.paymentFailed({reason:'fail'});throw result.error;}
   if(!(await showIntent(result.paymentIntent)))fail('Pagamento não concluído. Revise os dados e tente novamente.');
  }catch(error){fail(error.message||'Não foi possível concluir o pagamento.');}
  finally{busy=false;el('pay').disabled=false;el('pay').textContent='Confirmar pagamento';}
 }
 function mount(){
  if(mounted)return;mounted=true;
  elements=stripe.elements({clientSecret:config.clientSecret,locale:'pt-BR',appearance:{theme:'stripe',variables:{
   colorPrimary:'#715019',colorBackground:'#ffffff',colorText:'#211c16',colorDanger:'#a63220',
   fontFamily:'system-ui, sans-serif',borderRadius:'12px',spacingUnit:'4px'
  }}});
  express=elements.create('expressCheckout');express.mount('#express');express.on('confirm',confirm);
  payment=elements.create('payment',{layout:'accordion',paymentMethodOrder:['pix','card','link','boleto'],
   wallets:{applePay:'never',googlePay:'never'},
   defaultValues:{billingDetails:{name:config.name,email:config.email,address:{country:'BR'}}}});
  payment.mount('#payment');
  payment.on('ready',()=>{el('pay').disabled=false;el('pay').textContent='Confirmar pagamento';});
  payment.on('loaderror',e=>fail(e.error?.message||'Não foi possível carregar. Recarregue esta página.'));
  payment.on('change',e=>{el('pay').textContent=e.value?.type==='pix'?'Gerar Pix seguro':e.value?.type==='boleto'?'Gerar boleto':'Confirmar pagamento';});
 }
 el('pay').onclick=confirm;el('check').onclick=check;
 el('change').onclick=()=>{el('pending').hidden=true;el('form').hidden=false;if(!mounted)mount();};
 el('copy').onclick=async()=>{try{if(navigator.clipboard&&window.isSecureContext)await navigator.clipboard.writeText(el('pix-code').value);else{el('pix-code').focus();el('pix-code').select();if(!document.execCommand('copy'))throw Error();}el('copy').textContent='Código copiado';}catch(_){el('pix-code').focus();el('pix-code').select();el('copy').textContent='Selecione e copie o código acima';}};
 document.addEventListener('visibilitychange',()=>{if(!document.hidden)check();});
 window.addEventListener('pagehide',()=>{clearInterval(timer);timer=null;});
 window.addEventListener('pageshow',()=>{if(stripe&&!completed){poll();check();}});
 try{if(!window.Stripe)throw Error('Não foi possível carregar o Stripe. Verifique sua conexão e recarregue a página.');
  stripe=Stripe(config.publishableKey,{locale:'pt-BR'});await check();if(!completed&&!mounted&&el('pending').hidden)mount();poll();
 }catch(error){fail(error.message||'Não foi possível iniciar o pagamento.');}
});
</script></body></html>`;
}
