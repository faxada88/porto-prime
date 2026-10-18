# Porto Prime — Home e identidade
A Home usa padrões de navegação de apps de delivery: endereço no topo, busca discreta, categorias horizontais, chamada compacta e uma grade única de produtos. A marca Porto Prime permanece verde e dourada. Não reproduz marcas de terceiros.
Estado, callbacks, estoque, preços, carrinho, autenticação, despacho e pagamentos continuam intactos.

## Ícone
Arte original gerada com imagegen integrado (generate / logo-brand). Prompt: monograma P dourado com movimento de entrega sobre fundo verde profundo, gráfico simples e legível em tamanhos pequenos, sem palavras, sem moldura externa, sem marca de terceiros. As exportações usam o mesmo desenho.
- assets/store/porto-prime-app-store-1024.png — App Store, opaco, 1024px.
- assets/store/porto-prime-google-play-512.png — Google Play, 512px.
- apps/mobile/assets/reference_home/porto-prime-icon.png — marca no cabeçalho.
- Android: cinco densidades e adaptive icon com margem de segurança.
- iOS: todos os tamanhos do AppIcon.
- Web: favicon e ícones do manifesto.
Os arquivos de loja estão preparados para upload; o comando não publica nas lojas.

## Verificação
Sintaxe Dart, XML, dimensões e opacidade das imagens verificadas localmente. O script update-marketplace-look.ps1 executa análise, testes e build antes de instalar no Android. Flutter e o emulador não estão disponíveis neste ambiente.
