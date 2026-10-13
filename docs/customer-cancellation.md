# Cancelamento pelo cliente

O cliente solicita na tela de acompanhamento e confirma os valores antes de cancelar. Não há contador. O servidor considera somente a etapa operacional: sem aceite, cancelamento gratuito; após aceite e antes da coleta, retenção de 50% da entrega; após a coleta, retenção de 100% e devolução à distribuidora. Não há janela de tempo para definir a taxa. Pedidos entregues não permitem cancelamento. Sem coleta, o valor retido é creditado ao motoboy no cancelamento. Após coleta, fica pendente e só é creditado quando o Admin confirma os produtos recebidos.

A operação encerra ofertas e despacho, preserva a preferência online do motoboy e envia eventos ao cliente, Admin e entregador. O pedido vai para Pagamentos e Arquivo. Estornos Stripe e devoluções ao Cartão Porto Prime possuem registros idempotentes, sem repetir ajustes de itens anteriores. Falhas financeiras ficam pendentes ou em revisão, com retentativa administrativa. A confirmação é atualizada se os valores mudarem antes de concluir.

A migração adiciona paidAt e OrderCancellation. Pedidos antigos usam createdAt como aproximação do pagamento porque o timestamp original não estava registrado. Novos pagamentos registram a primeira confirmação no servidor. O instalador aplica SQL idempotente sem resetar o banco, gera Prisma, compila API/Admin/Flutter e reinicia apenas os serviços da aplicação. Banco, rotas, .env e Stripe CLI permanecem preservados.

Validação local: testes automatizados de API e compilação TypeScript/Next. Não há banco PostgreSQL nem SDK Flutter neste ambiente; migração e build Flutter são executados no Codespaces pelo instalador. É necessário validar pagamento, cancelamento e retorno financeiro em ambiente de teste antes de uso comercial.

## Refinamento de acompanhamento e pagamento misto

O modal tem altura limitada, conteúdo rolável e ações fixas; a busca tem um único destaque no acompanhamento. Um atalho flutuante aparece na navegação principal (fora do carrinho), somente para pedidos pagos ativos. Eventos existentes atualizam o atalho e uma consulta periódica recupera alterações quando a tela principal está aberta.

A parcela utilizada do Cartão Porto Prime volta em transação no cancelamento, independentemente de atraso ou falha Stripe. A parcela Stripe volta pela referência original do pagamento. A taxa é abatida uma única vez, da parcela Stripe primeiro; se insuficiente, o restante vem do crédito utilizado. Retentativas recuperam registros anteriores sem duplicar o saldo ou o repasse.

## Cancelamento após coleta

Aceite sem coleta retém 50% da taxa, independentemente do tempo desde o pagamento. Após PICKED_UP ou OUT_FOR_DELIVERY, retém 100% da taxa e repassa ao entregador. O cliente revisa os valores antes de confirmar.

A devolução física tem estados REQUIRED → IN_TRANSIT → ARRIVED → CONFIRMED separados do estorno financeiro. Só o motoboy atribuído pode iniciar e registrar chegada; só o Admin confirma produtos recebidos. Até essa confirmação, a operação permanece ativa para o motoboy e ele é excluído de novos despachos, O pedido em devolução só pode ser removido após a confirmação do recebimento, para preservar a conferência dos produtos. A confirmação fica registrada com usuário e horário. Migração aditiva sem reset; Script update-delivery-return.sh atualiza e reinicia API/Admin/app.

## Liberação do repasse no retorno

O estorno ao cliente e o repasse ao motoboy são independentes. Mesmo com o estorno concluído, um retorno REQUIRED, IN_TRANSIT ou ARRIVED não cria crédito na carteira. A transação administrativa que confirma CONFIRMED registra o repasse com chave única e preserva a disponibilidade ocupada até confirmar o recebimento. Retentativas não duplicam pagamentos. O layout mostra valor pendente, etapas, produtos e ação fixa. A correção não reverte créditos lançados pela versão anterior.
