# Navegação inferior premium

## Arquivos e arquitetura

- `apps/mobile/lib/core/widgets/prime_animated_navigation.dart`: componente visual controlado `PrimeAnimatedNavigation`, descritor imutável `PrimeNavigationDestination` e curva física `PrimeNavigationSpring`.
- `apps/mobile/lib/core/widgets/prime_bottom_navigation.dart`: adaptador do menu existente no AppShell. Mantém a assinatura pública, IDs, ordem, contadores e visibilidade de Pedidos.
- `apps/mobile/lib/features/courier/presentation/pages/courier_operations_dashboard.dart`: `CourierOperationsNav` adapta os mesmos cinco callbacks e o bloqueio `busy` ao componente compartilhado.

O proprietário continua fornecendo `selectedValue`. O componente recebe o índice, localiza o ID na lista visível e atualiza a apresentação em `didUpdateWidget`; não altera AppState, AppNav, Navigator, API, autenticação ou dados financeiros. Alterações de índice feitas por outras partes do app animam o mesmo elemento de cápsula. Retocar a aba atual continua chamando o callback original.

Uma prévia estritamente visual acompanha o dedo, inclusive nas ações que abrem outra página sem trocar o índice do shell. Cancelar o toque restaura o índice fornecido; quando uma nova rota cobre o menu, a prévia é reconciliada com o proprietário por uma leitura de ModalRoute. O callback é chamado imediatamente, sem esperar a animação e sem escrever um novo estado de navegação.

O Parceiro já utiliza o menu do AppShell. A página aberta “Meu espaço parceiro” tem seções internas em ChoiceChip, sem outro menu inferior; essas seções e seus fluxos continuam existentes.

## Estrutura das abas

| Ambiente | Ordem visual | IDs existentes |
| --- | --- | --- |
| Visitante | Início · Carrinho · Ofertas · Conta | 0 · 2 · 4 · 3 |
| Cliente autenticado | Início · Pedidos · Carrinho · Ofertas · Conta | 0 · 1 · 2 · 4 · 3 |
| Parceiro no AppShell | Início · Pedidos · Carrinho · Ofertas · Conta | 0 · 1 · 2 · 4 · 3 |
| Motoboy | Início · Entregas · Carteira · Histórico · Perfil | 0 · 1 · 2 · 3 · 4 |

Pedidos e Ofertas mantêm a abertura de suas páginas pelos callbacks do AppShell. As seções do Motoboy continuam usando seus modais e retornando ao índice controlado pela página. Nenhuma aba, rota ou página foi criada para alterar esses comportamentos. As barras de ação do checkout e de devolução continuam sendo ações do fluxo, não menus de abas.

## Aparência e animação

Superfície branca, cantos de 29 dp, borda neutra de 1 dp e sombra discreta. A cápsula usa exatamente `#073E43`; os ícones inativos usam verde-acinzentado. Não há gradiente nem halo azul.

A cápsula é um único elemento persistente em um Stack. `AnimatedPositioned` usa uma curva derivada de `SpringSimulation` (massa 1, rigidez 900 e amortecimento 48) durante 300 ms. Um `AnimationController` com a mesma duração e curva acompanha a posição para interpolar as cores dos ícones; o ícone fica branco conforme a cápsula passa sobre sua posição. Mudanças rápidas partem da posição visual atual, sem remover a cápsula.

Cada destino tem `AnimatedScale` de 160 ms no pressionamento e retorno com `easeOutBack`. O feedback tátil de seleção acontece somente no toque válido, uma vez por ação; atualizações externas de índice não o disparam. O estado de seleção continua pertencendo ao chamador.

As animações ficam restritas ao menu em RepaintBoundary. Não há polling, imagens, blur de fundo, pacotes de animação, repetição contínua nem reconstrução das páginas por quadro. A duração prevista é 300 ms; a taxa real de quadros deve ser aferida no aparelho em modo profile/release.

## Critérios de responsividade e acessibilidade

- Validar larguras de 320, 390 e 768 dp, com fonte em 100%, 150% e 200%, nas quatro variantes de menu.
- Dividir a largura igualmente pelos destinos visíveis, com alvo mínimo de 44 × 44 dp. Em janelas excepcionalmente pequenas, o menu permite rolagem horizontal para preservar esses alvos.
- Limitar a superfície a 600 dp no AppShell e 760 dp no Motoboy. Respeitar SafeArea, área de gestos e orientação RTL.
- Medir todos os rótulos com TextPainter usando a fonte, locale e TextScaler vigentes. A altura acompanha a maior legenda, com quebra de linha natural. Não reduzir a fonte dos rótulos para forçar encaixe.
- Recalcular posições ao rotacionar ou alterar a lista visível. A mudança entre visitante e autenticado usa IDs estáveis, preserva Conta e Carrinho e não mantém o badge de Pedidos oculto.
- Anunciar o nome, seleção e contadores pelos Semantics; manter Tooltip e foco por teclado. Somente o pequeno contador numérico limita a escala a 140% para não cobrir o ícone.
- Com redução de movimento, TickerMode desativado ou app em segundo plano, aplicar a posição final sem movimento ornamental. O menu continua acionável quando permitido pelo chamador.

## Verificação e atualização

`premium_navigation_test.dart` cobre as combinações de largura/fonte/ambiente, callbacks e alvos, mola, retarget durante movimento, índice externo, toque rápido e háptica, redução de movimento, Semantics, transição de visitante, busy do Motoboy, RTL, rotação, cancelamento do toque, retorno de outra página e TickerMode. Os testes existentes de navegação, ações do cliente e composição dos três estados do Motoboy também são executados.

O ambiente de edição não dispõe de Flutter/Dart/Android SDK; foram executadas verificações de sintaxe, imports, geometria, mola e preservação do escopo. Uma verificação numérica independente avaliou 231.770 posições em larguras variadas, com overshoot de 1,516% e erro normalizado de 0,000325 no instante 299 ms. Isso não substitui a renderização Flutter nem uma medição de FPS no dispositivo. O instalador executa análise e testes Flutter antes de gerar o APK e usar `adb install -r`. Uma falha impede a instalação. O script não limpa os dados nem reinicia Nest, Admin, banco, Stripe ou rotas.

`scripts/update-premium-navigation.ps1` aceita `-DeviceId`, `-AppleMerchantId` e `-CleanBuild`. O Android deve estar iniciado. A URL local da API continua `http://10.0.2.2:3000/api`.

## Referências técnicas

- https://api.flutter.dev/flutter/physics/SpringSimulation-class.html
- https://api.flutter.dev/flutter/widgets/AnimatedPositioned-class.html
- https://api.flutter.dev/flutter/widgets/AnimatedScale-class.html
- https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html
