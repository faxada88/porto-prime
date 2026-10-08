# Entrega Porto Prime

Tarifa padrão: R$ 5,50 até 3 km; R$ 2,50 por km excedente, proporcional à fração de km. Exemplos: 4 km = R$ 8,00; 5 km = R$ 10,50; 8 km = R$ 18,00. O arredondamento acontece uma única vez, nos centavos do valor final. Comissão zero: a carteira do motoboy continua recebendo 100% da taxa pelos mecanismos existentes de crédito e idempotência.

O Admin altera apenas taxa inicial, distância incluída e adicional por km. O ponto real da distribuidora precisa ser selecionado uma vez. Coordenadas de exemplo servem somente para abrir o mapa em Porto Seguro; nunca são salvas como origem ou destino. Não cobramos uma distância inventada quando a origem não existe, o destino não foi confirmado ou não há rota válida.

O formulário de endereços permite criar, editar, definir como principal e excluir, preservando a restrição existente de exclusão de locais vinculados ao histórico. Editar os dados de localização invalida o ponto anterior; editar nome/complemento/principal não o invalida. Endereços anteriores precisam ser confirmados no mapa uma vez.

A busca de ruas usa um índice local extraído do OpenStreetMap. A cobertura de números depende dos dados disponíveis: resultados de rua são sugestões, não a entrada exata da casa. O usuário confirma a entrada no mapa antes de salvar. Rotas usam OSRM local, perfil car, respeitando a rede viária mapeada, com limite de aproximação de 100 metros para o ponto de embarque/desembarque. São distâncias da rota sugerida e tempos estimados; não há trânsito ao vivo nem garantia de precisão absoluta em vias não mapeadas. O limite de atendimento existente permanece preservado.

## Instalação e execução

`bash scripts/update-delivery.sh` prepara o roteador, aplica as atualizações SQL idempotentes, gera Prisma e instala dependências do Admin e Flutter. Requer PostgreSQL ativo, Docker, curl, Python 3, npm e Flutter no Codespace. Na primeira execução baixa o extrato do Nordeste (aproximadamente 421 MB), instala osmium-tool se necessário e processa apenas Porto Seguro e entorno. A primeira preparação pode demorar vários minutos; seguintes execuções reutilizam os arquivos e o contêiner. Não exclui nem reinicia o banco. Serviços que usam o banco devem estar parados durante a aplicação do SQL e reiniciados depois.

O roteador fica acessível somente em `127.0.0.1:5000`, em contêiner com restart unless-stopped. Dados ficam em `.routing/`, ignorados pelo Git. `bash scripts/start-routing.sh` reinicia o roteador se necessário. Para atualizar o mapa, remova somente `.routing/ready-v1` e `.routing/nordeste.osm.pbf`, remova o contêiner `porto-prime-routing` e execute o script novamente. Não execute atualização dos dados com o roteador servindo requisições.

Variáveis opcionais de implantação (não são campos operacionais do Admin): `ROUTING_BASE_URL` para servidor OSRM próprio; `STREET_INDEX_PATH` para o arquivo streets.json; `OSRM_IMAGE` para imagem Docker compatível; `ROUTING_BBOX` para recorte da região. Se já houver ROUTING_BASE_URL no .env, ajuste para o servidor local ou próprio. Em produção, o roteador e índice devem ser hospedados em infraestrutura persistente. Software/dados gratuitos não eliminam custos de hospedagem do Codespaces/servidor.

Mapas de interface usam tiles do OpenStreetMap com atribuição, cache padrão do navegador e cache nativo de flutter_map. Sem download em massa, pré-carregamento/offline ou autocomplete público. Tiles públicos têm capacidade limitada e não oferecem SLA; produção com volume alto precisa de provedor compatível ou tiles próprios. Flutter permite trocar via `--dart-define=MAP_TILE_URL=...`; Admin via NEXT_PUBLIC_MAP_TILE_URL. Não usamos geocodificação pública Nominatim nem enviamos nome, número/complemento ou endereço completo a um serviço público de busca. Busca e rotas permanecem no servidor próprio.

## Sincronização

Depois de salvar preços, `delivery.pricing.updated` notifica clientes autenticados, namespace público de catálogo e Admin. Orçamentos são atualizados; o servidor calcula novamente e rejeita criação se a revisão ou o valor confirmado mudou. Endereços publicam `addresses.updated` somente após persistência, para o proprietário e Admin. Produtos, Stripe, despacho, presença e idempotência da carteira mantêm seus fluxos atuais. Pedidos já criados mantêm a taxa gravada.

## Validação nesta entrega

Testes de tarifa, pontos de localização, isolamento por cliente, limites, eventos pós-persistência, proteção contra preço desatualizado, carteira/financeiro e loja fechada. TypeScript do Admin e sintaxe dos scripts verificados. Este ambiente não tem Flutter, Docker ou PostgreSQL/Prisma gerado: não foi possível compilar o Flutter, preparar o extrato real nem executar fluxos reais completos. Essas verificações devem ocorrer no Codespace antes de publicação comercial.

Fontes: https://github.com/Project-OSRM/osrm-backend ; https://project-osrm.org/docs/v5.24.0/api/ ; https://download.geofabrik.de/south-america/brazil/nordeste.html ; https://osmcode.org/osmium-tool/ ; https://operations.osmfoundation.org/policies/tiles/ ; https://pub.dev/packages/flutter_map
