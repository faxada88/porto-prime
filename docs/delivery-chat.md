# Conversa da entrega

Cliente e motoboy responsável conversam no acompanhamento do pedido, antes de acionar a distribuidora. As mensagens rápidas preenchem o campo; o usuário confirma o envio. A conversa requer sessão e vínculo atual com o pedido, ignora pedidos excluídos e fica somente para leitura após encerramento. Usuários de outros pedidos não recebem mensagens.

A ação “Não resolveu?” solicita motivo e descrição. A distribuidora recebe atendimento normal, com trecho limitado das últimas 12 mensagens em contexto expansível. Não existe espera obrigatória para solicitar ajuda. Tickets de parceiros e suporte geral continuam funcionando.

Mensagens persistem em tabela separada e usam identificador de envio para evitar duplicação em tentativas repetidas. Atualização por WebSocket com consulta a cada 15 segundos como recuperação, retomada e histórico paginado.

Instalação: scripts/update-delivery-chat.sh. Mantém banco e rotas existentes ligados, adiciona tabela sem alterar pedidos, aplica suporte, regenera Prisma, compila Nest/Admin/Flutter e inicia 3000, 3002 e 8090. Falhas no encaminhamento do Codespaces não interrompem a instalação; consulte a aba Portas.

Validação local: testes de autorização, notificações privadas, idempotência, encerramento, exclusão, paginação e encaminhamento; compilação Nest/Admin; sintaxe Dart. Flutter e PostgreSQL não estão disponíveis no ambiente de edição para teste integrado de execução.
