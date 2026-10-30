# Saques Asaas — sandbox

Escopo: saques solicitados pelo motoboy no app. Stripe, checkout, crédito das entregas, parceiros e saques manuais anteriores não são migrados. Saques antigos não são enviados ao Asaas. Os saques criados manualmente no Admin mantêm seu fluxo atual.

Pré-requisitos: API parada; banco ativo; `.env` da API contém `ASAAS_ENVIRONMENT=sandbox` e `ASAAS_API_KEY`. O instalador valida os arquivos contra o ZIP fornecido, cria backups em TEMP, executa testes e builds e adiciona uma tabela isolada. Não faz pull, reset ou substituição de arquivos divergentes. A configuração de produção é recusada pelo código.

O instalador habilita `ASAAS_PAYOUTS_ENABLED=true` e cria um token aleatório `ASAAS_WEBHOOK_TOKEN` se necessário. Não publicar o `.env`.

## Teste real no sandbox

1. Reiniciar Nest. Adicionar saldo fictício ao Asaas e cadastrar a chave de uma segunda conta sandbox no app do motoboy.
2. O motoboy precisa ter saldo disponível na carteira do Porto Prime (entregas de teste ou ajuste administrativo já existente). Saldo Asaas e saldo da carteira são registros separados.
3. Configurar um webhook de transferências para `https://<dominio-ou-tunel-da-API>/api/wallet/asaas/webhook`, com o token de autenticação exatamente igual a `ASAAS_WEBHOOK_TOKEN`, eventos `TRANSFER_CREATED`, `TRANSFER_PENDING`, `TRANSFER_IN_BANK_PROCESSING`, `TRANSFER_BLOCKED`, `TRANSFER_DONE`, `TRANSFER_FAILED`, `TRANSFER_CANCELLED`. O localhost não pode ser alcançado pelo Asaas. Não expor a API de desenvolvimento sem os controles de acesso já existentes.
4. Solicitar saque pequeno. App retorna PROCESSING; worker envia em até 10 segundos. Conclusão confirmada pelo provedor muda para PAID e atualiza carteira/Admin por wallet.updated. Comprovante fica em receiptUrl. Webhook consulta o status atual no Asaas, evitando regressão por evento fora de ordem.
5. Sem webhook, a recuperação de transferências com ID conhecido consulta após 60 segundos. Não é substituto da configuração do webhook para atualização imediata.
6. Saldo insuficiente/chave recusada (resposta de validação definitiva) estorna uma vez. BLOCKED e timeout não estornam. A chave aleatória RANDOM é mapeada para EVP; telefone normalizado para chave local brasileira.

## Conciliação e interrupções

GET `/api/wallet/asaas/status` com token ADMIN retorna pendências, estados e erros sem a chave secreta.
POST `/api/wallet/asaas/reconcile` com token ADMIN e JSON `{"transferId":"ID_NO_ASAAS"}` consulta a conta autenticada e valida referência, valor e destino antes de atualizar o saque. Pode recuperar um envio cujo processo caiu antes de persistir o ID. A referência externa é `porto-withdrawal:<withdrawalId>`.

Um timeout ou reinício no meio do envio não autoriza repetir o POST: UNKNOWN/SENDING permanece reservado. Localizar a transferência no Asaas e conciliar. Se não houver transferência, é necessária investigação e resolução assistida antes de liberar a reserva; esta versão não oferece reenvio automático de resultado incerto. Não alterar manualmente a base para forçar pagamento ou estorno.

Somente novas solicitações com requestId entram na fila, transacionalmente com a reserva. O app conserva o requestId entre tentativas do mesmo diálogo. A tabela mantém a identificação única e bloqueia saques simultâneos pendentes do mesmo motoboy. Os dois caminhos administrativos existentes recusam a liquidação manual de saques Asaas.

## Validação realizada

52 testes unitários passaram em ambiente isolado: regressão financeira existente, envio concorrente, timeout, tipos de chave, recusa definitiva, estorno repetido, eventos atrasados, bloqueio, discrepância de valor/destino, autenticação do webhook e bloqueio de alteração manual. Checagem TypeScript focada passou com dependências de aplicação substituídas por interfaces de teste. Não houve acesso ao banco Windows, ao Flutter local ou à conta Asaas do usuário. O instalador executa build Nest e análise Flutter contra a instalação real. Homologação ponta a ponta permanece pendente.

Referências: https://docs.asaas.com/reference/transferir-para-conta-de-outra-instituicao-ou-chave-pix ; https://docs.asaas.com/docs/transfer-events
