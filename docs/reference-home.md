# Home — referência visual Porto Prime

Mudança apenas de apresentação: cabeçalho, busca, categorias, banner, cartões da Home e navegação inferior. Catálogo, nomes, preços, estoque, seleção de categoria, carrinho, rotas, autenticação, pagamentos e despacho continuam usando o estado e os handlers existentes. As seções inferiores da Home foram preservadas.

A composição segue a referência fornecida: fundo claro, verde profundo, dourado, fotografia tropical, título serifado, categorias fotográficas, produtos brancos e menu flutuante. Porto Seguro e os dados reais são mantidos; não são inventados produtos, avaliações ou ações de favoritos.

## Recursos

- `assets/reference_home/coast-banner.webp`: banner original gerado com imagegen integrado, modo generate. Prompt: fotografia publicitária tropical 2:1, espaço negativo verde profundo à esquerda, garrafa verde sem marca e copo gelado à direita, litoral de Porto Seguro ao pôr do sol, sem texto ou logotipos.
- `assets/reference_home/category-atlas.webp`: atlas transparente original gerado com imagegen integrado, modo generate. Prompt: seis objetos em uma linha, fotografia de estúdio consistente: cerveja, lata de refrigerante vermelha sem marca, gelo, chips, destilado e vinho; sem texto nem logotipos. Recortes em tempo de execução preservam os ícones escolhidos pelo Admin para outras categorias.
- DM Serif Display, fonte Google Fonts distribuída sob SIL OFL; licença incluída.
- Fotografias reais dos produtos continuam vindo do catálogo. Falhas de imagem mantêm o fallback existente.

## Validação

Sintaxe Dart e registro de assets verificados estaticamente. Flutter não foi executado neste ambiente. O atualizador Windows executa análise, testes de responsividade (320–768 px, texto até 200%), testes visuais existentes, teste dos ícones administrativos e build Android antes de instalar. Se houver erro, interrompe antes de substituir o app.

Com emulador e serviços ligados, execute `scripts/update-reference-home.ps1`. Não exige alterações no banco, Nest, Admin, Stripe ou rotas.
