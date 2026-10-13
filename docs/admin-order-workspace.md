# Central de pedidos e conferência

Lista compacta com número à esquerda, valor à direita, busca por número/cliente/telefone e filtros por conferência, despacho, entrega e espera do cliente. Ver pedido abre uma área dedicada; os outros pedidos não são empurrados por uma expansão longa.

A área de conferência reutiliza OrderAvailabilityEditor e seus callbacks sem mudar regras: produtos e destino na coluna principal; pagamento original, crédito utilizado e motoboy na coluna lateral; etapa e Liberar pedido fixos no rodapé. Histórico e exclusão preservam endpoints existentes. Só dados atuais da lista atualizada alimentam o pedido aberto.

Modal adapta colunas em telas estreitas, contém rolagem, devolve foco ao fechar, suporta Escape e restringe Tab ao diálogo principal. A edição de indisponibilidade permanece com o comportamento existente. Seleção em lote limitada a 100 pedidos conforme o servidor.

Validação: build Next/TypeScript; renderização estática dos estados pago, aguardando cliente, despacho e entrega; preservação das referências de order/products/request/reload enviadas ao editor. Sem teste visual em navegador autenticado neste ambiente. Instalador reinicia apenas Admin e renomeia o cache no mesmo filesystem.
