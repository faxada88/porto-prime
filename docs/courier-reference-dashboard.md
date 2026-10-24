# Painel do motoboy

Interface reconstruida a partir da referencia enviada pelo usuario: mapa escuro de Porto Seguro, identidade com coroa, sino e foto, controles laterais, barra verde de disponibilidade, quatro indicadores, cartao de entrega, oportunidades e menu Inicio / Entregas / Carteira / Historico / Perfil.

## Dados e acoes

- Mapa OpenStreetMap com alternancia clara/escura, leitura unica de GPS ao tocar em localizar e rota do endpoint de acompanhamento ja existente. O painel nao inicia o compartilhamento de localizacao. O envio de GPS continua dependendo de Iniciar rota e do status existente.
- Ganhos e quantidade de entregas usam o resumo real da carteira. O tempo online mede esta sessao em primeiro plano, pausa offline ou em segundo plano e explica isso ao tocar no indicador. Avaliacao mostra o valor recebido pelo perfil, quando existir; nunca presume uma nota.
- Ofertas na Home usam o mesmo componente com bloqueio de respostas duplicadas, expiracao e erro recuperavel. Aceitar/recusar enviam os mesmos requests. Som e vibracao anunciam a oferta; fora da Home, o modal continua disponivel.
- A configuracao atual do despacho oferece um pedido por motoboy por vez. O painel nao inventa oportunidades extras nem expoe a fila de outros motoboys.
- Enderecos de clientes continuam restritos a bairro/cidade antes do aceite. A miniatura de uma oferta e um diagrama de retirada/entrega, sem uma rota geografica ficticia. Apos o aceite, um mapa do destino real aparece quando houver coordenadas.
- A entrega atual preserva as transicoes e o PIN. Devolucoes continuam usando a pagina existente. Carteira, extrato, saques, documentos, configuracoes, ajuda, foto e sair permanecem acessiveis pelo perfil e Mais opcoes da conta.
- O sino lista ofertas, estado da entrega e movimentacoes reais da carteira/saques. A leitura e salva por conta neste dispositivo. Marcar todas como lidas nao modifica dados financeiros.
- Novas mensagens incluem traducoes revisadas em portugues, espanhol e ingles.

Nenhuma alteracao em API, banco, autenticacao, distribuicao de pedidos, pagamentos ou calculo financeiro. O atualizador instala com adb install -r, sem desinstalar o aplicativo, e nao interrompe os servicos.

Verificacao no ambiente de edicao: sintaxe Dart, imports, handlers e invariantes das ofertas. Flutter/Android nao estao instalados aqui. O atualizador executa a analise Dart, os testes existentes de oferta, o build release e a instalacao no Windows.
