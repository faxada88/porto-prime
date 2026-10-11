# Central de suporte Porto Prime

## Onde aparece
- Admin: nova aba **Suporte**, fila paginada com filtros de perfil/status e busca por nome, pedido, assunto ou protocolo. Conversa e status no mesmo painel; visual responsivo com retorno à lista no celular e aviso de novas mensagens nas demais abas.
- Cliente: **Falar com a distribuidora** no acompanhamento do pedido; **Ajuda e suporte** no perfil.
- Motoboy: **Suporte da entrega** no pedido aceito e **Ajuda e suporte** no perfil operacional.
- Parceiro: tickets no perfil e no botão de ajuda de **Meu espaço parceiro**. Assuntos: comissão/indicações, QR/link, carteira/saque, cadastro/dados, pedido indicado ou outros.

Cada atendimento mantém título, assunto, protocolo, status e mensagens. O Admin responde e marca como aguardando, em atendimento ou resolvido. Uma nova mensagem do solicitante reabre um atendimento resolvido. Isso não modifica o status do pedido.

## Integração e segurança
- REST autenticado `/api/support`: opções, listagem pessoal, fila Admin, criação, detalhe, mensagem e mudança de status.
- Evento Socket.IO `support.updated` enviado exclusivamente à conta dona do atendimento e à sala ADMIN. Mensagens persistidas antes da emissão; nenhum conteúdo de conversa é enviado a salas públicas.
- Cliente só abre chat associado a um pedido próprio não removido; motoboy somente com pedido atribuído ao seu perfil. Parceiro abre tickets independentes, sem acesso a pedidos de clientes. Detalhes e mensagens protegidos por dono/Admin.
- Reenvio idempotente por conta/identificador; bloqueio transacional de suporte evita duplicação. Paginação de mensagens, recuperação ao reconectar/voltar ao app e atualização de segurança a cada 15 segundos caso o evento não chegue.
- Migração aditiva `20261011200000_support_center`: somente SupportThread/SupportMessage e índices. `orderId` é referência textual autorizada na criação, sem vínculo que impeça exclusão operacional de pedidos. Os históricos de atendimento permanecem preservados; a exclusão de uma conta remove seu vínculo com o suporte sem bloquear a operação administrativa.
- Este canal não muda pagamentos, despacho, comissões ou regras de carteira. Não envia e-mails, WhatsApp ou notificações push fora do app.

## Atualização
1. Manter Prisma local e OSRM ligados.
2. `scripts/update-support-admin.sh`: aplica SQL repetível, gera Prisma Client, compila API/Admin e inicia 3000/3002. Também inclui a atualização visual da central Saques, com carteiras em modal centralizado.
3. `scripts/update-support-frontend.sh`: resolve dependências Flutter, compila web e inicia 8086.

## Validação disponível
- Build Nest e build Next.
- 17 testes de suporte: autorização, vínculo de pedido, isolamento, validação, mensagens persistidas, idempotência, estados e paginação. Mais 3 testes de heartbeat existente.
- Sintaxe Dart e referências de ícones/cores verificadas. Este ambiente não tem SDK Flutter nem PostgreSQL ativo; compilação Flutter e teste integrado de chats devem ocorrer no Codespaces.
