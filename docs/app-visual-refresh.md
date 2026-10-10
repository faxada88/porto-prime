# Porto Prime — atualização visual do aplicativo

Escopo estritamente Flutter/UI. Nenhum arquivo de backend, Admin, serviços, estado, rede, navegação, contratos, dependências ou banco foi alterado nesta atualização.

## Inventário e limites

| Área | Apresentação | Lógica preservada |
| --- | --- | --- |
| Home / categorias | Hero editorial com ilustração vetorial de litoral; categorias com profundidade; ícones Lucide; busca e seções | catálogo, disponibilidade, seleção, localização, callbacks |
| Produto / carrinho | Imagem em palco claro, ação coral com carrinho, dock azul profundo, resumo de compra | estoque, preço, quantidade, total, adicionar/remover |
| Perfil / cadastro / login | Cabeçalho próprio, Manrope, campos e botões padronizados | validações, consulta CPF, aprovação, sessão e foto obrigatória |
| Pedidos / acompanhamento | Cabeçalho de histórico, hierarquia, tokens de superfícies e estados | estados, pagamentos, eventos, timeline e rotas |
| Checkout / pagamentos | Contraste, cores e resumo financeiro | Stripe, confirmação, reconciliação e handlers |
| Endereços | Hero com profundidade e cores da identidade | sugestões, geocodificação, distância e cotação |
| Motoboy / parceiro | Paleta compartilhada, cartões financeiros e CTA, métricas legíveis | online/offline, ofertas, despacho, carteira, saques e sincronização |

O tema central propaga a identidade também às telas não reestruturadas individualmente. Não há novo mapa, pulso, dados inventados ou promessa de prazo. A arte de litoral é desenhada no Canvas, sem imagens externas, download, blur novo ou dependência adicional. Contraste branco/coral da ação: superior a 4,5:1. Containers de categoria e sua normalização óptica foram preservados.

## Verificação

A sintaxe Dart dos arquivos alterados foi verificada por parser. A revisão do diff preserva referências a AppState, callbacks de operação, timers, handlers e rotas. Flutter não está instalado no ambiente de edição; análise completa, compilação Flutter e inspeção real em navegador não foram realizadas aqui. O comando de instalação executa flutter build web --release e falha se a compilação não passar. É necessária revisão visual no dispositivo, especialmente com fontes ampliadas.

Reinicie o processo Flutter após instalar, pois a aba aberta pode continuar usando a versão anterior. Nenhuma migração ou reinicialização do Nest/Admin é necessária.
