# Conversa da entrega

Cliente e motoboy responsável conversam no acompanhamento do pedido, antes de acionar a distribuidora. As mensagens rápidas preenchem o campo; o usuário confirma o envio. A conversa requer sessão e vínculo atual com o pedido, ignora pedidos excluídos e fica somente para leitura após encerramento. Usuários de outros pedidos não recebem mensagens.

A ação “Não resolveu?” solicita motivo e descrição. A distribuidora recebe atendimento normal, com trecho limitado das últimas 12 mensagens em contexto expansível. Não existe espera obrigatória para solicitar ajuda. Tickets de parceiros e suporte geral continuam funcionando.

Mensagens persistem em tabela separada e usam identificador de envio para evitar duplicação em tentativas repetidas. Atualização por WebSocket com consulta a cada 15 segundos como recuperação, retomada e histórico paginado.

Instalação: scripts/update-delivery-chat.sh. Mantém banco e rotas existentes ligados, adiciona tabela sem alterar pedidos, aplica suporte, regenera Prisma, compila Nest/Admin/Flutter e inicia 3000, 3002 e 8090. Falhas no encaminhamento do Codespaces não interrompem a instalação; consulte a aba Portas.

Validação local: testes de autorização, notificações privadas, idempotência, encerramento, exclusão, paginação e encaminhamento; compilação Nest/Admin; sintaxe Dart. Flutter e PostgreSQL não estão disponíveis no ambiente de edição para teste integrado de execução.

## Correção do envio e abertura automática

A autenticação ocorre antes de abrir a transação. A autorização do pedido continua dentro da transação, usando o usuário autenticado. Isso impede uma espera por uma segunda conexão no Prisma dev, cujo pool local é de uma conexão.

O evento privado informa orderId, messageId persistido, senderId e recipientId. O app deduplica eventos por messageId e abre automaticamente o chat do destinatário enquanto estiver conectado. Antes da navegação, confirma novamente acesso e entrega ativa. O remetente só atualiza o histórico. Se o chat já está visível, não abre uma segunda tela. A navegação anterior permanece na pilha; textos de outras telas não são descartados.

Não é possível forçar a abertura de um app fechado ou sem conexão; nesse caso o histórico permanece disponível. A atualização aplica de forma idempotente a tabela de mensagens, recompila backend e Flutter antes de substituir os processos, sem reiniciar Admin ou banco.

Validação: teste de autenticação fora da conexão ocupada, permissões da entrega, idempotência e eventos privados nos dois sentidos; build Nest. Flutter SDK indisponível no ambiente de edição; compilação completa no instalador.
