# Correção da confirmação de pagamento

O checkout atual cria um PaymentIntent. A escuta local deve receber `payment_intent.succeeded`, `payment_intent.payment_failed` e `payment_intent.canceled`, e não apenas eventos de Checkout Session. Execute `bash scripts/start-stripe.sh` em um terminal dedicado. O `STRIPE_WEBHOOK_SECRET` da API deve corresponder ao `whsec_...` exibido por essa escuta; reinicie Nest depois de alterar o ambiente.

O formulário web tem somente um botão **Pagar**. Ele fica desabilitado durante a confirmação, recupera-se após recusa/erro e desaparece quando o Stripe retorna succeeded/processing. O retorno chama Flutter diretamente; não apresenta um botão desabilitado “Pagamento confirmado”. A aprovação local do Stripe não marca o pedido como pago.

`POST /api/payments/reconcile`, autenticado, recebe somente `{ "orderId": "..." }`. O cliente só pode consultar um pedido próprio. O servidor busca o PaymentIntent salvo no pedido usando a chave secreta e confere ID, metadados de cliente/pedido, moeda BRL, valor e recebimento integral antes de atualizar o banco. Webhook assinado e reconciliação reutilizam a mesma confirmação. O checkout reutiliza o PaymentIntent existente e usa uma chave de idempotência ao criar outro, evitando uma nova cobrança ao reabrir o mesmo pedido. A atualização é idempotente e emite o evento já existente para cliente/Admin. Apenas um pedido PENDING muda para CONFIRMED; estados posteriores não regridem.

O app verifica após a confirmação, com uma chamada em andamento por vez. Falha de comunicação ou espera de 90 segundos oferece **Verificar pedido**, sem confirmar outro pagamento. Após PAID no backend, mantém o modal de sucesso e acesso ao acompanhamento já existentes. A reconciliação permite recuperar o fluxo mesmo que o webhook local esteja atrasado ou ausente enquanto o app está aberto. O webhook continua necessário para atualizações sem o cliente presente.

Não há mudanças de banco, dependências, despacho, distribuição, carteira ou taxa de entrega. Reinicie Flutter e recarregue o navegador para carregar também o JavaScript novo de `web/index.html`.

Validação: 17 testes simulados do verificador Stripe e cinco cenários executados do formulário JavaScript (sucesso, processamento, recusa, falha de rede e confirmação incompleta), além dos 20 testes existentes de CPFHub. Sem transações reais. Build completo e teste real com Stripe/Admin não foram executados: este ambiente não dispõe de Flutter e faltam dependências/cliente Prisma gerado da API.
