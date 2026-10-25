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
    final helper = pickup ? 'Confira os produtos antes de confirmar.' : moving
      ? 'Peça o PIN ao cliente para finalizar.' : 'Inicie a rota para o cliente acompanhar.';

    Widget routeButton() => OutlinedButton(
      onPressed: busy ? null : canNavigate ? () => _open() : widget.onDetails,
      style: OutlinedButton.styleFrom(foregroundColor: courierGreen,
        backgroundColor: const Color(0xFFF0F8F6), side: const BorderSide(color: Color(0xFFD4E8E3)),
        minimumSize: const Size(44, 50), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (_opening) const SizedBox(width: 17, height: 17,
          child: CircularProgressIndicator(color: courierGreen, strokeWidth: 2))
        else Icon(canNavigate ? AppIcons.navigation : AppIcons.list, size: 19),
        const SizedBox(width: 8),
        Flexible(child: PrimeText(canNavigate ? 'Ver rota' : pickup ? 'Ver detalhes da retirada' : 'Ver detalhes',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.4,
            fontWeight: FontWeight.w700))),
      ]));
    Widget phoneButton() => OutlinedButton(
      onPressed: busy ? null : () => _open(phone: true),
      style: OutlinedButton.styleFrom(foregroundColor: courierInk,
        side: const BorderSide(color: Color(0xFFD9E4E7)),
        minimumSize: const Size(44, 50), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(AppIcons.phone, size: 18), const SizedBox(width: 8),
        const Flexible(child: PrimeText('Ligar', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w700))),
      ]));

    return Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCE8EB)),
        boxShadow: const [BoxShadow(color: Color(0x060B4147), blurRadius: 20, offset: Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _DeliveryProgress(status: status),
        const SizedBox(height: 24),
        InkWell(onTap: busy ? null : widget.onDetails,
          borderRadius: BorderRadius.circular(10), child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PrimeText(pickup ? 'Retirada em' : moving ? 'Entregando para' : 'Destino da entrega',
                style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF5B7580))),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 23, height: 1.25,
                fontWeight: FontWeight.w800, letterSpacing: -.6, color: courierInk)),
              const SizedBox(height: 10),
              PrimeText(detail, style: const TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF4E6875))),
            ]))),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, box) {
          final stacked = box.maxWidth < 280 || MediaQuery.textScalerOf(context).scale(13) > 18;
          if (!canCall) return routeButton();
          return stacked
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                routeButton(), const SizedBox(height: 9), phoneButton()])
            : Row(children: [
                Expanded(child: phoneButton()), const SizedBox(width: 10),
                Expanded(flex: 2, child: routeButton()),
              ]);
        }),
        const Padding(padding: EdgeInsets.symmetric(vertical: 21),
          child: Divider(height: 1, color: Color(0xFFE8EFF1))),
        _DeliveryMetrics(distance: metric(widget.order['routeDistanceKm'], 'km'),
          duration: metric(widget.order['routeDurationMinutes'], 'min'), amount: amount),
        const SizedBox(height: 22),
        FilledButton(onPressed: busy ? null : widget.onAdvance,
          style: FilledButton.styleFrom(backgroundColor: courierGreen, foregroundColor: Colors.white,
            minimumSize: const Size(44, 55), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.busy) const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else Icon(moving ? AppIcons.check : widget.primaryIcon, size: 21),
            const SizedBox(width: 10),
            Flexible(child: PrimeText(widget.busy ? 'Confirmando…' : moving ? 'Finalizar entrega' : widget.primaryLabel,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5,
                height: 1.4, fontWeight: FontWeight.w800))),
          ])),
        if (status != 'DELIVERED') ...[
          const SizedBox(height: 11),
          PrimeText(helper, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, height: 1.5, color: Color(0xFF67808B))),
        ],
      ]));
  }
}

class _DeliveryMetrics extends StatelessWidget {
  const _DeliveryMetrics({required this.distance, required this.duration, required this.amount});
  final String distance, duration, amount;
  @override Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(12) > 17;
    Widget item(String value, String label, {bool earnings = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PrimeText(value, style: TextStyle(fontSize: 16, height: 1.35,
          fontWeight: FontWeight.w800, color: earnings ? courierGreen : courierInk)),
        const SizedBox(height: 5),
        PrimeText(label, style: const TextStyle(fontSize: 10.5, height: 1.4, color: Color(0xFF67808B))),
      ]));
    final items = [item(distance, 'Distância'), item(duration, 'Tempo estimado'),
      item(amount, 'Valor da entrega', earnings: true)];
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F8F9), borderRadius: BorderRadius.circular(16)),
      child: large ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFE4ECEF))), items[i],
        ],
      ]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8), Expanded(child: items[i]),
        ],
      ]));
  }
}

class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress({required this.status});
  final String status;
  @override Widget build(BuildContext context) {
    final stage = status == 'DELIVERED' ? 2 : ['PICKED_UP', 'OUT_FOR_DELIVERY'].contains(status) ? 1 : 0;
    const labels = ['Retirar', 'Em entrega', 'Concluir'];
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < labels.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: Semantics(selected: i == stage, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3),
            color: i <= stage ? const Color(0xFF079580) : const Color(0xFFE1EAED))),
          const SizedBox(height: 9),
          PrimeText(labels[i], textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, height: 1.4,
              fontWeight: i == stage ? FontWeight.w800 : FontWeight.w500,
              color: i == stage ? courierGreen : const Color(0xFF718690))),
        ]))),
      ],
    ]);
  }
}
