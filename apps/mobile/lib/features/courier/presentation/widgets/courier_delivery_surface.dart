import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import 'courier_dashboard_map.dart' show courierGreen, courierInk;

/// A real offer keeps its server timer, earnings, address visibility and callbacks.
class CourierDeliverySurface extends StatelessWidget {
  const CourierDeliverySurface({super.key, required this.order, required this.incoming,
    this.seconds, this.totalSeconds, this.busy = false, this.action, this.error, this.onAccept, this.onReject,
    this.onDetails, this.onAdvance, this.primaryLabel, this.primaryIcon, this.statusLabel});
  final Map<String, dynamic> order;
  final bool incoming, busy;
  final int? seconds, totalSeconds;
  final String? action, error, primaryLabel, statusLabel;
  final IconData? primaryIcon;
  final VoidCallback? onAccept, onReject, onDetails, onAdvance;
  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '');
    return amount == null ? '—' : 'R\$ ' + amount.toStringAsFixed(2).replaceAll('.', ',');
  }
  String _metric(dynamic value, String unit) {
    final number = double.tryParse(value?.toString() ?? '');
    return number == null ? '—'
      : number.toStringAsFixed(unit == 'km' ? 1 : 0).replaceAll('.', ',') + ' ' + unit;
  }
  @override Widget build(BuildContext context) {
    final pickup = order['pickup'] is Map ? Map<String, dynamic>.from(order['pickup']) : <String, dynamic>{};
    final dropoff = order['dropoff'] is Map ? Map<String, dynamic>.from(order['dropoff']) : <String, dynamic>{};
    final address = !incoming && order['address'] is Map
      ? Map<String, dynamic>.from(order['address']) : <String, dynamic>{};
    final id = (order['orderId'] ?? order['id'] ?? '').toString();
    final shortId = id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();
    final target = incoming ? (dropoff['neighborhood'] ?? 'Região informada').toString()
      : (order['customer']?['name'] ?? 'Cliente Porto Prime').toString();
    final targetDetail = incoming ? (dropoff['city'] ?? 'Porto Seguro').toString()
      : [address['street'], address['number'], address['neighborhood']]
        .where((x) => x != null && x.toString().isNotEmpty).join(', ');
    String? image;
    if (!incoming && order['items'] is List && (order['items'] as List).isNotEmpty) {
      final first = (order['items'] as List).first;
      if (first is Map) image = (first['imageUrl'] ?? first['product']?['imageUrl'])?.toString();
    }
    Widget artwork() => Image.asset('assets/reference_home/courier-pickup-bag.webp',
      fit: BoxFit.cover, excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF0F5F6),
        child: Center(child: Icon(AppIcons.package, size: 35, color: courierGreen))));
    final photo = ClipRRect(borderRadius: BorderRadius.circular(13),
      child: image != null && image.isNotEmpty
        ? ColoredBox(color: const Color(0xFFF0F5F6), child: Image.network(image,
            fit: BoxFit.contain, excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => artwork()))
        : artwork());
    final stops = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _DeliveryStop(color: const Color(0xFF14B88D), label: 'COLETA',
        title: (pickup['name'] ?? 'Porto Prime Distribuidora').toString(),
        detail: (pickup['region'] ?? pickup['address'] ?? 'Base Porto Prime').toString(), connected: true),
      _DeliveryStop(color: const Color(0xFFF04456), label: 'ENTREGA',
        title: target, detail: targetDetail, connected: false),
    ]);
    final accept = FilledButton(
      onPressed: busy ? null : incoming ? onAccept : onAdvance,
      style: FilledButton.styleFrom(backgroundColor: courierGreen,
        foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF91B2B2),
        minimumSize: const Size(44, 52),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (busy && action != 'reject') const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        else Icon(incoming ? AppIcons.check : primaryIcon ?? AppIcons.route, size: 22),
        const SizedBox(width: 8),
        Flexible(child: PrimeText(busy && action != 'reject' ? 'Confirmando…'
          : incoming ? 'Aceitar entrega' : primaryLabel ?? 'Ver detalhes',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w800))),
      ]));
    final secondary = Tooltip(message: translateLabel(incoming ? 'Recusar entrega' : 'Ver detalhes'),
      child: OutlinedButton(
        onPressed: busy ? null : incoming ? onReject : onDetails,
        style: OutlinedButton.styleFrom(foregroundColor: courierInk,
          backgroundColor: const Color(0xFFF0F5F6), side: const BorderSide(color: Color(0xFFE3ECEF)),
          minimumSize: const Size(44, 52),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(incoming ? AppIcons.close : AppIcons.list, size: 22),
          const SizedBox(width: 8),
          Flexible(child: PrimeText(busy && action == 'reject' ? 'Enviando…' : incoming ? 'Recusar' : 'Detalhes',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w700))),
        ])));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.fromLTRB(3, 0, 3, 12),
        child: Row(children: [
          Expanded(child: PrimeText(incoming ? 'Entrega disponível' : 'Sua entrega',
            style: const TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w800,
              letterSpacing: -.5, color: courierInk))),
          const SizedBox(width: 12),
          if (seconds != null) _OfferCountdown(seconds: seconds!, total: totalSeconds),
        ])),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE1ECEF)),
          boxShadow: const [BoxShadow(color: Color(0x080C3F47), blurRadius: 20, offset: Offset(0, 8))]),
        child: LayoutBuilder(builder: (context, box) {
          final large = MediaQuery.textScalerOf(context).scale(14) > 19;
          final stacked = box.maxWidth < 265 || large;
          final metadata = Wrap(spacing: 8, runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center, children: [
            PrimeText('#' + shortId, style: const TextStyle(fontSize: 9,
              height: 1.3, color: Color(0xFF78909B), fontWeight: FontWeight.w600)),
            if (!incoming) PrimeText(statusLabel ?? 'Entrega em andamento',
              style: const TextStyle(fontSize: 10, height: 1.3,
                color: courierGreen, fontWeight: FontWeight.w700)),
          ]);
          final metrics = <Widget>[
            _OfferMetric(icon: AppIcons.route, label: 'Distância',
              value: _metric(order['routeDistanceKm'], 'km'), horizontal: large || box.maxWidth < 280),
            _OfferMetric(icon: AppIcons.clock, label: 'Tempo estimado',
              value: _metric(order['routeDurationMinutes'], 'min'), horizontal: large || box.maxWidth < 280),
            _OfferMetric(icon: AppIcons.money, label: 'Valor da entrega',
              value: _money(order['courierEarnings'] ?? order['deliveryFee']), horizontal: large || box.maxWidth < 280),
          ];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (stacked) ...[
              SizedBox(height: 116, child: photo), const SizedBox(height: 16), stops,
            ] else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: box.maxWidth < 320 ? 90 : 108, height: 149, child: photo),
              const SizedBox(width: 13), Expanded(child: stops),
            ]),
            const SizedBox(height: 12), metadata,
            const SizedBox(height: 14),
            if (large || box.maxWidth < 280)
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6), metrics[i],
                ],
              ])
            else IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const SizedBox(width: 7), Expanded(child: metrics[i]),
              ],
            ])),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 12),
              child: PrimeText(error!, style: const TextStyle(fontSize: 12,
                height: 1.4, color: AppColors.danger))),
            const SizedBox(height: 14),
            if (box.maxWidth < 300 || large) ...[
              accept, const SizedBox(height: 8), secondary,
            ] else Row(children: [
              Expanded(flex: 4, child: secondary), const SizedBox(width: 8),
              Expanded(flex: 5, child: accept),
            ]),
          ]);
        })),
    ]);
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
    SizedBox(width: 14, child: Column(children: [
      const SizedBox(height: 6),
      Container(width: 11, height: 11, decoration: BoxDecoration(shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5))),
      if (connected) Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 5),
        child: CustomPaint(size: const Size(1, 0), painter: _StopConnector()))),
    ])),
    const SizedBox(width: 7),
    Expanded(child: Padding(padding: EdgeInsets.only(bottom: connected ? 13 : 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(18)),
          child: PrimeText(label, style: TextStyle(fontSize: 8, height: 1.2,
            letterSpacing: .3, color: color, fontWeight: FontWeight.w800))),
        const SizedBox(height: 5),
        PrimeText(title, style: const TextStyle(fontSize: 13, height: 1.25,
          fontWeight: FontWeight.w800, color: courierInk)),
        const SizedBox(height: 3),
        PrimeText(detail, style: const TextStyle(fontSize: 10.5, height: 1.4, color: Color(0xFF617B88))),
      ]))),
  ]));
}

class _StopConnector extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFB6CED3)..strokeWidth = 1.3;
    for (var y = 0.0; y < size.height; y += 6) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, (y + 3).clamp(0.0, size.height).toDouble()), paint);
    }
  }
  @override bool shouldRepaint(covariant _StopConnector oldDelegate) => false;
}

class _OfferMetric extends StatelessWidget {
  const _OfferMetric({required this.icon, required this.label, required this.value, required this.horizontal});
  final IconData icon;
  final String label, value;
  final bool horizontal;
  @override Widget build(BuildContext context) {
    final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PrimeText(value, style: const TextStyle(fontSize: 14, height: 1.25,
        fontWeight: FontWeight.w800, color: courierInk)),
      const SizedBox(height: 4),
      PrimeText(label, style: const TextStyle(fontSize: 9, height: 1.35, color: Color(0xFF69818E))),
    ]);
    return Container(padding: EdgeInsets.all(horizontal ? 12 : 9),
      decoration: BoxDecoration(color: const Color(0xFFF1F6F7), borderRadius: BorderRadius.circular(13)),
      child: horizontal ? Row(children: [
        Icon(icon, size: 21, color: courierGreen), const SizedBox(width: 12), Expanded(child: copy),
      ]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: courierGreen), const SizedBox(height: 8), copy,
      ]));
  }
}

class _OfferCountdown extends StatelessWidget {
  const _OfferCountdown({required this.seconds, required this.total});
  final int seconds;
  final int? total;
  @override Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(12) > 18;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    final size = large ? 88.0 : 54.0;
    return Semantics(label: translateLabel('Tempo para aceitar'), child: SizedBox(
      width: size, height: size, child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: CircularProgressIndicator(
          value: (seconds / ((total ?? seconds) > 0 ? (total ?? seconds) : 1)).clamp(0.0, 1.0).toDouble(), strokeWidth: 3.5,
          strokeCap: StrokeCap.round, backgroundColor: const Color(0xFFEAF0F2),
          color: seconds <= 8 ? const Color(0xFFF04456) : const Color(0xFFE2AD44))),
        PrimeText('$minutes:$remainder', style: const TextStyle(fontSize: 12,
          height: 1.2, fontWeight: FontWeight.w800, color: courierInk)),
      ])));
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
