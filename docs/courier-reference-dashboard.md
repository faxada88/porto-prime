# Área do motoboy: foco em entregas

A Home foi simplificada após a revisão visual:
- Removidas as duas grades de indicadores e toda a seção “Seus ganhos”.
- Um único saldo disponível, no acesso à Carteira, sem repetições de ganhos do dia ou da semana.
- Cabeçalho com nome, sino, foto e um único controle de disponibilidade. Perfil e saída continuam disponíveis.
- Quando não existe uma oferta ou entrega atribuída, uma ilustração vetorial discreta ocupa o centro da tela, com texto curto para o estado online ou offline.
- Ao receber uma oferta real, o card operacional substitui o estado de espera. Os botões, prazo do servidor, remuneração, endereços e proteções de aceitação continuam iguais.
- A transição visual respeita a preferência de redução de movimento. Não há animação em loop ou nova consulta periódica.
- Ganhos detalhados e histórico permanecem nas abas existentes.

A ilustração de espera é decorativa: não mostra localização, rota geográfica, posição em fila, metas, promessas de renda ou ofertas simuladas. O aviso de alta demanda só aparece quando fornecido pelo estado real da operação.

## Layout
O estado de espera preenche o espaço disponível e mantém o acesso à Carteira próximo ao menu. Em telas menores e com fontes ampliadas, o conteúdo pode rolar naturalmente. O estado de entrega usa a lista rolável existente. Nenhuma fonte do conteúdo foi reduzida para forçar encaixe.

## Atualização no Windows
Com o Android completamente iniciado:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update-courier-dashboard.ps1 -DeviceId emulator-5554

O script executa análise, testes existentes de oferta, compilação e instalação com adb install -r. Nest, Admin, banco, rotas e Stripe podem continuar ligados. A opção CleanBuild continua disponível para reconstruir os arquivos gerados quando necessário.

## Escopo e validação
Somente apresentação, textos e mensagem final do instalador foram alterados. Nenhuma mudança na API, autenticação, carteira, despacho, pagamentos, aceite/recusa, confirmação por PIN ou localização.
Sintaxe Dart, imports, chaves de tradução e preservação das ações existentes verificados no ambiente de edição. Não há Flutter/Android SDK neste ambiente; análise semântica, testes de widgets e compilação serão executados pelo script no Windows. A conferência visual final deve ocorrer no emulador.

## Imagem incorporada
Arquivo: apps/mobile/assets/reference_home/courier-pickup-bag.webp (640 × 640, WebP).
Modo: ferramenta integrada imagegen, com a imagem do usuário como referência; conversão de tamanho/formato para o aplicativo.
Prompt: gerar somente uma fotografia quadrada de uma sacola preta premium com coroa e texto PORTO PRIME dourados, acompanhada por bebidas sobre balcão de madeira, fundo de bar com bokeh âmbar, iluminação quente e composição frontal; sem interface, telefone, dados de pedido ou legendas. A foto é institucional, não o conteúdo real do pedido.
