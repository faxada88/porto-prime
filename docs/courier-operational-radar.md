# Radar operacional do motoboy

- Hero com saudação e nome reais, disponibilidade manual e animações curtas; respeita redução de movimento. Blur limitado ao painel de disponibilidade.
- Navegação para carteira, histórico e perfil existentes. A ação central conecta quando offline, atualiza radar quando online ou abre a entrega ativa. Início retorna ao topo.
- GET /api/orders/courier/radar é exclusivo de motoboys ativos e aprovados. Consulta somente leitura; não muda distribuição, ofertas, pagamento ou carteira.
- Demanda: pedidos pagos sem motoboy nos estados confirmado/preparando/pronto/procurando. Zonas aproximadas em grade de 0,01 grau; não retorna IDs de pedidos ou endereços de clientes. Alta demanda significa três ou mais pedidos na zona, sem previsão artificial.
- Mini mapa é uma visualização geográfica de zonas com zoom, sem mapa de ruas ou instruções de navegação. Sem coordenadas, o bairro aparece na lista, sem marcadores inventados.
- Atualização por evento demand.updated após mudanças de pedidos, com atualização adicional a cada 15 segundos. Cache de 5 segundos invalidado pela versão da operação.
- Conclusão operacional: entregas concluídas hoje / (concluídas hoje + entregas ativas), com início do dia de Porto Seguro (UTC-3). Sem amostra, nenhum percentual é inventado.
- Testes simulados: 17 testes de agregação, autorização, cache e despacho passaram. Flutter SDK indisponível neste ambiente: build e revisão visual em dispositivo ainda precisam ser executados.
