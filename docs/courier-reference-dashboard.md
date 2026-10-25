# Painel claro do motoboy

Implementação visual baseada em Painel de Entregas Porto Prime (1).png:
- Fundo gelo, cabeçalho com coroa vetorial, marca, sino e foto real do motoboy.
- Saudação com o primeiro nome e um único controle de disponibilidade.
- Três indicadores: ganhos do dia, entregas do dia e saldo disponível.
- Oferta com fotografia de coleta, origem/destino, cronômetro circular, distância, duração e remuneração reais.
- Botões Recusar e Aceitar entrega; uma solicitação por vez e tentativa novamente após falha permanecem.
- Resumo de ganhos e menu Início, Entregas, Carteira, Histórico e Perfil.
- Sair da conta no menu da foto e no Perfil, usando o logout existente do dispositivo.
- O mapa não ocupa mais o fundo da Home. Acompanhamento, permissões de GPS e rota continuam nos fluxos de entrega.

O terceiro cartão inferior abre a Carteira e mostra o saldo disponível. A API atual fornece ganhos de hoje e da semana, mas não um agregado mensal. Nenhum total mensal é calculado a partir de histórico parcial. Não são criados valores fictícios, ofertas adicionais ou pontos de paginação sem ofertas reais.

A oferta mantém a região do destino antes da aceitação; o endereço completo permanece sujeito à liberação do servidor. A fotografia da sacola é institucional e decorativa. Quando uma entrega atribuída fornece uma foto real de produto, ela tem preferência.

## Responsividade
Sem altura fixa nas seções de texto. Fontes ampliadas reorganizam saudação, indicadores, oferta e botões em coluna. Metadados e botões mantêm quebra de linha e alvos de toque de pelo menos 44 px. O prazo circular utiliza os mesmos segundos da oferta, sem um novo relógio de despacho.

## Atualização no Windows
Com o Android completamente iniciado:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update-courier-dashboard.ps1 -DeviceId emulator-5554 -CleanBuild

CleanBuild executa flutter clean antes de pub get para reconstruir arquivos gerados. O script analisa os arquivos alterados, executa os testes existentes de oferta, compila e instala com adb install -r, preservando os dados locais. Nest, Admin, banco, Stripe e rotas podem continuar ligados.

## Validação
Sintaxe Dart, imports relativos, integridade dos callbacks e escopo do diff verificados no ambiente de edição. Não há Flutter/Android SDK neste ambiente; análise semântica, testes de widgets e compilação são executados pelo script no Windows. A equivalência visual em execução precisa ser conferida no emulador.

## Imagem incorporada
Arquivo: apps/mobile/assets/reference_home/courier-pickup-bag.webp (640 × 640, WebP).
Modo: ferramenta integrada imagegen, com a imagem do usuário como referência; conversão de tamanho/formato para o aplicativo.
Prompt: gerar somente uma fotografia quadrada de uma sacola preta premium com coroa e texto PORTO PRIME dourados, acompanhada por bebidas sobre balcão de madeira, fundo de bar com bokeh âmbar, iluminação quente e composição frontal; sem interface, telefone, dados de pedido ou legendas. A foto é institucional, não o conteúdo real do pedido.
