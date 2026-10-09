# Entrega automática Porto Prime

Tarifa padrão: R$ 5,50 até 3 km; R$ 2,50 por km excedente, proporcional à fração de km. Exemplos: 4 km = R$ 8,00; 5 km = R$ 10,50; 8 km = R$ 18,00. Arredondamento somente nos centavos finais. O motoboy recebe 100% da taxa pelos mecanismos existentes de crédito e idempotência.

## Base fixa para testes

A origem é o acesso viário ao terminal de passageiros do Aeroporto de Porto Seguro (SBPS), identificado nos dados locais OpenStreetMap e ajustado ao ponto de acesso mais próximo da rede OSRM. Não usamos o centro da pista como ponto de partida. Se não houver terminal mapeado ou acesso viário em até 500 metros, a instalação interrompe com erro; não grava coordenadas inventadas. O script não reseta tarifas já alteradas no Admin e incrementa a revisão somente se a origem mudar. Esta é uma base de teste, não a localização da distribuidora real.

O Admin mostra a base fixa e apenas três campos operacionais: taxa inicial, distância incluída e adicional por km. Alterações notificam os aplicativos em tempo real. Pedidos existentes mantêm seus valores.

## Endereço sem mapa

O cliente digita CEP ou rua. A consulta de CEP existente preenche cidade, UF e, quando disponíveis, rua/bairro. CEP genérico não identifica uma casa: o cliente precisa informar rua, número e bairro. Após completar os dados, o formulário calcula a rota no backend em segundo plano e mostra taxa, distância e total da sacola com entrega. Não há mapa, seleção de pin ou botão de confirmação de localização.

A busca usa o índice local de ruas/números OpenStreetMap. Se o número estiver mapeado, ele tem prioridade. Quando houver somente trecho de rua, a interface informa explicitamente que a distância é estimada, pois o número não está mapeado. Ruas inexistentes ou homônimas distantes sem bairro identificável produzem mensagem para corrigir os dados, nunca uma distância fictícia. Endereços antigos sem coordenadas também são localizados automaticamente. Pontos anteriormente confirmados continuam utilizáveis. Alterar dados de endereço invalida coordenadas antigas, como antes.

Rotas usam OSRM local e rede viária mapeada. A aproximação da origem/destino na consulta de rota é limitada a 100 metros. Distância e tempo dependem da cobertura do mapa; não há trânsito ao vivo nem garantia de precisão de uma casa cujo número não foi mapeado. O limite existente de área atendida continua preservado. Endereços residenciais completos não são enviados para geocodificadores públicos; a consulta de CEP usa os provedores já existentes.

Preview exige sessão de cliente e ignora coordenadas fornecidas pelo navegador. A criação do pedido recalcula a taxa no servidor e rejeita orçamento cuja revisão ou preço mudou. Stripe, despacho e regras de carteira não foram alterados.

## Atualização

`bash scripts/update-auto-delivery.sh` inicia o roteador, atualiza o índice local e referência do terminal, aplica SQL idempotente, gera Prisma, configura a base de teste e instala dependências do Admin/Flutter. Requer PostgreSQL ativo, Docker, curl, Python, npm e Flutter. A primeira preparação de rotas baixa o extrato Nordeste (aproximadamente 421 MB); seguintes execuções reutilizam os arquivos. Não apaga banco, catálogo ou arquivos .env. Reinicie os serviços depois da atualização, inclusive Flutter, para carregar o código novo.

OSRM fica em `127.0.0.1:5000`; dados persistem em `.routing/`, ignorados pelo Git. `bash scripts/start-routing.sh` inicia o contêiner existente. Variáveis opcionais: ROUTING_BASE_URL, STREET_INDEX_PATH, OSRM_IMAGE, ROUTING_BBOX. Uma região diferente precisa manter SBPS no recorte para esta base de teste. Em produção, usar origem real e infraestrutura persistente; software gratuito não elimina custo de hospedagem.

## Validação

50 testes passaram cobrindo tarifa proporcional, localização automática, indicação de estimativa, ruas inexistentes/homônimas, isolamento por cliente, preço desatualizado e loja fechada. TypeScript do Admin e sintaxe dos scripts verificados. Este ambiente não dispõe de Flutter, Docker e PostgreSQL: a compilação Flutter e a execução com dados reais precisam ocorrer no Codespace. Não foi afirmada validação ponta a ponta de pagamento ou localização real.

Fontes: https://github.com/Project-OSRM/osrm-backend ; https://project-osrm.org/docs/v5.24.0/api/ ; https://download.geofabrik.de/south-america/brazil/nordeste.html ; https://osmcode.org/osmium-tool/
