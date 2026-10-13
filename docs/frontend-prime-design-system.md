# Porto Prime · refatoração visual do aplicativo

## Inventário e limites funcionais

O aplicativo continua Flutter, Material 3, Manrope local e Lucide. Nenhuma dependência foi adicionada ou removida, nem houve mudança de framework. Componentes novos são vetoriais e nativos do Flutter; ícones de instalação derivam do mesmo SVG próprio. Não há fotografias externas ou emojis como iconografia.

| Área | Camada visual revisada | Ligações funcionais preservadas |
| --- | --- | --- |
| Home e catálogo | Header compacto, marca própria, composição do hero, busca, categorias, produtos e seções | Seleção de categoria, catálogo, estoque, loja aberta e carrinho |
| Carrinho e checkout | Produtos, progresso, tipografia, resumo, controles e identidade do pagamento | Quantidades, limpeza, endereço, crédito, valores e Stripe |
| Pedidos | Headers, superfícies, estados, acesso ao pedido ativo e cancelamento | Estados, busca de motoboy, reembolsos, prazo operacional e retorno |
| Perfil e cadastro | Hierarquia, menus, identificação por marca, inputs e feedback | Login, cadastro por papel, CPF, foto, documentos e validações |
| Motoboy | Hero pessoal, disponibilidade, navegação, carteira, cartões e modo retorno | Online/offline, ofertas, aceite, coleta, PIN, devolução e saques |
| Parceiro | Saudação, divulgação destacada, saldo separado, indicadores e carteira | Link, QR, indicação, comissão e saques |
| Endereços | Intro, cartões, etapas e revisão de entrega | Busca, seleção, geocodificação e cálculo |
| Suporte e chats | Headers claros, estados vazios, superfícies e bolhas limitadas em largura | Tickets, envio, paginação, contexto e escalonamento |
| Plataformas | Favicon, manifesto web e ícones Android/iOS/macOS/Windows | Rotas, permissões e configurações de execução |

A auditoria comparou os 113 handlers Future existentes: 109 ficaram idênticos; quatro mudaram apenas ícones, cor de erro ou tamanho de fonte dentro de diálogos. Todas as expressões de chamadas à API foram preservadas. main.dart, AppState, clientes HTTP, tempo real, captura de indicação e ponte Stripe web permanecem byte a byte iguais. Nenhum arquivo de backend, banco ou Admin integra este commit.

## Sistema visual

Oceano profundo, teal e areia dourada formam a identidade; coral é reservado para descontos e estados de atenção. Tipografia, dimensões, raios, sombras, superfícies, alturas e motion permanecem centralizados. Botões, menus, tooltip, seleção de texto e cartões têm defaults próprios. Componentes respeitam o ajuste de tamanho de texto, áreas de toque, foco e redução de movimento. Saldo é exibido sem recorte; imagens de produtos mantêm contain.

Contrastes principais verificados: primary/branco 6,42:1; muted/canvas 4,76:1; erro/superfície de erro 4,77:1; ink/dourado 9,18:1. A navegação, categorias e produtos usam a mesma família de ícones, com a curadoria óptica já existente. Foram removidas referências Material remanescentes da iconografia de aplicação. Desenhos próprios não consomem eventos ou estado. Blur de fundo animado foi substituído por contraste e superfícies leves no hero do motoboy.

## Validação e atualização

Verificado localmente: sintaxe Dart de todos os arquivos, nomes de constantes Lucide contra o pacote 3.1.22, igualdade da camada central protegida, igualdade das chamadas API, alterações dos handlers limitadas à apresentação, sintaxe do instalador, contraste e dimensões dos novos assets.

A revisão automática bloqueou a execução do SDK Flutter local por tentativa de consulta a metadados da infraestrutura. Portanto, analyze, testes de widgets e build Flutter **não foram executados localmente**. O instalador usa o SDK já presente no Codespaces e executa analyze, os testes de layout em 320/390/768/1280 px com texto 1/1,5/2 e o build release antes de parar o app atual. Se um check falhar, o bundle em execução não é substituído. Não foi feita validação visual em navegador autenticado.

O instalador compila em uma pasta separada, conserva o bundle anterior e serve o novo em 8090. API, Admin, banco, rotas e Stripe CLI permanecem ligados. Os novos ícones nativos serão incorporados no próximo build da respectiva plataforma; o comando de Codespaces atualiza a versão web. As fontes e dependências existentes são preservadas.

Referências técnicas primárias: https://docs.flutter.dev/perf/best-practices ; https://docs.flutter.dev/ui/animations ; https://api.flutter.dev/flutter/material/ThemeData-class.html ; https://pub.dev/packages/lucide_icons_flutter .


## Refinamento de navegação e iconografia — 13/10/2026
- Paleta preservada; nenhuma dependência adicionada.
- Dez ilustrações vetoriais próprias de categorias, desenhadas em uma grade de 48 unidades, com traço de 2 unidades e preenchimento discreto. Categorias adicionais mantêm o fallback Lucide existente.
- Home: busca e categorias antes da campanha compacta; títulos menores e ações diretas. Cartões sem fotografia usam a ilustração da categoria, sem simular uma fotografia de produto.
- Cabeçalhos compartilhados mais compactos; navegação ativa em verde profundo com ícone dourado; carrinho com subtotal e próximo passo mais claros.
- Ações de estado, navegação e chamadas à API comparadas com a versão anterior e preservadas. Backend, banco, autenticação, checkout e despacho não fazem parte desta alteração.
- Sintaxe Dart verificada estaticamente. Testes Flutter e build são executados pelo atualizador no Codespaces antes de substituir o bundle em execução; não foram executados localmente nesta etapa.
