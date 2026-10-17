# Experiência ao redor do Stripe

Refatoração exclusivamente de apresentação. O formulário PaymentSheet nativo e
sua aparência padrão permanecem intactos, assim como initPaymentSheet,
presentPaymentSheet, Payment Element web, confirmação por saldo, reconciliação,
timers, webhook e navegação após pagamento aprovado. Nenhuma alteração na API.

PrimePaymentExperience recebe dados e callbacks, sem acesso à API ou ao SDK.
Resumo e endereço revisável, totais do servidor, crédito utilizado, aviso de
ambiente de teste e uma única ação principal no Android. O botão continua abrindo
o formulário seguro do Stripe. Na web, somente o Payment Element confirma.
Durante confirmação, não existe CTA para cobrar novamente; mantém-se a ação
existente de verificar o pedido. Formulário de cartão próprio não foi criado.

O idioma do PaymentSheet segue o aparelho. SetupPaymentSheetParameters desta
versão não expõe locale; nenhum parâmetro fictício ou alteração global de idioma
foi adicionado. No emulador, português pode ser selecionado nas configurações
Android de idioma. Selo de teste do Stripe permanece enquanto forem usadas
chaves de teste.

Teste de apresentação cobre 320/390/768 pixels, fontes até 200%, delegação dos
callbacks, ausência de CTA duplicada web, processamento e fluxo somente saldo.
Fontes Dart inspecionadas sintaticamente; testes e build Flutter executados pelo
atualizador no Windows antes de substituir o APK. Sem alegação de execução
local do SDK Android ou de pagamentos reais.
