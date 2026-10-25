import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import 'courier_dashboard_map.dart' show courierGreen, courierInk;

Map<String, dynamic> courierNavigationAddress(Map<String, dynamic> order) {
  if (!['COURIER_ASSIGNED', 'PICKED_UP', 'OUT_FOR_DELIVERY', 'DELIVERED'].contains(order['status'])) return {};
  final raw = order['status'] == 'COURIER_ASSIGNED' ? order['pickup'] : order['address'];
  return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
}
String courierAddressText(Map<String, dynamic> address) =>
  [address['street'], address['number'], address['neighborhood'], address['city'], address['state']]
    .where((value) => value != null && value.toString().trim().isNotEmpty).join(', ');

/// Opens an installed map application; routing/fees and GPS transport are untouched.
Uri? courierNavigationUri(Map<String, dynamic> order, {bool apple = false}) {
  final address = courierNavigationAddress(order);
  final lat = double.tryParse(address['latitude']?.toString() ?? '');
  final lng = double.tryParse(address['longitude']?.toString() ?? '');
  final coordinates = lat != null && lng != null && lat.isFinite && lng.isFinite &&
    lat.abs() <= 90 && lng.abs() <= 180;
    final text = courierAddressText(address);
  final rawAddress = (address['address'] ?? '').toString().trim();
  if (!coordinates && (address['street']?.toString().trim().isEmpty ?? true) && rawAddress.isEmpty) return null;
  final query = coordinates ? '$lat,$lng' : text.isNotEmpty ? text : rawAddress;
  if (query.isEmpty) return null;
  if (apple) return Uri(scheme: 'maps', host: '', queryParameters: {'daddr': query});
  return Uri(scheme: 'geo', path: coordinates ? '$lat,$lng' : '0,0', queryParameters: {'q': query});
}
Uri? courierCustomerPhone(Map<String, dynamic> order) {
  if (!['COURIER_ASSIGNED', 'PICKED_UP', 'OUT_FOR_DELIVERY', 'DELIVERED'].contains(order['status'])) return null;
  final customer = order['customer'];
  final raw = customer is Map ? customer['phone']?.toString() ?? '' : '';
  final phone = raw.replaceAll(RegExp(r'[^+0-9]'), '');
  if (!RegExp(r'^\+?[0-9]{6,15}$').hasMatch(phone)) return null;
  return Uri(scheme: 'tel', path: phone);
}

class CourierAssignedDelivery extends StatefulWidget {
  const CourierAssignedDelivery({super.key, required this.order, required this.busy,
    required this.primaryLabel, required this.primaryIcon, required this.onAdvance, required this.onDetails});
  final Map<String, dynamic> order;
  final bool busy;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onAdvance, onDetails;
  @override State<CourierAssignedDelivery> createState() => _CourierAssignedDeliveryState();
}
class _CourierAssignedDeliveryState extends State<CourierAssignedDelivery> {
  bool _opening = false;
  Future<void> _open({bool phone = false}) async {
    if (_opening || widget.busy) return;
    final uri = phone ? courierCustomerPhone(widget.order) : courierNavigationUri(widget.order,
      apple: defaultTargetPlatform == TargetPlatform.iOS);
    if (uri == null) return;
    setState(() => _opening = true);
    try {
      var opened = false;
      try { if (!kIsWeb) opened = await launchUrl(uri, mode: LaunchMode.externalApplication); }
      catch (_) { /* Use the web fallback when there is no native handler. */ }
      if (!opened && !phone) {
        final query = uri.queryParameters['q'] ?? uri.queryParameters['daddr'] ?? '';
        opened = await launchUrl(Uri.https('www.openstreetmap.org', '/search', {'query': query}),
          mode: LaunchMode.externalApplication);
      }
      if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: PrimeText(phone ? 'Não foi possível abrir o telefone.' : 'Não foi possível abrir o aplicativo de mapas.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: PrimeText(phone ? 'Não foi possível abrir o telefone.' : 'Não foi possível abrir o aplicativo de mapas.')));
    } finally { if (mounted) setState(() => _opening = false); }
  }

  @override Widget build(BuildContext context) {
    final status = widget.order['status']?.toString() ?? '';
    final pickup = status == 'COURIER_ASSIGNED';
    final moving = status == 'OUT_FOR_DELIVERY';
    final address = courierNavigationAddress(widget.order);
    final customer = widget.order['customer'] is Map
      ? Map<String, dynamic>.from(widget.order['customer']) : <String, dynamic>{};
    final title = pickup ? (address['name'] ?? 'Porto Prime Distribuidora').toString()
      : (customer['name'] ?? 'Cliente').toString();
    final addressText = courierAddressText(address);
    final detail = addressText.isNotEmpty ? addressText
      : (address['address'] ?? address['region'] ?? (pickup ? 'Consulte os detalhes da retirada.' : 'Endereço da entrega')).toString();
    final canNavigate = courierNavigationUri(widget.order) != null;
    final canCall = courierCustomerPhone(widget.order) != null;
    final earnings = double.tryParse((widget.order['courierEarnings'] ?? widget.order['deliveryFee'] ?? '').toString());
    String metric(dynamic raw, String unit) {
      final value = double.tryParse(raw?.toString() ?? '');
      return value == null ? '—' : value.toStringAsFixed(unit == 'km' ? 1 : 0).replaceAll('.', ',') + ' ' + unit;
    }
    final amount = earnings == null ? '—' : 'R\$ ' + earnings.toStringAsFixed(2).replaceAll('.', ',');
    final busy = widget.busy || _opening;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0ECEE)),
          boxShadow: const [BoxShadow(color: Color(0x070B4147), blurRadius: 20, offset: Offset(0, 7))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _DeliveryProgress(status: status), const SizedBox(height: 19),
          Material(color: const Color(0xFFFCFEFE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE4EDEF))),
            child: Padding(padding: const EdgeInsets.all(15), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: InkWell(onTap: busy ? null : widget.onDetails,
                  borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    PrimeText(pickup ? 'Retirada em' : moving ? 'Entregando para' : 'Destino da entrega',
                      style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF506C7A))),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontSize: 20, height: 1.25,
                      fontWeight: FontWeight.w800, letterSpacing: -.5, color: courierInk)),
                    const SizedBox(height: 10),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(AppIcons.mapPin, size: 19, color: courierGreen), const SizedBox(width: 7),
                      Expanded(child: PrimeText(detail, style: const TextStyle(fontSize: 11.5,
                        height: 1.55, color: Color(0xFF617D8A)))),
                    ]),
                  ])))),
                const SizedBox(width: 10),
                Column(children: [
                  IconButton.filledTonal(onPressed: busy || !canCall ? null : () => _open(phone: true),
                    tooltip: translateLabel('Ligar para o cliente'),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F5F6), foregroundColor: courierInk),
                    icon: const Icon(AppIcons.phone, size: 20)),
                  const SizedBox(height: 5),
                  IconButton.filledTonal(onPressed: busy || !canNavigate ? null : () => _open(),
                    tooltip: translateLabel('Abrir rota'),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F5F6), foregroundColor: courierInk),
                    icon: const Icon(AppIcons.navigation, size: 20)),
                ]),
              ]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(height: 1, color: Color(0xFFE7EFF1))),
              LayoutBuilder(builder: (context, box) {
                final large = MediaQuery.textScalerOf(context).scale(12) > 18;
                Widget item(IconData icon, String value, String label) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(icon, size: 20, color: courierInk), const SizedBox(height: 6),
                    PrimeText(value, style: const TextStyle(fontSize: 13, height: 1.35,
                      fontWeight: FontWeight.w800, color: courierInk)),
                    const SizedBox(height: 3),
                    PrimeText(label, style: const TextStyle(fontSize: 9, height: 1.4, color: Color(0xFF66818E))),
                  ]));
                final items = [item(AppIcons.route, metric(widget.order['routeDistanceKm'], 'km'), 'Distância'),
                  item(AppIcons.clock, metric(widget.order['routeDurationMinutes'], 'min'), 'Tempo estimado'),
                  item(AppIcons.money, amount, 'Valor da entrega')];
                return large ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items)
                  : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8), Expanded(child: items[i]),
                    ],
                  ]);
              }),
              const SizedBox(height: 14),
              FilledButton(onPressed: busy ? null : canNavigate ? () => _open() : widget.onDetails,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF008574), foregroundColor: Colors.white,
                  minimumSize: const Size(44, 50), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (_opening) const SizedBox(width: 17, height: 17,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  else Icon(canNavigate ? AppIcons.navigation : AppIcons.list, size: 19),
                  const SizedBox(width: 9),
                  Flexible(child: PrimeText(canNavigate ? 'Abrir no app de mapas'
                    : pickup ? 'Ver detalhes da retirada' : 'Ver detalhes', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w700))),
                ])),
            ]))),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFEAF8F1), borderRadius: BorderRadius.circular(15)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(AppIcons.package, size: 27, color: Color(0xFF1C9774)), const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                PrimeText(pickup ? 'Retire o pedido na distribuidora' : moving ? 'Entregue o pedido para o cliente' : 'Tudo pronto para sair',
                  style: const TextStyle(fontSize: 12, height: 1.4, color: courierGreen, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                PrimeText(pickup ? 'Confira os produtos antes de confirmar.' : moving
                  ? 'Confirme a entrega com o PIN do cliente.' : 'Inicie a rota para o cliente acompanhar.',
                  style: const TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF5C8188))),
              ])),
            ])),
          const SizedBox(height: 11),
          OutlinedButton(onPressed: busy ? null : widget.onAdvance,
            style: OutlinedButton.styleFrom(foregroundColor: courierInk,
              minimumSize: const Size(44, 53), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              side: const BorderSide(color: Color(0xFF148C7F)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (widget.busy) const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: courierGreen))
              else Icon(moving ? AppIcons.check : widget.primaryIcon, size: 23),
              const SizedBox(width: 10),
              Flexible(child: PrimeText(widget.busy ? 'Confirmando…' : moving ? 'Finalizar entrega' : widget.primaryLabel,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5,
                  height: 1.4, fontWeight: FontWeight.w800))),
            ])),
        ])),
    ]);
  }
}

class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress({required this.status});
  final String status;
  @override Widget build(BuildContext context) {
    final stage = status == 'DELIVERED' ? 2 : ['PICKED_UP', 'OUT_FOR_DELIVERY'].contains(status) ? 1 : 0;
    const labels = ['Retirar', 'Em entrega', 'Concluir'];
    const icons = [AppIcons.package, AppIcons.truck, AppIcons.check];
    return Stack(children: [
      Positioned(left: 25, right: 25, top: 15, child: Row(children: [
        Expanded(child: Container(height: 2, color: stage > 0 ? const Color(0xFF00AE7C) : const Color(0xFFD5E1E5))),
        Expanded(child: Container(height: 2, color: stage > 1 ? const Color(0xFF00AE7C) : const Color(0xFFD5E1E5))),
      ])),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < 3; i++) Expanded(child: Column(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: i < stage ? const Color(0xFF00A77B) : i == stage ? const Color(0xFFE0F7EC) : const Color(0xFFD4DFE4),
              border: Border.all(color: Colors.white, width: 2)),
            child: Icon(i < stage ? AppIcons.check : icons[i], size: 18,
              color: i < stage ? Colors.white : i == stage ? const Color(0xFF00A77B) : Colors.white)),
          const SizedBox(height: 7),
          PrimeText(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5,
            height: 1.4, fontWeight: i == stage ? FontWeight.w800 : FontWeight.w500,
            color: i <= stage ? courierInk : const Color(0xFF76909D))),
        ])),
      ]),
    ]);
  }
}
