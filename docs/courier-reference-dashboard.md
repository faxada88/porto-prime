# Fluxo claro do motoboy em três estados

Referência visual: Fluxo do App Porto Prime Delivery(1).png.

## Aguardando
Cabeçalho claro com marca, foto real, sino, saudação e um único controle de disponibilidade. Radar com moto e círculos suaves; ao ficar offline ou desativar animações o radar pausa. O aviso diz que a próxima oferta aparecerá ali, sem exibir entregas fictícias.

Há uma única faixa de resumo na espera: ganhos de hoje, entregas de hoje e tempo online desta sessão. Valores financeiros e quantidade vêm da API. Tempo online é medido localmente nesta abertura da conta e pausa quando offline ou em segundo plano. Não representa um histórico diário fornecido pelo servidor.

## Recebendo oferta
Card único com selo Nova entrega, cronômetro do prazo real, imagem institucional, remuneração, distância e duração, retirada e região de entrega, Recusar e Aceitar entrega. Preservadas as proteções contra aceite duplicado, fechamento durante uma solicitação, expiração e nova tentativa após falha.

O servidor fornece somente a região antes do aceite. A prévia indica que a rota/endereço completo será liberado após aceitar; nenhuma coordenada ou rua é inventada para copiar o mapa da referência.

## Com entrega
O progresso mostra Retirar, Em entrega e Concluir conforme o status real. A ação principal continua sendo Confirmar coleta, Iniciar rota e Finalizar entrega, nessa ordem. Finalizar entrega chama a mesma confirmação com PIN.

O contato abre o discador com o telefone real do cliente. O botão de mapas usa o destino da etapa e o aplicativo disponível; não inicia compartilhamento GPS nem modifica taxas ou estado do pedido. Sem um endereço preciso da retirada, o botão abre os detalhes existentes. Se não há aplicativo de mapas, há alternativa pelo OpenStreetMap.

Distância e duração exibidas são as mesmas fornecidas no pedido. Não são rotuladas como distância restante quando não existe essa medida.

## Layout e verificação
Substituído o preenchimento da espera com SliverFillRemaining por SliverLayoutBuilder e altura mínima explícita, sem solicitação de medidas intrínsecas a um LayoutBuilder. Textos mantêm escala de acessibilidade; os estados podem rolar naturalmente.

Adicionados 12 cenários de renderização dos três estados em 320/390 px e escala 1/2, três verificações da ação por etapa e duas de navegação/privacidade. Os sete testes existentes de ofertas permanecem. Sintaxe, imports relativos, escopo e preservação das ações conferidos neste ambiente. Flutter/Android SDK não estão instalados aqui; o comando abaixo executa análise, os testes e compilação no PC.

A causa exata de uma tela preta só pode ser confirmada pelos logs do dispositivo. A alteração remove a dependência de layout intrínseco e os cenários novos verificam a composição completa de cada estado.

## Atualização
Com o Android completamente iniciado:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update-courier-dashboard.ps1 -DeviceId emulator-5554

Nest, Admin, banco, rotas e Stripe podem continuar ligados. Instalador mantém adb install -r e não limpa os dados do app. CleanBuild continua opcional.

## Limites preservados
Sem mudanças na API, banco, autenticação, despacho, taxas, remuneração, saques ou pagamentos. O GPS continua sendo ativado pelo serviço existente somente quando a ação Iniciar rota é confirmada no servidor. Cancelamentos com devolução continuam no fluxo próprio.

## Referências técnicas
- Android, ações comuns para mapas: https://developer.android.com/guide/components/intents-common#Maps
- Flutter url_launcher, esquemas, aplicativos disponíveis e alternativa após falha: https://pub.dev/packages/url_launcher

## Imagem incorporada
Arquivo: apps/mobile/assets/reference_home/courier-pickup-bag.webp (640 × 640, WebP).
Modo: ferramenta integrada imagegen, com a imagem do usuário como referência; conversão de tamanho/formato para o aplicativo.
Prompt: gerar somente uma fotografia quadrada de uma sacola preta premium com coroa e texto PORTO PRIME dourados, acompanhada por bebidas sobre balcão de madeira, fundo de bar com bokeh âmbar, iluminação quente e composição frontal; sem interface, telefone, dados de pedido ou legendas. A foto é institucional, não o conteúdo real do pedido.
