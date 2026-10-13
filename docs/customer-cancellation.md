# Cancelamento pelo cliente

O cliente solicita na tela de acompanhamento e confirma os valores antes de cancelar. Não há contador. O servidor considera dois minutos desde a confirmação do pagamento: nesse intervalo, cancelamento gratuito; depois, retenção de 50% da entrega somente se um motoboy já aceitou. Pedidos entregues não permitem cancelamento. O valor retido é creditado integralmente ao motoboy no cancelamento.

A operação encerra ofertas e despacho, preserva a preferência online do motoboy e envia eventos ao cliente, Admin e entregador. O pedido vai para Pagamentos e Arquivo. Estornos Stripe e devoluções ao Cartão Porto Prime possuem registros idempotentes, sem repetir ajustes de itens anteriores. Falhas financeiras ficam pendentes ou em revisão, com retentativa administrativa. A confirmação é atualizada se os valores mudarem antes de concluir.

A migração adiciona paidAt e OrderCancellation. Pedidos antigos usam createdAt como aproximação do pagamento porque o timestamp original não estava registrado. Novos pagamentos registram a primeira confirmação no servidor. O instalador aplica SQL idempotente sem resetar o banco, gera Prisma, compila API/Admin/Flutter e reinicia apenas os serviços da aplicação. Banco, rotas, .env e Stripe CLI permanecem preservados.

Validação local: testes automatizados de API e compilação TypeScript/Next. Não há banco PostgreSQL nem SDK Flutter neste ambiente; migração e build Flutter são executados no Codespaces pelo instalador. É necessário validar pagamento, cancelamento e retorno financeiro em ambiente de teste antes de uso comercial.

## Refinamento de acompanhamento e pagamento misto

O modal tem altura limitada, conteúdo rolável e ações fixas; a busca tem um único destaque no acompanhamento. Um atalho flutuante aparece na navegação principal (fora do carrinho), somente para pedidos pagos ativos. Eventos existentes atualizam o atalho e uma consulta periódica recupera alterações quando a tela principal está aberta.

A parcela utilizada do Cartão Porto Prime volta em transação no cancelamento, independentemente de atraso ou falha Stripe. A parcela Stripe volta pela referência original do pagamento. A taxa é abatida uma única vez, da parcela Stripe primeiro; se insuficiente, o restante vem do crédito utilizado. Retentativas recuperam registros anteriores sem duplicar o saldo ou o repasse.
