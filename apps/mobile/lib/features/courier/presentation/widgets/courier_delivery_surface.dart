import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import 'courier_dashboard_map.dart';

/// Presentation for the real dispatch offer or the courier's assigned order.
/// Offers retain the server's neighbourhood-only customer address.
class CourierDeliverySurface extends StatelessWidget {
  const CourierDeliverySurface({super.key, required this.order, required this.incoming,
    this.seconds, this.busy = false, this.action, this.error, this.onAccept, this.onReject,
    this.onDetails, this.onAdvance, this.primaryLabel, this.primaryIcon, this.statusLabel});
  final Map<String, dynamic> order;
  final bool incoming, busy;
  final int? seconds;
  final String? action, error, primaryLabel, statusLabel;
  final IconData? primaryIcon;
  final VoidCallback? onAccept, onReject, onDetails, onAdvance;
  String _money(dynamic value) => 'R\$ ' +
    (double.tryParse(value?.toString() ?? '') ?? 0).toStringAsFixed(2).replaceAll('.', ',');
  String _metric(dynamic value, String unit) {
    final number = double.tryParse(value?.toString() ?? '');
    return number == null ? '—' : number.toStringAsFixed(unit == 'km' ? 1 : 0).replaceAll('.', ',') + ' ' + unit;
  }
  @override Widget build(BuildContext context) {
    final pickup = order['pickup'] is Map ? Map<String, dynamic>.from(order['pickup']) : <String, dynamic>{};
    final dropoff = order['dropoff'] is Map ? Map<String, dynamic>.from(order['dropoff']) : <String, dynamic>{};
    final address = !incoming && order['address'] is Map
      ? Map<String, dynamic>.from(order['address']) : <String, dynamic>{};
    final id = (order['orderId'] ?? order['id'] ?? '').toString();
    final shortId = id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();
    final earnings = order['courierEarnings'] ?? order['deliveryFee'];
    final target = incoming
      ? (dropoff['neighborhood'] ?? 'Região informada').toString()
      : (order['customer']?['name'] ?? 'Cliente Porto Prime').toString();
    final targetDetail = incoming ? (dropoff['city'] ?? 'Porto Seguro').toString()
      : [address['street'], address['number'], address['neighborhood']].where((x) => x != null && x.toString().isNotEmpty).join(', ');
    String? image;
    if (!incoming && order['items'] is List && (order['items'] as List).isNotEmpty) {
      final first = (order['items'] as List).first;
      if (first is Map) image = (first['imageUrl'] ?? first['product']?['imageUrl'])?.toString();
    }
    final thumbnail = Container(width: 83, height: 70, padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF0F4F5), borderRadius: BorderRadius.circular(16)),
      child: image != null && image.isNotEmpty ? Image.network(image, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(AppIcons.package, size: 35, color: courierGreen))
        : const Icon(AppIcons.package, size: 35, color: courierGreen));
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDDE9ED)),
        boxShadow: const [BoxShadow(color: Color(0x060D3B49), blurRadius: 20, offset: Offset(0, 6))]),
      child: LayoutBuilder(builder: (context, box) {
        final large = MediaQuery.textScalerOf(context).scale(14) > 19;
        final preview = box.maxWidth >= 320 && !large;
        final header = Wrap(alignment: WrapAlignment.spaceBetween, spacing: 12, runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(gradient: LinearGradient(colors: incoming
                ? const [Color(0xFF00854F), Color(0xFF007F50)]
                : const [Color(0xFF007D62), Color(0xFF005F51)]),
                borderRadius: BorderRadius.circular(20)),
              child: PrimeText(incoming ? 'NOVA ENTREGA' : statusLabel ?? 'ENTREGA EM ANDAMENTO',
                style: const TextStyle(fontSize: 10, height: 1.25, fontWeight: FontWeight.w800, color: Colors.white))),
            Row(mainAxisSize: MainAxisSize.min, children: [
              PrimeText('#' + shortId, style: const TextStyle(fontSize: 11, color: Color(0xFF5B7380), fontWeight: FontWeight.w600)),
              if (seconds != null) ...[
                const SizedBox(width: 8),
                Semantics(label: translateLabel('Tempo para aceitar'), child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  decoration: BoxDecoration(color: seconds! <= 8 ? AppColors.coral100 : const Color(0xFFEDF6F2),
                    borderRadius: BorderRadius.circular(9)),
                  child: PrimeText(seconds.toString() + ' s', style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w800, color: seconds! <= 8 ? AppColors.danger : courierGreen)))),
              ],
              IconButton(onPressed: busy ? null : incoming ? onReject : onDetails,
                tooltip: translateLabel(incoming ? 'Recusar entrega' : 'Ver detalhes'),
                icon: Icon(incoming ? AppIcons.close : AppIcons.more, size: 19, color: const Color(0xFF5B7380)),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44), padding: EdgeInsets.zero),
            ]),
          ]);
        final stops = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _DeliveryStop(color: const Color(0xFF00AF73), label: 'Retirada',
            title: (pickup['name'] ?? 'Porto Prime Distribuidora').toString(),
            detail: (pickup['region'] ?? pickup['address'] ?? 'Base Porto Prime').toString(), connected: true),
          _DeliveryStop(color: const Color(0xFFFF4D64), label: 'Entrega',
            title: target, detail: targetDetail, connected: false),
        ]);
        final accept = FilledButton(
          onPressed: busy ? null : incoming ? onAccept : onAdvance,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF006E59),
            foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF8EABA3),
            minimumSize: const Size(44, 52), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (busy && action != 'reject') const SizedBox(width: 17, height: 17,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else Icon(incoming ? AppIcons.check : primaryIcon ?? AppIcons.route, size: 21),
            const SizedBox(width: 8),
            Flexible(child: PrimeText(busy && action != 'reject' ? 'Confirmando…'
              : incoming ? 'Aceitar entrega' : primaryLabel ?? 'Ver detalhes',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w800))),
          ]));
        final secondary = OutlinedButton.icon(
          onPressed: busy ? null : incoming ? onReject : onDetails,
          style: OutlinedButton.styleFrom(foregroundColor: courierInk,
            backgroundColor: const Color(0xFFF2F6F8), side: const BorderSide(color: Color(0xFFE2EBEE)),
            minimumSize: const Size(44, 52), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          icon: Icon(incoming ? AppIcons.close : AppIcons.list, size: 20),
          label: PrimeText(busy && action == 'reject' ? 'Enviando…' : incoming ? 'Recusar' : 'Detalhes',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)));
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          header, const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            thumbnail, const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PrimeText(_money(earnings), style: const TextStyle(fontSize: 27, height: 1.1,
                fontWeight: FontWeight.w800, letterSpacing: -.8, color: courierGreen)),
              const SizedBox(height: 5),
              PrimeText(_metric(order['routeDistanceKm'], 'km') + ' • ' +
                _metric(order['routeDurationMinutes'], 'min'),
                style: const TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w700, color: courierInk)),
              const SizedBox(height: 6),
              const Row(children: [Icon(AppIcons.bike, size: 16, color: courierInk), SizedBox(width: 6),
                Flexible(child: PrimeText('Entrega Porto Prime', style: TextStyle(fontSize: 10.5,
                  color: Color(0xFF57717D), height: 1.3)))]),
            ])),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: stops),
            if (preview) ...[
              const SizedBox(width: 10),
              SizedBox(width: 86, height: 131, child: _DeliveryPreview(order: order, incoming: incoming)),
            ],
          ]),
          if (incoming) const Padding(padding: EdgeInsets.only(top: 3, bottom: 10),
            child: PrimeText('O endereço completo será liberado após aceitar.',
              style: TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF5B7380)))),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: PrimeText(error!, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.danger))),
          const SizedBox(height: 10),
          if (box.maxWidth < 310 || large) ...[
            accept, const SizedBox(height: 8), secondary,
          ] else Row(children: [
            Expanded(flex: 3, child: secondary), const SizedBox(width: 8),
            Expanded(flex: 5, child: accept),
          ]),
        ]);
      }));
  }
}

class _DeliveryStop extends StatelessWidget {
  const _DeliveryStop({required this.color, required this.label, required this.title,
    required this.detail, required this.connected});
  final Color color;
  final String label, title, detail;
  final bool connected;
  @override Widget build(BuildContext context) => IntrinsicHeight(child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: 15, child: Column(children: [
        const SizedBox(height: 3),
        Container(width: 11, height: 11, decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: .16), spreadRadius: 3)])),
        if (connected) Expanded(child: Container(width: 1, margin: const EdgeInsets.only(top: 4), color: const Color(0xFFB4DAD0))),
      ])),
      const SizedBox(width: 9),
      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PrimeText(label, style: TextStyle(fontSize: 12, height: 1.3, color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          PrimeText(title, style: const TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w700, color: courierInk)),
          const SizedBox(height: 3),
          PrimeText(detail, style: const TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF617985))),
        ]))),
    ]));
}
class _DeliveryPreview extends StatelessWidget {
  const _DeliveryPreview({required this.order, required this.incoming});
  final Map<String, dynamic> order;
  final bool incoming;
  @override Widget build(BuildContext context) {
    final point = incoming ? null : courierMapPoint(order['address']);
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: point == null
      ? Container(color: const Color(0xFFF0F7F8), padding: const EdgeInsets.all(11),
          child: Column(children: [
            const Icon(AppIcons.store, color: courierGreen, size: 23),
            Expanded(child: Center(child: Container(width: 3, decoration: BoxDecoration(
              color: const Color(0xFF37B8DD), borderRadius: BorderRadius.circular(3))))),
            const Icon(AppIcons.mapPin, color: Color(0xFFEF5967), size: 23),
          ]))
      : Stack(children: [
          IgnorePointer(child: FlutterMap(
            key: ValueKey(point.toString()), options: MapOptions(initialCenter: point, initialZoom: 13),
            children: [
              TileLayer(urlTemplate: courierTileUrl, userAgentPackageName: 'com.portoprime.porto_prime'),
              MarkerLayer(markers: [Marker(point: point, width: 26, height: 26,
                child: const Icon(AppIcons.mapPin, size: 26, color: courierGreen))]),
            ])),
          const Positioned(left: 3, bottom: 2, child: Text('© OSM', style: TextStyle(fontSize: 7, color: courierInk))),
        ]));
  }
}

class CourierOpportunities extends StatelessWidget {
  const CourierOpportunities({super.key, required this.offers, required this.onOpen, required this.onAll});
  final List<Map<String, dynamic>> offers;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final VoidCallback onAll;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [
      const Expanded(child: PrimeText('Próximas oportunidades',
        style: TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w800, color: courierInk))),
      if (offers.isNotEmpty) TextButton(onPressed: onAll, child: const PrimeText('Ver todas')),
    ]),
    const SizedBox(height: 10),
    if (offers.isEmpty) Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0EBEF))),
      child: const Row(children: [
        Icon(AppIcons.radar, size: 21, color: courierGreen), SizedBox(width: 11),
        Expanded(child: PrimeText('Novas ofertas aparecem aqui quando disponíveis.',
          style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF617985)))),
      ]))
    else SizedBox(height: 155.0 + (MediaQuery.textScalerOf(context).scale(12) - 12) * 7,
      child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final order = offers[index];
          final value = double.tryParse((order['courierEarnings'] ?? order['deliveryFee'] ?? '').toString());
          return SizedBox(width: 220, child: Material(color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21),
              side: const BorderSide(color: Color(0xFFE0EBEF))),
            child: InkWell(onTap: () => onOpen(order), borderRadius: BorderRadius.circular(21),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PrimeText(value == null ? '—' : 'R\$ ' + value.toStringAsFixed(2).replaceAll('.', ','),
                    style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: courierGreen)),
                  const SizedBox(height: 7),
                  PrimeText((order['routeDistanceKm'] ?? '—').toString() + ' km',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF617985))),
                  const SizedBox(height: 9),
                  Row(children: [
                    Expanded(child: PrimeText((order['dropoff']?['neighborhood'] ?? 'Porto Seguro').toString(),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF617985)))),
                    const Icon(AppIcons.chevronRight, color: courierGreen, size: 18),
                  ]),
                ])))));
        })),
  ]);
}
