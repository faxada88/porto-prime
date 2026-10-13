# Checkout Porto Prime

Carrinho → Entrega e revisão → Pagamento seguro. O carrinho possui ação fixa “Escolher entrega”. A segunda etapa calcula a rota com os serviços existentes, apresenta produtos, entrega e total, permite escolher saldo Porto Prime e prepara o pagamento sem fechar a tela de endereço. Somente depois de receber o pagamento Stripe a próxima tela é aberta.

A tela Stripe oferece resumo recolhível com valores congelados no pedido, endereço e rota. Possui voltar à revisão e voltar ao início. O botão do formulário Stripe continua único. Durante a confirmação, sair exige reconhecer que o pagamento pode continuar e o pedido deve ser consultado antes de outra tentativa. Navegar não cancela, reembolsa nem altera o pedido. Uma tentativa ainda não paga permanece no histórico conforme a lógica existente.

O coordenador mantém o pedido preparado para a mesma seleção durante esta navegação e reutiliza o PaymentIntent existente. Alterar a seleção segue a criação/validação de pedidos existente. A reutilização não é uma nova regra global para pedidos em sessões diferentes.

Backend: a resposta autenticada POST /payments/checkout recebe o campo adicional summary, com valores persistidos, endereço e produtos. Não altera cobrança, créditos, distribuição, estados ou webhook. O total exibido no Stripe não é recalculado pelo cliente.

Instalação: scripts/update-checkout-experience.sh. Gera Prisma e compila Nest/Flutter antes de trocar processos. Não executa migrations ou reset do banco. Preserva Admin, banco, rotas e Stripe CLI. Serve Flutter release otimizado na porta 8090.

Validação no ambiente de edição: build Nest, testes de pagamento/resumo/reutilização, teste Stripe.js e análise de sintaxe e referências Dart. Não há SDK Flutter disponível neste ambiente; a compilação Flutter completa ocorre no instalador, antes de parar os serviços atuais.
