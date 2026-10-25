import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import 'courier_dashboard_map.dart' show courierGreen, courierInk;
import 'courier_assigned_delivery.dart';

/// Presentation only: the timer, dispatch callbacks and private address boundary stay intact.
class CourierDeliverySurface extends StatelessWidget {
  const CourierDeliverySurface({super.key, required this.order, required this.incoming,
    this.seconds, this.totalSeconds, this.busy = false, this.action, this.error,
    this.onAccept, this.onReject, this.onDetails, this.onAdvance,
    this.primaryLabel, this.primaryIcon, this.statusLabel});
  final Map<String, dynamic> order;
  final bool incoming, busy;
  final int? seconds, totalSeconds;
  final String? action, error, primaryLabel, statusLabel;
  final IconData? primaryIcon;
  final VoidCallback? onAccept, onReject, onDetails, onAdvance;
  @override Widget build(BuildContext context) {
    if (!incoming) return CourierAssignedDelivery(order: order, busy: busy,
      primaryLabel: primaryLabel ?? 'Ver detalhes', primaryIcon: primaryIcon ?? AppIcons.list,
      onAdvance: onAdvance, onDetails: onDetails);
    final pickup = order['pickup'] is Map ? Map<String, dynamic>.from(order['pickup']) : <String, dynamic>{};
    final dropoff = order['dropoff'] is Map ? Map<String, dynamic>.from(order['dropoff']) : <String, dynamic>{};
    final id = (order['orderId'] ?? order['id'] ?? '').toString();
    final shortId = id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();
    final amount = double.tryParse((order['courierEarnings'] ?? order['deliveryFee'] ?? '').toString());
    final money = amount == null ? '—' : 'R\$ ' + amount.toStringAsFixed(2).replaceAll('.', ',');
    String metric(dynamic value, String suffix) {
      final parsed = double.tryParse(value?.toString() ?? '');
      return parsed == null ? '—' : parsed.toStringAsFixed(suffix == 'km' ? 1 : 0).replaceAll('.', ',') + ' ' + suffix;
    }
    final accept = FilledButton(
      onPressed: busy ? null : onAccept,
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF008574),
        foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFF91B2AB),
        minimumSize: const Size(44, 54), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (busy && action != 'reject') const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        else const Icon(AppIcons.check, size: 23),
        const SizedBox(width: 8),
        Flexible(child: PrimeText(busy && action != 'reject' ? 'Confirmando…' : 'Aceitar entrega',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w800))),
      ]));
    final reject = Tooltip(message: translateLabel('Recusar entrega'), child: OutlinedButton(
      onPressed: busy ? null : onReject,
      style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFF1F5F6),
        foregroundColor: courierInk, side: const BorderSide(color: Color(0xFFE6EEF0)),
        minimumSize: const Size(44, 54), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(AppIcons.close, size: 23), const SizedBox(width: 8),
        Flexible(child: PrimeText(busy && action == 'reject' ? 'Enviando…' : 'Recusar',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w700))),
      ])));
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          stops: [0, .22, 1], colors: [Color(0xFFFFFCF3), Colors.white, Colors.white]),
        border: Border.all(color: const Color(0xFFE5ECEC)),
        boxShadow: const [BoxShadow(color: Color(0x080D3D44), blurRadius: 22, offset: Offset(0, 8))]),
      child: LayoutBuilder(builder: (context, box) {
        final large = MediaQuery.textScalerOf(context).scale(14) > 19;
        final image = ClipRRect(borderRadius: BorderRadius.circular(13),
          child: Image.asset('assets/reference_home/courier-pickup-bag.webp', fit: BoxFit.cover,
            excludeFromSemantics: true, errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFFF0F5F6), child: Center(child: Icon(AppIcons.package, size: 38, color: courierGreen)))));
        final pay = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PrimeText(money, style: const TextStyle(fontSize: 31, height: 1.15,
            fontWeight: FontWeight.w800, letterSpacing: -.9, color: courierInk)),
          const SizedBox(height: 8),
          PrimeText(metric(order['routeDistanceKm'], 'km') + ' • ' + metric(order['routeDurationMinutes'], 'min'),
            style: const TextStyle(fontSize: 15, height: 1.4, color: courierInk, fontWeight: FontWeight.w600)),
          const SizedBox(height: 9),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFFF0F5F6), borderRadius: BorderRadius.circular(18)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.delivery_dining_rounded, size: 17, color: courierInk), SizedBox(width: 5),
              Flexible(child: PrimeText('Entrega Porto Prime', style: TextStyle(fontSize: 10.5,
                height: 1.3, color: Color(0xFF577782)))),
            ])),
        ]);
        final stops = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _OfferStop(label: 'Retirada', title: (pickup['name'] ?? 'Porto Prime Distribuidora').toString(),
            detail: (pickup['region'] ?? 'Base Porto Prime').toString(), pickup: true),
          _OfferStop(label: 'Entrega', title: (dropoff['neighborhood'] ?? 'Região informada').toString(),
            detail: (dropoff['city'] ?? 'Porto Seguro').toString(), pickup: false),
        ]);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Align(alignment: Alignment.centerLeft, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFFFE8B9), borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(AppIcons.energy, color: Color(0xFFD48B0D), size: 22), SizedBox(width: 8),
                Flexible(child: PrimeText('NOVA ENTREGA', style: TextStyle(fontSize: 11,
                  height: 1.3, fontWeight: FontWeight.w800, color: Color(0xFF4C350B)))),
              ])))),
            const SizedBox(width: 10),
            if (seconds != null) _OfferCountdown(seconds: seconds!, total: totalSeconds),
          ]),
          const SizedBox(height: 19),
          if (large) ...[
            SizedBox(height: 142, child: image), const SizedBox(height: 14), pay,
          ] else Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(width: box.maxWidth < 300 ? 87 : 109, height: 132, child: image),
            const SizedBox(width: 14), Expanded(child: pay),
          ]),
          const SizedBox(height: 21),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: stops),
            if (box.maxWidth >= 300 && !large) ...[
              const SizedBox(width: 12),
              const SizedBox(width: 86, height: 164, child: _OfferProtectedRoute()),
            ],
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 5, alignment: WrapAlignment.spaceBetween, children: [
            PrimeText('#' + shortId, style: const TextStyle(fontSize: 9, height: 1.4, color: Color(0xFF7A909A))),
            const PrimeText('Endereço completo após aceitar.', style: TextStyle(fontSize: 9,
              height: 1.4, color: Color(0xFF7A909A))),
          ]),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12),
            child: PrimeText(error!, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.danger))),
          const SizedBox(height: 18),
          if (large || box.maxWidth < 300) ...[accept, const SizedBox(height: 9), reject]
          else Row(children: [Expanded(flex: 4, child: reject), const SizedBox(width: 9),
            Expanded(flex: 6, child: accept)]),
        ]);
      }));
  }
}
class _OfferStop extends StatelessWidget {
  const _OfferStop({required this.label, required this.title, required this.detail, required this.pickup});
  final String label, title, detail;
  final bool pickup;
  @override Widget build(BuildContext context) {
    final color = pickup ? const Color(0xFF00A77B) : const Color(0xFFFF3E50);
    return Stack(children: [
      if (pickup) const Positioned(left: 6, top: 13, bottom: 0,
        child: SizedBox(width: 1, child: ColoredBox(color: Color(0xFFB5CDD1)))),
      Padding(padding: EdgeInsets.fromLTRB(24, 0, 0, pickup ? 20 : 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PrimeText(label, style: TextStyle(fontSize: 11, height: 1.3, color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          PrimeText(title, style: const TextStyle(fontSize: 13, height: 1.3,
            fontWeight: FontWeight.w800, color: courierInk)),
          const SizedBox(height: 3),
          PrimeText(detail, style: const TextStyle(fontSize: 10.5, height: 1.5, color: Color(0xFF64808E))),
        ])),
      Positioned(left: 0, top: 1, child: Container(width: 14, height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: .18), width: 3)))),
    ]);
  }
}
class _OfferProtectedRoute extends StatelessWidget {
  const _OfferProtectedRoute();
  @override Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: const Color(0xFFF0F5F5), borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE4EDED))),
    padding: const EdgeInsets.all(9),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(AppIcons.route, size: 27, color: Color(0xFF9EB7BC)), const SizedBox(height: 13),
      const Icon(AppIcons.lock, size: 16, color: courierGreen), const SizedBox(height: 7),
      const PrimeText('Rota após aceitar', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 9, height: 1.5, color: Color(0xFF6E8791))),
    ]));
}
class _OfferCountdown extends StatelessWidget {
  const _OfferCountdown({required this.seconds, required this.total});
  final int seconds;
  final int? total;
  @override Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(12) > 18;
    final size = large ? 88.0 : 51.0;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return Semantics(label: translateLabel('Tempo para aceitar'), child: SizedBox(
      width: size, height: size, child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: CircularProgressIndicator(strokeWidth: 3.5, strokeCap: StrokeCap.round,
          value: (seconds / ((total ?? seconds) > 0 ? (total ?? seconds) : 1)).clamp(0.0, 1.0).toDouble(),
          backgroundColor: const Color(0xFFFAEFD7), color: seconds <= 8 ? AppColors.danger : const Color(0xFFF4AE00))),
        PrimeText('$minutes:$rest', style: const TextStyle(fontSize: 11.5,
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
