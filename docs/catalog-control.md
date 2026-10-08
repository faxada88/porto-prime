# Catálogo e loja

Admin: criação/edição de nome, descrição, preço, imagem HTTPS, estoque e categoria; disponibilidade independente do estoque; categorias com nome, imagem, ordem e disponibilidade. Busca e filtros, cards paginados em lotes de 24, formulários com confirmação de persistência.

Arquivar oculta produtos/categorias da vitrine sem excluir registros ou alterar itens dos pedidos. Restaurar conserva estoque e disponibilidade anteriores. Arquivar ou pausar uma categoria oculta seus produtos, sem modificar cada produto. A imagem é informada por URL HTTPS de um asset próprio hospedado; esta etapa não inclui armazenamento/upload de imagens.

`PATCH /api/admin/store` controla abertura e mensagem. Fechar bloqueia novos pedidos no servidor e desabilita continuar na sacola. Pedidos e pagamentos já iniciados continuam com o fluxo existente. Não altera despacho, Stripe, taxas, regras financeiras ou histórico.

Mutação bem-sucedida dispara `catalog.updated` ou `store.updated`. Namespace público `/catalog` transmite exclusivamente aviso com timestamp, sem contas, dados pessoais, pagamentos ou pedidos. App refaz a leitura do catálogo, categorias e loja; reconexão recupera alterações perdidas. Polling de 30 s mantém fallback quando o socket estiver indisponível. Admin recebe eventos autenticados e mantém polling existente. Categorias vazias também aparecem no app; categorias arquivadas/pausadas não aparecem. O carrinho não é apagado pelo fechamento da loja.

Atualização: parar Nest/Flutter antes de executar `bash scripts/update-catalog.sh`, com PostgreSQL ativo. O script aplica SQL aditivo/idempotente e gera Prisma, limpa cache Flutter e atualiza dependências. Reiniciar os serviços depois. Não executa reset de banco.

Validação nesta etapa: Admin `tsc --noEmit`; 24 testes de catálogo, disponibilidade de loja, perfis de clientes/motoboys. Flutter não está disponível no ambiente de edição; compilação e revisão visual em dispositivo não foram executadas aqui. Testes usam mocks, não um PostgreSQL real.


## Revisão do catálogo e fechamento

Layout revisado: abas Produtos/Categorias, listagem compacta de largura inteira, sem painel lateral de navegação. Uma ação Editar por linha; disponibilidade, estoque e arquivamento dentro do editor. Fechar/Abrir loja persiste diretamente, sem segunda confirmação escondida. Status exibido após resposta do servidor, com proteção contra respostas anteriores.

App começa sem autorização de venda até consultar o estado da loja. Evento público de loja carrega somente estado, mensagem e versão; atualiza a interface imediatamente. Leitura da loja funciona independentemente de falhas no catálogo. Antes de novo pedido e checkout, consulta novamente a loja; backend também valida novos pedidos e início de checkout, inclusive reabertura de intents pendentes. Pagamentos já abertos no Stripe e webhooks de aprovação continuam intactos. Nenhum cancelamento automático de pedidos ou cobranças.

Validação adicional: testes de bloqueio de novos checkouts com loja fechada e falha no banco, retomada com loja aberta e valor do pagamento preservado. Flutter continua sem SDK no ambiente de edição; revisão visual do app deve ser feita no dispositivo após reiniciar.
