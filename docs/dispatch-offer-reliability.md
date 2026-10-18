# Despacho e oferta — correção operacional

## Gargalos corrigidos
- O socket entrega o payload seguro diretamente à tela, sem esperar carteira, histórico ou cadastro.
- Aceitar usa a resposta do PATCH como confirmação; erro de consulta secundária não transforma uma aceitação válida em falha.
- Modal com bloqueio durante envio, progresso, mensagem de erro e nova tentativa. Expiração/fechamento por evento não interrompe uma aceitação em andamento.
- Dados operacionais usam versão e sessão para rejeitar respostas antigas, com consultas coalescidas.
- Reconexão sincroniza imediatamente. Recuperação por polling a cada 15s com socket conectado ou 5s sem conexão; o caminho principal é tempo real.
- Cleanup de oferta vencida é confirmado antes do conflito HTTP. O pedido volta ao despacho.
- Repetir uma aceitação já confirmada é idempotente. As transações de atribuição existentes continuam protegendo contra dois motoboys no mesmo pedido.
- Ciclo com paralelismo limitado a quatro pedidos. Erros transitórios não derrubam o timer nem bloqueiam os outros pedidos.
- Rotação pelo histórico preservada. A janela de 100 candidatos prioriza quem nunca recebeu e quem recebeu há mais tempo, evitando excluir o restante da frota.

Não altera pagamento, taxas, carteira, cancelamento, devolução, cadastro, aprovação ou preferência online/offline. Sem migração de banco. Uma oferta continua exclusiva por vez; recusas e expirações passam a outro candidato e voltam aos anteriores em novas rodadas enquanto houver candidatos elegíveis.

## Verificação
Quatro testes de lógica do servidor passaram localmente: aceitação repetida, cleanup de expiração, rotação a/b/a e isolamento de falhas na fila. Execução local usa TypeScript transpilado com mocks de Nest/Prisma (não substitui teste com banco real). Sintaxe Dart verificada. O atualizador Windows executa Vitest, build Nest, análise/testes Flutter e build APK; depois inicia a API e instala o app. Flutter/Android não executados neste ambiente. Latência real depende da conexão e do banco; teste operacional recomendado com duas contas de motoboy.

## Atualização
Pare apenas o Nest com Ctrl+C e deixe banco, rotas, Stripe, Admin e emulador ligados. Execute scripts/update-dispatch-offers.ps1. O script testa, compila, inicia o Nest em outro terminal e instala o APK.
