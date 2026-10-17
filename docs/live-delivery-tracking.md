# Rastreamento da entrega

Extensão isolada: não altera OrdersService, checkout, despacho, carteira ou schema.
POST /orders/:id/tracking/location e GET /orders/:id/tracking autenticam cada
requisição. Só o motoboy aprovado/ativo atribuído escreve. Só ele, o cliente dono
do pedido e o Admin leem. Posições vão exclusivamente à sala do cliente e à sala
Admin, nunca ao catálogo público ou aos demais motoboys.

GPS começa após OUT_FOR_DELIVERY confirmado pelo endpoint de avanço já existente.
PICKED_UP, aceite e online não ativam GPS. O app retoma uma rota ativa ao reabrir,
se já tem permissão. Sem GPS/permissão/rede a entrega segue normalmente, com aviso
no painel. Retorno mantém rastreamento até a devolução concluída. Saída da conta,
remoção, entrega finalizada ou cancelamento sem retorno encerram o compartilhamento.
O cliente vê atualização de sinal e não um progresso inventado.

Android: geolocator com serviço foreground, notificação e wake lock, iniciado
com o aplicativo aberto. Continua ao alternar de aplicativo. Encerrar à força o
app, desligar o telefone ou restrições do fabricante podem interromper GPS; não
há promessa de rastreamento após force-stop. iOS possui as descrições e modo
background configurados, mas requer validação em aparelho Apple.

Última posição apenas em memória do Nest, expira em dois minutos; sem histórico
GPS persistente. Após reiniciar a API, a próxima posição repopula o mapa. Para
múltiplas instâncias será necessário armazenamento compartilhado/adapter de
WebSocket; esta versão se destina à instância única atual. Cache de rota de 30s,
posições no máximo a cada 2s, transporte em aproximadamente 5-6s. A precisão deve
ser de até 100m e o timestamp de até 60s. Permissões não são verificação antifraude.

Mapa: flutter_map existente, tiles configuráveis via MAP_TILE_URL. OpenStreetMap
padrão para desenvolvimento, atribuição visível. Dimensionar provedor de tiles
antes do lançamento. OSRM local fornece linha e estimativa; falha dele não oculta
a posição. O desenho da moto é vetorial. Cliente usa WebSocket e polling de 8s
para reconexão. GPS nunca marca pedido como entregue nem movimenta dinheiro.

Validação: testes do serviço com DB/auth/realtime simulados; parse sintático Dart.
O atualizador Windows executa Vitest, build Nest, análise/testes Flutter e build
APK antes da instalação. GPS real, permissões, segundo plano e trajeto precisam
ser testados no Android do usuário; nenhum teste local de aparelho foi alegado.

Teste: pedido pago, liberar, aceitar, coletar -> ainda sem GPS. Iniciar rota ->
permitir localização. Abrir o mesmo pedido em uma conta de cliente no navegador
ou segundo aparelho. No emulador, Extended Controls > Location permite enviar
pontos ou reproduzir um trajeto em Porto Seguro. Confirmar atualização, perda de
sinal, volta da rede, conclusão, cancelamento e retorno. Cliente e motoboy devem
estar em sessões distintas, na mesma API. Não misturar os dois pacotes antigos.
