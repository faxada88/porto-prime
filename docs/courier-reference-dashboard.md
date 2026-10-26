# Fluxo claro do motoboy em três estados

Referência visual: Fluxo do App Porto Prime Delivery(1).png.

## Aguardando
Cabeçalho claro com marca, foto real, sino, saudação e um único controle de disponibilidade, alinhado ao nome. Removidos os textos repetidos sobre receber ofertas: durante a espera há somente “Buscando entregas”. Offline mantém uma instrução curta.

As cinco bolinhas giram em três órbitas ao redor da moto, com rastros discretos e pulso suave. O ciclo contínuo de 16 segundos usa pintura própria, sem reconstruir o painel a cada quadro. Pausa offline, em segundo plano, com TickerMode desativado ou com redução de movimento.

Há uma única faixa de resumo na espera: ganhos de hoje, entregas de hoje e tempo online desta sessão. Valores financeiros e quantidade vêm da API. Tempo online é medido localmente nesta abertura da conta e pausa quando offline ou em segundo plano. Não representa um histórico diário fornecido pelo servidor.

## Recebendo oferta
Card único branco, com título Nova entrega, contador compacto e uma linha discreta indicando o prazo real. O valor é a informação principal, seguido de distância e tempo. Retirada e região de entrega ocupam toda a largura útil de um bloco claro, com tipografia maior e sem fotografia decorativa, selo da plataforma ou coluna lateral simulando uma rota bloqueada.

Aceitar entrega ocupa a largura inteira e Recusar fica como ação secundária discreta logo abaixo. O código curto do pedido e a informação de endereço após o aceite ficam em uma linha de apoio que pode quebrar naturalmente. Preservadas as proteções contra aceite duplicado, fechamento durante uma solicitação, expiração e nova tentativa após falha. IncomingDeliveryOfferSheet e seus sete testes existentes não foram alterados.

Enquanto existe oferta, o cabeçalho mostra apenas marca, notificações e foto. Ficar offline continua acessível no menu da foto pela mesma ação de disponibilidade. Na espera, saudação e botão ONLINE permanecem. A apresentação de uma nova oferta volta ao início da rolagem para manter o valor e o contador visíveis, inclusive quando a fonte está ampliada.

O servidor fornece somente a região antes do aceite. Uma única informação explica que o endereço completo será liberado após aceitar; nenhuma coordenada, rua ou mapa é inventado.

## Com entrega
O progresso mostra Retirar, Em entrega e Concluir conforme o status real. A ação principal continua sendo Confirmar coleta, Iniciar rota e Finalizar entrega, nessa ordem. Finalizar entrega chama a mesma confirmação com PIN.

A entrega ativa tem cabeçalho compacto “Sua entrega”, acesso aos detalhes e um único card branco. As etapas usam linhas discretas; nome e endereço têm mais espaço e texto maior. Há uma única ação de mapas, acompanhada do botão Ligar quando existe telefone válido. Distância, tempo e remuneração ficam juntos em uma faixa sem ícones repetidos. A ação principal é preenchida e a instrução do PIN fica logo abaixo, sem um segundo card de orientação.

O controle ONLINE e a saudação grande ficam na espera; durante uma entrega, o cabeçalho dá lugar ao título e aos detalhes. O aviso saudável de rota compartilhada não ocupa um card adicional. Alertas de GPS, permissões e conexão continuam aparecendo com as mesmas ações de recuperação.

O contato abre o discador com o telefone real do cliente. O botão de mapas usa o destino da etapa e o aplicativo disponível; não inicia compartilhamento GPS nem modifica taxas ou estado do pedido. Sem um endereço preciso da retirada, o botão abre os detalhes existentes. Se não há aplicativo de mapas, há alternativa pelo OpenStreetMap.

Distância e duração exibidas são as mesmas fornecidas no pedido. Não são rotuladas como distância restante quando não existe essa medida.

## Layout e verificação
Substituído o preenchimento da espera com SliverFillRemaining por SliverLayoutBuilder e altura mínima explícita, sem solicitação de medidas intrínsecas a um LayoutBuilder. Textos mantêm escala de acessibilidade; os estados podem rolar naturalmente.

SafeArea agora protege o viewport inteiro, incluindo durante a rolagem, para o cabeçalho não passar por baixo da barra de status. Adicionada uma verificação com recuo superior de 34 px, além dos cenários existentes de telas estreitas e fonte ampliada.

Adicionados 12 cenários de renderização dos três estados em 320/390 px e escala 1/2, três verificações da ação por etapa e duas de navegação/privacidade. Os sete testes existentes de ofertas permanecem. Sintaxe, imports relativos, escopo e preservação das ações conferidos neste ambiente. Flutter/Android SDK não estão instalados aqui; o comando abaixo executa análise, os testes e compilação no PC.

A causa exata de uma tela preta só pode ser confirmada pelos logs do dispositivo. A alteração remove a dependência de layout intrínseco e os cenários novos verificam a composição completa de cada estado.

## Confirmação de saque
Depois de requestWithdrawal retornar uma resposta do servidor, o formulário fecha e abre uma confirmação com o valor recebido e uma única animação de confetes de 2,8 segundos. PENDING mostra “Boa! Saque solicitado” e “Aguardando processamento”; PROCESSING informa processamento; somente PAID mostra pagamento confirmado. Não há promessa de prazo nem anúncio antecipado de Pix pago. Cancelamento e erro não exibem a comemoração.

O botão “Voltar à carteira” fecha a confirmação sobre a carteira existente. A solicitação mantém os mesmos valores, validações, chave Pix, API, reserva financeira e atualização de saldo. O formulário bloqueia fechamento durante o envio e não abre duas vezes simultaneamente. A confirmação só é exibida na conta que fez a solicitação. Confetes não repetem ao reconstruir a tela, não capturam toques e respeitam redução de movimento e segundo plano. Novos textos incluem espanhol e inglês.

Sete verificações adicionais em courier_feedback_test.dart cobrem parada do radar offline/redução de movimento, alinhamento e ausência de mensagens repetidas, status do saque em 320 px com fonte ampliada e encerramento da animação sem reinício. Esses testes serão executados pelo instalador; o SDK Flutter continua indisponível neste ambiente.

## Atualização
Com o Android completamente iniciado:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update-courier-dashboard.ps1 -DeviceId emulator-5554

Nest, Admin, banco, rotas e Stripe podem continuar ligados. Instalador mantém adb install -r e não limpa os dados do app. CleanBuild continua opcional.

## Limites preservados
Sem mudanças na API, banco, autenticação, despacho, taxas, remuneração ou regras financeiras dos saques e pagamentos. O GPS continua sendo ativado pelo serviço existente somente quando a ação Iniciar rota é confirmada no servidor. Cancelamentos com devolução continuam no fluxo próprio.

## Referências técnicas
- Android, ações comuns para mapas: https://developer.android.com/guide/components/intents-common#Maps
- Flutter url_launcher, esquemas, aplicativos disponíveis e alternativa após falha: https://pub.dev/packages/url_launcher

## Imagem incorporada
Arquivo: apps/mobile/assets/reference_home/courier-pickup-bag.webp (640 × 640, WebP).
Modo: ferramenta integrada imagegen, com a imagem do usuário como referência; conversão de tamanho/formato para o aplicativo.
Prompt: gerar somente uma fotografia quadrada de uma sacola preta premium com coroa e texto PORTO PRIME dourados, acompanhada por bebidas sobre balcão de madeira, fundo de bar com bokeh âmbar, iluminação quente e composição frontal; sem interface, telefone, dados de pedido ou legendas. A foto é institucional, não o conteúdo real do pedido.
