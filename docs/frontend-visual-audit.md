# Porto Prime — auditoria da camada visual

Base: `feat/mobile-production-flow`, commit `6c80d7587cf95b90e3899d0c71b5f99bbecaa7b6`.
Escopo: apresentação, tokens, acessibilidade e responsividade. Nenhuma migração ou alteração de backend.

## Inventário e fronteiras funcionais

| Área | Tela/componente | Ligações que devem permanecer intactas |
|---|---|---|
| Inicialização | `main.dart`, `SplashPage`, `AppShell` | bootstrap, sessão, IndexedStack e índices de navegação |
| Cliente | `HomePage`, `CategoriesPage`, `PrimeCategoryTile`, `PrimeProductCard` | catálogo, filtro, categoria selecionada, adicionar e alterar quantidade |
| Sacola | `CartPage`, `_LiveItem`, sheet do checkout | subtotal, endereço selecionado, quoteDelivery, createOrder, removeProduct |
| Pagamento | `StripeCheckoutPage`, `_PaidInfo`, elementos Stripe web | clientSecret, publishableKey, orderId, polling, callbacks e confirmação real |
| Pedidos | `OrdersPage`, `OrderTrackingPage`, timeline | loadOrders, loadActiveOrder, estados recebidos e atualização periódica |
| Conta | `ProfilePage`, login, candidatura, endereços | validações, CPF, status, respostas de pendências, login/logout e navegação |
| Cadastro | `RegistrationPage` | formulários por papel, disponibilidade, CEP e aprovação |
| Motoboy | `CourierPage`, `_AvailabilityHero`, `_OfferCountdown`, `_DeliveryDetailsSheet` | heartbeat, online/offline, expiry, aceitar/recusar, avanço, PIN e despacho |
| Financeiro | `_DriverSectionSheet`, `_FinanceHero`, ledger e saques | walletSummary, walletLedger, requestWithdrawal e histórico real |
| Parceiro | conta e cadastro PARTNER existentes | identidade, status e ações existentes; sem inventar comissões ou operações |
| Admin | `page.tsx`: Dashboard, Orders, Pending, People, Catalog, Payments, Withdrawals, Settings | API, filtros, autenticação, polling, WebSocket, mutations e permissões |
| Compartilhados | `AppTheme`, `AppIcons`, `prime_ui.dart` | somente padrões de apresentação |

## Dependências e iconografia

A base já usa `lucide_icons_flutter ^3.1.22` e `lucide-react ^1.52.0`.
A interface própria usa exclusivamente Lucide. `uses-material-design: true` inclui apenas o asset nativo necessário aos controles do framework (calendário/seleção), sem restaurar os pacotes antigos.
A pesquisa confirmou a família Lucide como sistema coerente nas duas stacks:
https://lucide.dev/guide/react/ e https://pub.dev/packages/lucide_icons_flutter/versions/3.1.22.
Os lockfiles estavam sem pacotes já declarados; foram sincronizados. As dependências antigas de ícones sem uso foram retiradas do lockfile mobile.
Manrope foi empacotada localmente (pesos 400–800, licença OFL em `assets/fonts/OFL.txt`), removendo `google_fonts` e suas dependências exclusivamente visuais. A fonte da identidade visual não depende de downloads em runtime.

Curadoria: Cervejas/beer, Destilados/martini, Vinhos/wine, Refrigerantes/cupSoda,
Energéticos/zap, Águas/droplet, Gelo/snowflake, Conveniência/shoppingBag,
Combos/packageOpen e Ofertas/badgePercent. Tamanho e offset óptico ficam juntos em
`CategoryIconSpec`, inclusive aliases com acentos. Categorias desconhecidas mantêm fallback vetorial.
As categorias continuam vindo do catálogo existente; não há criação de categorias no banco.

## Padrões consolidados

- Oceano, areia e coral com superfícies claras; contraste preservado nos textos principais.
- Tokens de cores, tipografia, pesos, dimensões, espaço, radius, bordas, sombras, camadas e motion.
- No Admin, `design-tokens.css` é a única fonte de tokens globais; os breakpoints mantêm overrides locais.
- Categorias com duas linhas de texto, foco visível, Enter/Espaço, estado selecionado e redução de movimento.
- Grade adaptativa de 3/4/5 colunas; cinco colunas a partir de 460 px de área útil.
- Altura dos produtos adaptada ao texto aumentado, imagem contida e controle de quantidade com área de 44 px.
- Sacola e dashboards financeiros consomem os mesmos tokens; limites de largura para áreas de leitura.
- Navigation não elimina nenhum módulo existente do Admin em mobile; safe-area preservada.
- Inputs web em 16 px, zoom do navegador permitido, formulários e sheets continuam roláveis.
- Erro amigável é aplicado apenas na renderização; o erro original e os retries não mudam.
- Skeletons e timeline respeitam movimento reduzido, sem modificar os timers de negócio.

## Limites de escopo

O backend atual não fornece `totalReceived` no resumo da wallet. Não foi criado um cálculo financeiro
novo para preencher esse campo. Saldo, ganhos de hoje/semana, saques e movimentos mostram os dados reais já disponíveis.
O ambiente de parceiro não possui um painel de comissões separado nesta base; as ações existentes foram preservadas.
A navegação do cliente mantém Sacola na rota/índice 2. Trocar essa rota por Pedidos mudaria o comportamento autorizado.

## Aceitação e validação

- Backend, schema, API clients, AppState, realtime, modelos e navegação funcional sem diff.
- Comparação estrutural dos callbacks existentes e das chamadas funcionais do Flutter/Admin.
- Build de produção do Admin e TypeScript.
- 40 combinações aprovadas do Admin (10 módulos em 320, 390, 768 e 1440 px) com fixtures locais.
- 48 combinações visuais aprovadas do Flutter web nos mesmos tamanhos: Cliente/Parceiro (Home, Busca, Sacola, Perfil), Motoboy (Home, menu, carteira e modal de nova entrega).
- Capturas locais revisadas para conferir alinhamento, legibilidade, categorias e ações principais. O botão Recusar foi simplificado para manter o texto completo em 320 px.
- 27 testes Flutter aprovados: grade em quatro larguras, texto em 100%/200%, teclado, carrinho, indicadores financeiros e mensagem de erro.
- Build Flutter web release aprovado. Análise sem erros; permanecem 3 warnings anteriores de componentes privados sem uso e avisos de estilo existentes.
- Comparação TypeScript: 74 callbacks e 59 chamadas de integração do Admin idênticos à base.
- Parser verificou 28 arquivos Dart: nenhum callback existente ou chamada funcional foi removido/modificado.
- A verificação Wasm aponta incompatibilidades existentes no Stripe/socket; esta entrega mantém o build JavaScript atual.
- Fluxos reais Stripe → webhook → liberação → despacho → PIN → crédito exigem o backend e
  contas de teste do ambiente; fixtures visuais não constituem validação ponta a ponta desses serviços.
