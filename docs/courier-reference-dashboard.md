# Painel do motoboy

Home simplificada: mapa mais compacto e discreto, identidade Porto Prime, sino de atualizacoes, Sair visivel e um unico controle de disponibilidade. O mapa mantem somente o atalho de centralizar a localizacao; entrega/rota, carteira, historico e perfil ficam nos seus atalhos do menu inferior.

## Apresentacao e acoes

- Um unico CourierAvailabilityControl recebe o toque de online/offline. A antiga caixa flutuante de status e o botao offline separado foram removidos. Aguardando resposta, o controle bloqueia novos toques; durante uma entrega, continua abrindo os detalhes da rota em vez de alterar a disponibilidade.
- Ganhos e entregas do dia usam o resumo real da carteira. Os indicadores de tempo de sessao e avaliacao foram retirados da Home para reduzir informacoes secundarias.
- Sem oferta, apenas uma mensagem curta aparece. O bloco de proximas oportunidades so aparece se houver ofertas adicionais reais. O despacho atual mantem uma oferta por motoboy por vez; nenhuma oferta demonstrativa foi criada.
- Alta demanda usa uma faixa compacta com o adicional real. O aviso completo continua disponivel para outros contextos do componente.
- Sair aparece no cabecalho e no Perfil. A confirmacao usa AppState.logout, o logout existente da sessao deste dispositivo. Se houver rastreamento ativo, o dialogo explica a pausa no envio da localizacao. A acao nao cancela a entrega e nao utiliza logoutAll.
- O mapa le os mesmos snapshots de acompanhamento. Localizar continua sendo uma leitura unica de GPS apos o toque; o envio de localizacao continua condicionado ao Inicio da rota no fluxo existente.
- Ofertas preservam validade, bloqueio de respostas duplicadas, falhas recuperaveis, som e vibracao. O cabecalho e os botoes da oferta continuam reorganizando seus textos com fontes ampliadas.
- Endereco completo permanece disponivel apenas apos o aceite. Avanco de status, PIN, devolucoes, carteira, saques, documentos, ajuda e foto usam os fluxos existentes.
- Textos novos incluem portugues, espanhol e ingles.

Nenhuma alteracao de API, schema, autenticacao, distribuicao de pedidos ou calculo financeiro. O atualizador pode rodar com Nest, banco, Admin, rotas e Stripe ligados; usa instalacao com -r e preserva os dados locais do aplicativo.

Verificacao no ambiente de edicao: sintaxe Dart, imports, assinaturas e handlers preservados. Flutter/Android nao estao instalados aqui. O comando de atualizacao executa analise, os testes existentes das ofertas, build release e instalacao no Windows.
