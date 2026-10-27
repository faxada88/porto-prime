import 'category_labels.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Presentation-only translations. API values, names and catalogue data stay intact.
class AppLanguage extends ChangeNotifier {
  AppLanguage._();
  static final instance = AppLanguage._();
  static const supported = [Locale('pt', 'BR'), Locale('es', 'ES'), Locale('en', 'US')];
  Locale _locale = supported.first;
  Locale get locale => _locale;
  final Map<String, Map<String, String>> _messages = {};
  final Map<String, List<_Phrase>> _templates = {};
  SharedPreferences? _preferences;

  static const Map<String, Map<String, String>> _curated = {
"Conta bloqueada": {"es": "Cuenta bloqueada", "en": "Account blocked"},
"Conta suspensa": {"es": "Cuenta suspendida", "en": "Account suspended"},
"Vamos regularizar sua conta": {"es": "Vamos a regularizar tu cuenta", "en": "Let’s get your account ready"},
"Novas entregas estão indisponíveis. Consulte as orientações abaixo. O acesso será atualizado após a revisão administrativa.": {"es": "No puedes recibir nuevas entregas. Consulta las indicaciones a continuación. El acceso se actualizará después de la revisión administrativa.", "en": "New deliveries are unavailable. Check the guidance below. Access will update after the administrative review."},
"Confira o que falta e envie sua resposta por aqui. Você não precisa informar seu CPF novamente.": {"es": "Revisa lo que falta y envía tu respuesta aquí. No necesitas volver a introducir tu CPF.", "en": "Check what’s missing and send your response here. You don’t need to enter your CPF again."},
"Aguardando análise administrativa. Nenhuma exigência adicional foi registrada.": {"es": "Pendiente de revisión administrativa. No se ha solicitado información adicional.", "en": "Awaiting administrative review. No additional information has been requested."},
"Atualizar situação": {"es": "Actualizar estado", "en": "Refresh status"},
"Falar com o suporte": {"es": "Contactar con soporte", "en": "Contact support"},
"Exigência": {"es": "Requisito", "en": "Requirement"},
"Resposta enviada • aguardando análise": {"es": "Respuesta enviada • pendiente de revisión", "en": "Response sent • awaiting review"},
"Pronto! Agora é só aguardar.": {"es": "¡Listo! Ahora solo queda esperar.", "en": "All done! We’ll take it from here."},
"Sua resposta foi enviada para análise. Avisaremos por aqui quando houver uma atualização.": {"es": "Enviamos tu respuesta para revisión. Te avisaremos aquí cuando haya novedades.", "en": "Your response has been submitted for review. We’ll notify you here when there’s an update."},
"Sua resposta": {"es": "Tu respuesta", "en": "Your response"},
"Anexar imagem do documento": {"es": "Adjuntar imagen del documento", "en": "Attach a document image"},
"Documento anexado • substituir": {"es": "Documento adjunto • sustituir", "en": "Document attached • replace"},
"Enviar para análise": {"es": "Enviar para revisión", "en": "Send for review"},
"Escreva uma resposta antes de enviar.": {"es": "Escribe una respuesta antes de enviarla.", "en": "Write a response before sending."},
"Escolha uma imagem de até 60 KB.": {"es": "Selecciona una imagen de hasta 60 KB.", "en": "Choose an image up to 60 KB."},
"Escolha uma imagem JPEG ou PNG.": {"es": "Selecciona una imagen JPEG o PNG.", "en": "Choose a JPEG or PNG image."},
"Você está disponível. Avisaremos assim que chegar uma nova oportunidade.": {"es":"Estás disponible. Te avisaremos cuando llegue una nueva oportunidad.","en":"You're available. We'll let you know when a new opportunity arrives."},
"Ligar": {"es":"Llamar","en":"Call"},
"Peça o PIN ao cliente para finalizar.": {"es":"Pide el PIN al cliente para finalizar.","en":"Ask the customer for the PIN to complete delivery."},
"Boa! Saque solicitado": {"es":"¡Listo! Retiro solicitado","en":"Great! Withdrawal requested"},
"Seu saque está em processamento": {"es":"Tu retiro se está procesando","en":"Your withdrawal is being processed"},
"Saque pago!": {"es":"¡Retiro pagado!","en":"Withdrawal paid!"},
"Confira seu saque": {"es":"Consulta tu retiro","en":"Check your withdrawal"},
"Aguardando processamento": {"es":"Pendiente de procesamiento","en":"Awaiting processing"},
"Em processamento": {"es":"En proceso","en":"Processing"},
"Pagamento confirmado": {"es":"Pago confirmado","en":"Payment confirmed"},
"Consulte o status na carteira": {"es":"Consulta el estado en tu cartera","en":"Check the status in your wallet"},
"Acompanhe as atualizações na carteira.": {"es":"Consulta las actualizaciones en tu cartera.","en":"Follow updates in your wallet."},
"Voltar à carteira": {"es":"Volver a la cartera","en":"Back to wallet"},
"Buscando sua próxima entrega...": {"es":"Buscando tu próxima entrega...","en":"Looking for your next delivery..."},
"Avisaremos assim que surgir uma oportunidade na sua região.": {"es":"Te avisaremos en cuanto haya una oportunidad en tu zona.","en":"We'll let you know as soon as an opportunity appears in your area."},
"Você está online e pronto para receber entregas.": {"es":"Estás conectado y listo para recibir entregas.","en":"You're online and ready to receive deliveries."},
"Em entrega": {"es":"En reparto","en":"On delivery"},
"Endereço completo após aceitar.": {"es":"Dirección completa después de aceptar.","en":"Full address after accepting."},
"Rota após aceitar": {"es":"Ruta después de aceptar","en":"Route after accepting"},
"Retirada em": {"es":"Recogida en","en":"Pick up at"},
"Entregando para": {"es":"Entregando a","en":"Delivering to"},
"Destino da entrega": {"es":"Destino de la entrega","en":"Delivery destination"},
"Consulte os detalhes da retirada.": {"es":"Consulta los detalles de recogida.","en":"Check the pickup details."},
"Endereço da entrega": {"es":"Dirección de entrega","en":"Delivery address"},
"Ligar para o cliente": {"es":"Llamar al cliente","en":"Call customer"},
"Abrir rota": {"es":"Abrir ruta","en":"Open route"},
"Abrir no app de mapas": {"es":"Abrir en la app de mapas","en":"Open in maps app"},
"Ver detalhes da retirada": {"es":"Ver detalles de recogida","en":"View pickup details"},
"Retire o pedido na distribuidora": {"es":"Recoge el pedido en la distribuidora","en":"Pick up the order at the store"},
"Entregue o pedido para o cliente": {"es":"Entrega el pedido al cliente","en":"Hand the order to the customer"},
"Tudo pronto para sair": {"es":"Todo listo para salir","en":"Ready to head out"},
"Confira os produtos antes de confirmar.": {"es":"Revisa los productos antes de confirmar.","en":"Check the products before confirming."},
"Confirme a entrega com o PIN do cliente.": {"es":"Confirma la entrega con el PIN del cliente.","en":"Confirm delivery with the customer's PIN."},
"Inicie a rota para o cliente acompanhar.": {"es":"Inicia la ruta para que el cliente pueda seguirte.","en":"Start the route so the customer can track the delivery."},
"Finalizar entrega": {"es":"Finalizar entrega","en":"Complete delivery"},
"Retirar": {"es":"Recoger","en":"Pick up"},
"Concluir": {"es":"Finalizar","en":"Complete"},
"Não foi possível abrir o telefone.": {"es":"No se pudo abrir el teléfono.","en":"Couldn't open the phone app."},
"Não foi possível abrir o aplicativo de mapas.": {"es":"No se pudo abrir la aplicación de mapas.","en":"Couldn't open the maps app."},
"Abrir carteira": {"es":"Abrir cartera","en":"Open wallet"},
"Na sua carteira": {"es":"En tu cartera","en":"In your wallet"},
"Sua próxima entrega": {"es":"Tu próxima entrega","en":"Your next delivery"},
"Pronto quando você estiver": {"es":"Listos cuando tú lo estés","en":"Ready when you are"},
"Avisaremos assim que uma oferta chegar.": {"es":"Te avisaremos en cuanto llegue una oferta.","en":"We'll let you know as soon as an offer arrives."},
"Fique online para receber novas entregas.": {"es":"Conéctate para recibir nuevas entregas.","en":"Go online to receive new deliveries."},
"Olá,": {"es":"Hola,","en":"Hello,"},
"Motoboy": {"es":"Repartidor","en":"Courier"},
"Pronto para mais entregas?": {"es":"¿Listo para más entregas?","en":"Ready for more deliveries?"},
"Boa entrega!": {"es":"¡Buen reparto!","en":"Have a great delivery!"},
"EM ENTREGA": {"es":"EN REPARTO","en":"DELIVERING"},
"ONLINE": {"es":"EN LÍNEA","en":"ONLINE"},
"OFFLINE": {"es":"DESCONECTADO","en":"OFFLINE"},
"Você está recebendo entregas": {"es":"Estás recibiendo entregas","en":"You're receiving deliveries"},
"Toque para ficar online": {"es":"Toca para conectarte","en":"Tap to go online"},
"Ganhos de hoje": {"es":"Ganancias de hoy","en":"Today's earnings"},
"Entrega disponível": {"es":"Entrega disponible","en":"Delivery available"},
"Sua entrega": {"es":"Tu entrega","en":"Your delivery"},
"COLETA": {"es":"RECOGIDA","en":"PICKUP"},
"ENTREGA": {"es":"ENTREGA","en":"DROPOFF"},
"Distância": {"es":"Distancia","en":"Distance"},
"Tempo estimado": {"es":"Tiempo estimado","en":"Estimated time"},
"Valor da entrega": {"es":"Importe de la entrega","en":"Delivery earnings"},
"Seus ganhos": {"es":"Tus ganancias","en":"Your earnings"},
"Ver carteira": {"es":"Ver cartera","en":"View wallet"},
"Hoje": {"es":"Hoy","en":"Today"},
"Semana": {"es":"Semana","en":"Week"},
"{0} entrega": {"es":"{0} entrega","en":"{0} delivery"},
"{0} entregas": {"es":"{0} entregas","en":"{0} deliveries"},
"Disponível para saque": {"es":"Disponible para retirar","en":"Available to withdraw"},
"Sair": {"es":"Salir","en":"Log out"},
"Sair da conta": {"es":"Cerrar sesión","en":"Log out"},
"Sair da conta?": {"es":"¿Cerrar sesión?","en":"Log out?"},
"Você poderá entrar novamente quando quiser.": {"es":"Puedes volver a iniciar sesión cuando quieras.","en":"You can log in again whenever you like."},
"Você está em uma rota. Ao sair, o envio da localização será pausado até você entrar novamente.": {"es":"Tienes una ruta en curso. Al salir, el envío de tu ubicación se pausará hasta que vuelvas a iniciar sesión.","en":"You have a route in progress. Logging out will pause location sharing until you log in again."},
"Toque para ficar offline": {"es":"Toca para desconectarte","en":"Tap to go offline"},
"Receber novas entregas": {"es":"Recibir nuevas entregas","en":"Receive new deliveries"},
"Buscando entregas": {"es":"Buscando entregas","en":"Looking for deliveries"},
"Avisaremos quando uma oferta chegar.": {"es":"Te avisaremos cuando llegue una oferta.","en":"We'll let you know when an offer arrives."},
"Pronto para rodar?": {"es":"¿Listo para repartir?","en":"Ready to deliver?"},
"Fique online quando estiver disponível.": {"es":"Conéctate cuando estés disponible.","en":"Go online when you're available."},
"por entrega elegível": {"es":"por entrega elegible","en":"per eligible delivery"},
"Tempo online nesta sessão. A contagem pausa quando você fica offline ou sai do aplicativo.": {"es":"Tiempo conectado en esta sesión. El contador se pausa cuando te desconectas o sales de la aplicación.","en":"Online time in this session. The timer pauses when you go offline or leave the app."},
"Tempo para aceitar": {"es":"Tiempo para aceptar","en":"Time to accept"},
"Você está online": {"es":"Estás conectado","en":"You're online"},
"Você está offline": {"es":"Estás desconectado","en":"You're offline"},
"Recebendo entregas": {"es":"Recibiendo entregas","en":"Receiving deliveries"},
"Ficar offline": {"es":"Desconectarse","en":"Go offline"},
"Ficar online": {"es":"Conectarse","en":"Go online"},
"Ganhos hoje": {"es":"Ganancias de hoy","en":"Today's earnings"},
"Entregas hoje": {"es":"Entregas de hoy","en":"Today's deliveries"},
"Tempo online": {"es":"Tiempo conectado","en":"Online time"},
"Avaliação": {"es":"Valoración","en":"Rating"},
"Meu perfil": {"es":"Mi perfil","en":"My profile"},
"Suas avaliações aparecerão aqui quando disponíveis.": {"es":"Tus valoraciones aparecerán aquí cuando estén disponibles.","en":"Your ratings will appear here when available."},
"Próximas oportunidades": {"es":"Próximas oportunidades","en":"Upcoming opportunities"},
"Seu radar está ativo": {"es":"Tu radar está activo","en":"Your radar is active"},
"A próxima oferta aparece aqui automaticamente.": {"es":"La próxima oferta aparecerá aquí automáticamente.","en":"Your next offer will appear here automatically."},
"Novas ofertas aparecem aqui quando disponíveis.": {"es":"Las nuevas ofertas aparecerán aquí cuando estén disponibles.","en":"New offers will appear here when available."},
"Conecte-se para receber novas entregas.": {"es":"Conéctate para recibir nuevas entregas.","en":"Go online to receive new deliveries."},
"Conecte-se para receber": {"es":"Conéctate para recibir","en":"Go online to receive"},
"Atualizar entregas": {"es":"Actualizar entregas","en":"Refresh deliveries"},
"Localizar minha posição": {"es":"Localizar mi posición","en":"Locate my position"},
"Mapa claro": {"es":"Mapa claro","en":"Light map"},
"Mapa escuro": {"es":"Mapa oscuro","en":"Dark map"},
"Ver rota atual": {"es":"Ver ruta actual","en":"View current route"},
"Ver rota": {"es":"Ver ruta","en":"View route"},
"Ver detalhes da rota": {"es":"Ver detalles de la ruta","en":"View route details"},
"Ative o GPS para localizar sua posição.": {"es":"Activa el GPS para localizar tu posición.","en":"Turn on GPS to locate your position."},
"Permita a localização para centralizar o mapa.": {"es":"Permite el acceso a la ubicación para centrar el mapa.","en":"Allow location access to center the map."},
"Localização indisponível. Tente novamente.": {"es":"Ubicación no disponible. Inténtalo de nuevo.","en":"Location unavailable. Please try again."},
"Atualizações": {"es":"Actualizaciones","en":"Updates"},
"Tudo em dia": {"es":"Todo al día","en":"You're all caught up"},
"Novas entregas e movimentações aparecerão aqui.": {"es":"Las nuevas entregas y movimientos aparecerán aquí.","en":"New deliveries and transactions will appear here."},
"Marcar todas como lidas": {"es":"Marcar todas como leídas","en":"Mark all as read"},
"Crédito recebido": {"es":"Crédito recibido","en":"Credit received"},
"Movimentação na carteira": {"es":"Movimiento en la cartera","en":"Wallet transaction"},
"Saque atualizado": {"es":"Retiro actualizado","en":"Withdrawal updated"},
"NOVA ENTREGA": {"es":"NUEVA ENTREGA","en":"NEW DELIVERY"},
"ENTREGA EM ANDAMENTO": {"es":"ENTREGA EN CURSO","en":"DELIVERY IN PROGRESS"},
"Entrega em andamento": {"es":"Entrega en curso","en":"Delivery in progress"},
"Nova entrega": {"es":"Nueva entrega","en":"New delivery"},
"Entrega Porto Prime": {"es":"Entrega Porto Prime","en":"Porto Prime delivery"},
"Recusar entrega": {"es":"Rechazar entrega","en":"Decline delivery"},
"Recusar": {"es":"Rechazar","en":"Decline"},
"Aceitar entrega": {"es":"Aceptar entrega","en":"Accept delivery"},
"Retirada": {"es":"Recogida","en":"Pickup"},
"Entrega": {"es":"Entrega","en":"Drop-off"},
"Detalhes": {"es":"Detalles","en":"Details"},
"O endereço completo será liberado após aceitar.": {"es":"La dirección completa estará disponible al aceptar.","en":"The full address will be available after you accept."},
"Confirmando…": {"es":"Confirmando…","en":"Confirming…"},
"Enviando…": {"es":"Enviando…","en":"Sending…"},
"Mais opções da conta": {"es":"Más opciones de la cuenta","en":"More account options"},
"Região informada": {"es":"Zona indicada","en":"Provided area"},
"Base Porto Prime": {"es":"Base Porto Prime","en":"Porto Prime base"},
"Entendi": {"es":"Entendido","en":"Got it"},
"Bebidas para o seu momento": {"es":"Bebidas para tu momento","en":"Drinks for your moment"},
"Seus itens continuam no carrinho.": {"es":"Tus productos siguen en el carrito.","en":"Your items stay in your cart."},
"Continuar comprando": {"es":"Seguir comprando","en":"Continue shopping"},
"Informe um telefone válido com o código do país": {"es":"Introduce un teléfono válido con el código del país","en":"Enter a valid phone number with its country calling code"},
"Confira seu telefone": {"es":"Revisa tu teléfono","en":"Check your phone number"},
"Confira o número e o código do país": {"es":"Revisa el número y el código del país","en":"Check the number and country calling code"},
"Número com código de área": {"es":"Número con código de área","en":"Number with area code"},
"País / código": {"es":"País / código","en":"Country / calling code"},
"País ou código, como +55": {"es":"País o código, como +55","en":"Country or calling code, such as +55"},
"Busque pelo nome ou código do país.": {"es":"Busca por nombre o código de país.","en":"Search by country name or calling code."},
"Escolha seu país": {"es":"Elige tu país","en":"Choose your country"},
"Selecione o peso": {"es":"Selecciona el peso","en":"Choose a weight"},
"Peso não informado": {"es":"Peso no especificado","en":"Weight not specified"},
"Aguarde um instante": {"es":"Espera un momento","en":"Please wait a moment"},
"Produto": {"es":"Producto","en":"Product"},
"Total": {"es":"Total","en":"Total"},
"Quantidade": {"es":"Cantidad","en":"Quantity"},
"Outras opções": {"es":"Otras opciones","en":"Other options"},
"Peso do pacote": {"es":"Peso de la bolsa","en":"Bag weight"},
"Tipo": {"es":"Tipo","en":"Type"},
"Novas opções de gelo em breve.": {"es":"Pronto habrá nuevas opciones de hielo.","en":"More ice options coming soon."},
"Escolha, adicione e pronto.": {"es":"Elige, añade y listo.","en":"Choose, add, and you're set."},
"Escolha seu gelo": {"es":"Elige tu hielo","en":"Choose your ice"},
"Fechar": {"es":"Cerrar","en":"Close"},
"Adicionar ao carrinho": {"es":"Añadir al carrito","en":"Add to cart"},
"Indisponível": {"es":"No disponible","en":"Unavailable"},
"Limite de estoque atingido": {"es":"Límite de existencias alcanzado","en":"Stock limit reached"},
"Gelo na medida certa": {"es":"Hielo a tu medida","en":"Ice to suit your plans"},
"Escolha o tipo, o peso e pronto.": {"es":"Elige el tipo, el peso y listo.","en":"Choose the type and weight. That's it."},
"Moído": {"es":"Picado","en":"Crushed"},
"Escolher meu gelo": {"es":"Elegir mi hielo","en":"Choose my ice"},
"Seu gelo, do seu jeito": {"es":"Tu hielo, a tu gusto","en":"Your ice, your way"},
"Escolha uma opção para adicionar.": {"es":"Elige una opción para añadir.","en":"Choose an option to add."},
"Como você prefere?": {"es":"¿Cómo lo prefieres?","en":"How would you like it?"},
"Qual o peso?": {"es":"¿Qué peso?","en":"Which weight?"},
"Esta combinação não está disponível. Confira as opções abaixo ou escolha outro tipo.": {"es":"Esta combinación no está disponible. Revisa las opciones de abajo o elige otro tipo.","en":"This combination is unavailable. Check the options below or choose another type."},
"Escolha seu produto": {"es":"Elige tu producto","en":"Choose your product"},
"Escolha uma opção": {"es":"Elige una opción","en":"Choose an option"},
"Gelo adicionado ao carrinho": {"es":"Hielo añadido al carrito","en":"Ice added to your cart"},
"Opções disponíveis": {"es":"Opciones disponibles","en":"Available options"},
"Encontre o gelo para o seu pedido.": {"es":"Encuentra el hielo para tu pedido.","en":"Find the right ice for your order."},
"Adicionar": {"es":"Añadir","en":"Add"},

"Nossas cervejas": {"es":"Nuestras cervezas","en":"Our beers"},
"Cortes para o seu churrasco": {"es":"Cortes para tu barbacoa","en":"Cuts for your barbecue"},
"Sua rotina, seu ritmo": {"es":"Tu rutina, tu ritmo","en":"Your routine, your pace"},
"Nossa seleção de vinhos": {"es":"Nuestra selección de vinos","en":"Our wine selection"},
"Energia para acompanhar você": {"es":"Energía para acompañarte","en":"Energy to keep you going"},
"Gelo no ponto": {"es":"Hielo a tu gusto","en":"Ice, just right"},
"Nossa seleção de destilados": {"es":"Nuestra selección de destilados","en":"Our spirits selection"},
"Ofertas para aproveitar": {"es":"Ofertas para disfrutar","en":"Offers to enjoy"},
"Hora de matar a fome": {"es":"Hora de comer algo","en":"Time for a bite"},
"Produtos selecionados": {"es":"Productos seleccionados","en":"Selected products"},
"As melhores marcas, sempre geladas para o seu momento.": {"es":"Las mejores marcas, siempre frías para tu momento.","en":"The best brands, always chilled for your moment."},
"Boas escolhas para o seu momento.": {"es":"Buenas opciones para tu momento.","en":"Great choices for your moment."},
"Escolha sua favorita e aproveite!": {"es":"¡Elige tu favorita y disfruta!","en":"Pick your favorite and enjoy!"},
"Filtrar produtos": {"es":"Filtrar productos","en":"Filter products"},
"Ordenar produtos": {"es":"Ordenar productos","en":"Sort products"},
"Em estoque": {"es":"En stock","en":"In stock"},
"Somente ofertas": {"es":"Solo ofertas","en":"Offers only"},
"Aplicar filtros": {"es":"Aplicar filtros","en":"Apply filters"},
"Recomendados": {"es":"Recomendados","en":"Recommended"},
"Menor preço": {"es":"Precio más bajo","en":"Lowest price"},
"Maior preço": {"es":"Precio más alto","en":"Highest price"},
"Nome: A–Z": {"es":"Nombre: A–Z","en":"Name: A–Z"},
"Todas": {"es":"Todas","en":"All"},
"Todos": {"es":"Todos","en":"All"},
"Lata": {"es":"Lata","en":"Can"},
"Garrafa": {"es":"Botella","en":"Bottle"},
"Artesanais": {"es":"Artesanales","en":"Craft"},
"Sem álcool": {"es":"Sin alcohol","en":"Alcohol free"},
"Bovina": {"es":"Vacuno","en":"Beef"},
"Frango": {"es":"Pollo","en":"Chicken"},
"Suína": {"es":"Cerdo","en":"Pork"},
"Kits": {"es":"Kits","en":"Kits"},
"Proteínas": {"es":"Proteínas","en":"Protein"},
"Creatina": {"es":"Creatina","en":"Creatine"},
"Pré-treino": {"es":"Preentreno","en":"Pre-workout"},
"Barras": {"es":"Barritas","en":"Bars"},
"Tintos": {"es":"Tintos","en":"Red"},
"Brancos": {"es":"Blancos","en":"White"},
"Rosés": {"es":"Rosados","en":"Rosé"},
"Espumantes": {"es":"Espumosos","en":"Sparkling"},
"Sem açúcar": {"es":"Sin azúcar","en":"Sugar free"},
"Cubos": {"es":"Cubitos","en":"Cubes"},
"Escamas": {"es":"Escamas","en":"Flakes"},
"Hambúrgueres": {"es":"Hamburguesas","en":"Burgers"},
"Sanduíches": {"es":"Sándwiches","en":"Sandwiches"},
"Combos": {"es":"Combos","en":"Combos"},
"Oferta": {"es":"Oferta","en":"Offer"},
"avaliações": {"es":"reseñas","en":"reviews"},
"Tente outro termo ou ajuste os filtros.": {"es":"Prueba otro término o ajusta los filtros.","en":"Try another search or adjust the filters."},
'Ver ofertas': {'es': 'Ver ofertas', 'en': 'View offers'},
'Ofertas': {'es': 'Ofertas', 'en': 'Offers'},
'Novas ofertas em breve': {'es': 'Nuevas ofertas pronto', 'en': 'New offers coming soon'},
'Salvar produto': {'es': 'Guardar producto', 'en': 'Save product'},
'Remover dos favoritos': {'es': 'Quitar de favoritos', 'en': 'Remove from favorites'},

'Produtos que combinam com o seu pedido': {'es': 'Productos que combinan con tu pedido', 'en': 'Great additions to your order'},
'Complete o seu pedido': {'es': 'Completa tu pedido', 'en': 'Complete your order'},
'Buscar produtos': {'es': 'Buscar productos', 'en': 'Search products'},
'Nenhum produto encontrado.': {'es': 'No se encontraron productos.', 'en': 'No products found.'},
'Vale levar junto': {'es': 'Añade algo más', 'en': 'Add a little extra'},
'Continuar apresentação': {'es': 'Reanudar presentación', 'en': 'Resume slideshow'},
'Pausar apresentação': {'es': 'Pausar presentación', 'en': 'Pause slideshow'},
'Produto anterior': {'es': 'Producto anterior', 'en': 'Previous product'},
'Próximo produto': {'es': 'Siguiente producto', 'en': 'Next product'},
"Se o pagamento já estiver em processamento, aguardaremos a confirmação. Somente compras com pagamento confirmado aparecem em Pedidos.": {"es": "Si el pago ya se está procesando, esperaremos la confirmación. Solo las compras con pago confirmado aparecen en Pedidos.", "en": "If your payment is already processing, we will wait for confirmation. Only purchases with confirmed payment appear in Orders."},
"Saldo liberado de checkout não concluído": {"es": "Saldo liberado de una compra no finalizada", "en": "Balance released from an unfinished checkout"},

  'produto': {'es': 'producto', 'en': 'product'},
  'produtos': {'es': 'productos', 'en': 'products'},
  'Ver carrinho': {'es': 'Ver carrito', 'en': 'View cart'},
  'Subtotal': {'es': 'Subtotal', 'en': 'Subtotal'},
  'Subtotal dos produtos': {'es': 'Subtotal de los productos', 'en': 'Product subtotal'},

  "BEM-VINDO(A) AO PORTO PRIME": {
    "es": "TE DAMOS LA BIENVENIDA A PORTO PRIME",
    "en": "WELCOME TO PORTO PRIME"
  },
  "Seu próximo\npedido começa\ncom você.": {
    "es": "Tu próximo\npedido empieza\ncontigo.",
    "en": "Your next\norder starts\nwith you."
  },
  "Crie sua conta para pedir, acompanhar a entrega e usar todos os benefícios do Porto Prime.": {
    "es": "Crea tu cuenta para hacer pedidos, seguir la entrega y disfrutar de todos los beneficios de Porto Prime.",
    "en": "Create your account to order, track your delivery and enjoy all Porto Prime benefits."
  },
  "Seus pedidos": {
    "es": "Tus pedidos",
    "en": "Your orders"
  },
  "Acompanhe tudo em tempo real": {
    "es": "Sigue todo en tiempo real",
    "en": "Track everything in real time"
  },
  "Seus endereços": {
    "es": "Tus direcciones",
    "en": "Your addresses"
  },
  "Gerencie seus endereços": {
    "es": "Gestiona tus direcciones",
    "en": "Manage your addresses"
  },
  "Seu saldo": {
    "es": "Tu saldo",
    "en": "Your balance"
  },
  "Cupons, créditos e benefícios": {
    "es": "Cupones, créditos y beneficios",
    "en": "Coupons, credit and benefits"
  },
  "Criar minha conta": {
    "es": "Crear mi cuenta",
    "en": "Create my account"
  },
  "Entrar na minha conta": {
    "es": "Entrar en mi cuenta",
    "en": "Sign in to my account"
  },
  "Uma conta. Tudo organizado e seguro.": {
    "es": "Una cuenta. Todo organizado y seguro.",
    "en": "One account. Everything organized and secure."
  },
  "ESTAMOS POR PERTO": {
    "es": "ESTAMOS CERCA DE TI",
    "en": "WE’RE HERE FOR YOU"
  },
  "Precisa de ajuda?": {
    "es": "¿Necesitas ayuda?",
    "en": "Need help?"
  },
  "Ajuda e suporte": {
    "es": "Ayuda y soporte",
    "en": "Help and support"
  },
  "Fale com a equipe Porto Prime": {
    "es": "Habla con el equipo de Porto Prime",
    "en": "Talk to the Porto Prime team"
  },
  "Parcerias e patrocínios": {
    "es": "Alianzas y patrocinios",
    "en": "Partnerships and sponsorships"
  },
  "Conte sua ideia para a Porto Prime": {
    "es": "Cuéntale tu idea a Porto Prime",
    "en": "Share your idea with Porto Prime"
  },
  "Privacidade e segurança": {
    "es": "Privacidad y seguridad",
    "en": "Privacy and security"
  },
  "Cuidamos dos seus dados com carinho": {
    "es": "Cuidamos tus datos con atención",
    "en": "We handle your data with care"
  },
  "Muito mais que um destino.": {
    "es": "Mucho más que un destino.",
    "en": "Much more than a destination."
  }
};

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    for (final code in ['es', 'en']) {
      // The translated JSON catalogues are optional until included in assets.
      // Missing files must never crash application startup on Android.
      try {
        final raw = jsonDecode(
          await rootBundle.loadString('assets/localization/$code.json'),
        ) as Map<String, dynamic>;
        final messages = raw.map((key, value) => MapEntry(key, value.toString()));
        _messages[code] = messages;
        _templates[code] = messages.entries.where((e) => RegExp(r'\{\d+\}').hasMatch(e.key))
            .where((e) => e.key.replaceAll(RegExp(r'\{\d+\}'), '').trim().length >= 4)
            .map((e) => _Phrase(e.key, e.value)).toList()
          ..sort((a, b) => b.specificity.compareTo(a.specificity));
      } catch (error) {
        // Keep the existing curated/category translations as fallbacks.
        _messages[code] = <String, String>{};
        _templates[code] = <_Phrase>[];
        debugPrint('Porto Prime: translation asset $code unavailable: $error');
      }
    }
    final saved = _preferences?.getString('porto-language-v1');
    final restoredLocale = supported.firstWhere(
      (l) => l.languageCode == saved,
      orElse: () => supported.first,
    );
    if (_locale != restoredLocale) {
      _locale = restoredLocale;
      notifyListeners();
    }
  }

  Future<void> select(String code) async {
    if (!supported.any((l) => l.languageCode == code)) return;
    _locale = supported.firstWhere((l) => l.languageCode == code);
    notifyListeners();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await const MethodChannel('porto_prime/language').invokeMethod<void>('setLanguage', {'language': _locale.toLanguageTag()});
    }
    await _preferences?.setString('porto-language-v1', code);
  }

  String translate(String value) {
    final code = locale.languageCode;
    if (code == 'pt' || value.isEmpty) return value;
    final exact = CategoryLabels.translate(value, code) ?? _curated[value]?[code] ?? _messages[code]?[value];
    if (exact != null) return exact;
    for (final phrase in _templates[code] ?? <_Phrase>[]) {
      final match = phrase.pattern.firstMatch(value);
      if (match != null) return phrase.render(match);
    }
    return value;
  }
}

class _Phrase {
  _Phrase(this.source, this.target) {
    final tokens = RegExp(r'\{(\d+)\}');
    var cursor = 0;
    final buffer = StringBuffer('^');
    for (final token in tokens.allMatches(source)) {
      buffer.write(RegExp.escape(source.substring(cursor, token.start)));
      buffer.write('([\\s\\S]*?)');
      indices.add(token.group(1)!);
      cursor = token.end;
    }
    buffer.write(RegExp.escape(source.substring(cursor)));
    buffer.write(r'$');
    pattern = RegExp(buffer.toString());
  }
  final String source, target;
  final indices = <String>[];
  late final RegExp pattern;
  int get specificity => source.replaceAll(RegExp(r'\{\d+\}'), '').length;
  String render(RegExpMatch match) => target.replaceAllMapped(RegExp(r'\{(\d+)\}'), (token) {
    final index = indices.indexOf(token.group(1)!);
    return index < 0 ? token.group(0)! : match.group(index + 1)!;
  });
}

T translateLabel<T extends String?>(T text) => (text == null ? null : AppLanguage.instance.translate(text)) as T;

String? Function(String?)? localizeValidator(String? Function(String?)? validator) => validator == null
    ? null : (value) { final error = validator(value); return error == null ? null : AppLanguage.instance.translate(error); };

/// Keeps Flutter's Text layout and accessibility, including const call sites.
class PrimeText extends Text {
  const PrimeText(super.data, {super.key, super.style, super.strutStyle, super.textAlign,
    super.textDirection, super.locale, super.softWrap, super.overflow, super.textScaleFactor,
    super.textScaler, super.maxLines, super.semanticsLabel, super.semanticsIdentifier,
    super.textWidthBasis, super.textHeightBehavior, super.selectionColor});
  @override String? get data => super.data == null ? null : AppLanguage.instance.translate(super.data!);
  @override String? get semanticsLabel => super.semanticsLabel == null ? null : AppLanguage.instance.translate(super.semanticsLabel!);
  @override Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppLanguage.instance, builder: (context, _) => super.build(context));
}

class PrimeInputDecoration extends InputDecoration {
  const PrimeInputDecoration({super.alignLabelWithHint, super.border, super.contentPadding,
    super.counterText, super.enabledBorder, super.errorMaxLines, super.errorText, super.fillColor,
    super.filled, super.focusedBorder, super.helperText, super.hintStyle, super.hintText,
    super.labelText, super.prefixIcon, super.prefixIconConstraints, super.prefixText, super.suffixIcon});
  String? _translate(String? text) => text == null ? null : AppLanguage.instance.translate(text);
  @override String? get labelText => _translate(super.labelText);
  @override String? get hintText => _translate(super.hintText);
  @override String? get helperText => _translate(super.helperText);
  @override String? get errorText => _translate(super.errorText);
  @override String? get counterText => _translate(super.counterText);
}

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, this.compact = false});
  final bool compact;
  static const labels = {'pt': 'Português', 'es': 'Español', 'en': 'English'};
  static const flags = {'pt': '🇧🇷', 'es': '🇪🇸', 'en': '🇺🇸'};
  @override Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppLanguage.instance,
    builder: (context, _) => PopupMenuButton<String>(
      tooltip: AppLanguage.instance.translate('Idioma'),
      initialValue: AppLanguage.instance.locale.languageCode,
      onSelected: AppLanguage.instance.select,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => labels.entries.map((entry) => PopupMenuItem<String>(
        value: entry.key,
        child: Row(children: [Text(flags[entry.key]!, style: const TextStyle(fontSize: 23)),
          const SizedBox(width: 12), Expanded(child: Text(entry.value)),
          if (entry.key == AppLanguage.instance.locale.languageCode)
            const Icon(Icons.check_rounded, size: 20)]))).toList(),
      child: Container(height: 48, padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 9),
        decoration: BoxDecoration(color: const Color(0xFF004A50), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC4D4D6), width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(flags[AppLanguage.instance.locale.languageCode]!, style: const TextStyle(fontSize: 22)),
          if (!compact) const SizedBox(width: 6),
          if (!compact) Text(AppLanguage.instance.locale.languageCode.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 4), const Icon(Icons.expand_more_rounded, size: 16, color: Colors.white)])),
    ));
}

