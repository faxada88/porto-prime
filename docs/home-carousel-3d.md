# Home — categorias coloridas e carrossel

Layout inspirado na referência fornecida, com identidade Porto Prime. Saudação usa o nome real da conta, categorias seguem os dados e os ícones escolhidos no Admin, grade mantém quatro colunas e até oito categorias reais, com acesso a todas. Nenhuma promoção ou entrega grátis fictícia.

Três banners editoriais levam ao catálogo existente. Avanço automático a cada cinco segundos, gesto lateral, indicadores clicáveis, controle de pausa, pausa durante toque e em segundo plano. A preferência de reduzir animações desativa o avanço automático. Textos e imagens ocupam colunas separadas; com fonte ampliada a ilustração decorativa é omitida para preservar a leitura.

## Arte
`apps/mobile/assets/reference_home/category-3d.webp` — atlas transparente original de nove ilustrações. Geração integrada imagegen, modo generate (logo-brand/UI asset). Prompt: nove miniaturas coloridas 3D, grade 3x3, fundo transparente e sem marcas: cerveja, refrigerante, gelo, churrasco, frutas, fitness, destilados, vinho e cesta de conveniência. Exportação WebP 1200x1200 com alpha; recortes feitos em tempo de execução. Chaves não presentes no atlas usam o ícone colorido correspondente definido no Admin.

## Validação e atualização
Sintaxe Dart e integridade/transparência do asset verificadas localmente. Testes Flutter cobrem avanço, pausa, callbacks, redução de movimento e responsividade; executados pelo script no PC do usuário, junto ao build. Flutter não executado neste ambiente. Sem alterações em backend, pagamento, despacho, carteira ou autenticação.

`update-home-carousel.ps1` verifica se o Android terminou de iniciar, executa análise/testes/build e instala com ADB `-r`, preservando os dados do aplicativo. Nest, banco, Admin, rotas e Stripe podem continuar ligados.
