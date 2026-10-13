# Pedidos pagos e cartão Porto Prime

A criação de pedido mantém um rascunho do cliente e reserva somente o valor de saldo escolhido no ledger existente. Não envia evento de criação para Admin. A fila operacional e o contador de pedidos administrativos consultam exclusivamente pagamentos PAID, PARTIALLY_REFUNDED e REFUNDED, preservando os arquivos financeiros existentes. A confirmação Stripe continua validada no servidor; o evento order.updated sincroniza o Admin após pagamento.

O saldo escolhido pode cobrir subtotal mais taxa de entrega, sem reduzir a taxa registrada ou o repasse do motoboy. R$ 45 + R$ 16 com R$ 50 de saldo deixa R$ 11 para Stripe. R$ 100 de saldo usado numa compra de R$ 61 reserva R$ 61 e mantém R$ 39 na carteira. Nenhum saldo é aplicado sem escolha do cliente.

Se o saldo cobrir o total, POST /payments/checkout retorna creditOnly sem chamar Stripe ou confirmar a compra. O cliente confirma na etapa de pagamento. POST /payments/confirm-credit verifica autenticação, propriedade, pedido ativo, total zero e débito integral previamente reservado sob lock do pedido; marca PAID/CONFIRMED sem novo débito. Retentativas não duplicam pagamento ou evento.

O crédito de produtos permanece alocado por item. A parte de crédito da entrega é derivada do saldo usado menos a soma das parcelas por produto. O total operacional mantém essa parcela e o estorno do último item restaura o saldo da entrega; devoluções em dinheiro usam somente o valor que foi efetivamente cobrado pelo Stripe.

Instalar com scripts/update-paid-orders-credit.sh; sem alteração de schema ou reset do banco. Regenera Prisma, compila Nest, Flutter e Admin, reinicia serviços 3000/3002/8090. Banco, rotas e Stripe CLI continuam ligados.

Validação local: testes de pedido, visibilidade Admin, pagamento por saldo, retentativas, permissões, estornos e alocação; build Nest/Admin e cenários Stripe.js. A compilação Flutter completa ocorre no instalador; SDK Flutter indisponível no ambiente de edição.

Para o pagamento misto em BRL, a seleção preserva o mínimo Stripe de R$ 0,50 quando o saldo não cobrir o total; a parcela não utilizada permanece no cartão. A compra integral em saldo continua permitida. Referência: https://docs.stripe.com/currencies#minimum-and-maximum-charge-amounts . O backend recusa resíduos inválidos antes de reservar saldo.
