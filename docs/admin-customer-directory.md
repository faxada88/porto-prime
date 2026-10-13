# Clientes e pedidos no perfil

Lista compacta com busca normalizada por nome, CPF, telefone, e-mail e ID, filtros de acesso, ordenação e páginas de 25/50/100 registros. A seleção se limita a 100 clientes por lote, conforme o endpoint existente. Só a página atual é renderizada. A paginação do diretório é local sobre os usuários já carregados pela API existente; não altera a consulta global de usuários ou os contratos de backend.

No perfil, abra Pedidos e expanda o pedido: Excluir pedido → confirmação no próprio registro. Usa DELETE /admin/orders/:id existente, que remove o pedido do cliente e do despacho sem apagar registros financeiros ou solicitar estorno. A proteção de devolução física pendente permanece no servidor. A lista e o resumo são consultados novamente, com ajuste de página após exclusão do último registro. Eventos de pedidos atualizam o perfil aberto; respostas antigas não sobrescrevem a consulta mais recente.

Atualizador compila e reinicia apenas Admin na porta 3002, preservando API, banco e Flutter. Build Next/TypeScript e renderização estática com 10 mil clientes verificadas localmente. Não foi feita validação visual em navegador autenticado nem uma exclusão contra o banco real neste ambiente.
