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
      style: OutlinedButton.styleFrom(backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F7480), side: const BorderSide(color: Colors.transparent),
        minimumSize: const Size(44, 48), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Flexible(child: PrimeText(busy && action == 'reject' ? 'Enviando…' : 'Recusar',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w700))),
      ])));
    final remaining = seconds ?? 0;
    final total = totalSeconds ?? remaining;
    final fraction = (remaining / (total > 0 ? total : 1)).clamp(0.0, 1.0).toDouble();
    return Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCE8E9)),
        boxShadow: const [BoxShadow(color: Color(0x070D3D44), blurRadius: 24, offset: Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14, runSpacing: 10, children: [
          const PrimeText('Nova entrega', style: TextStyle(fontSize: 17, height: 1.3,
            fontWeight: FontWeight.w800, letterSpacing: -.3, color: courierInk)),
          if (seconds != null) _OfferCountdown(seconds: seconds!),
        ]),
        if (seconds != null) ...[
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: fraction, minHeight: 3,
              backgroundColor: const Color(0xFFEDF3F3),
              color: remaining <= 8 ? const Color(0xFFD19B38) : const Color(0xFF079582))),
        ],
        const SizedBox(height: 22),
        const PrimeText('Valor da entrega', style: TextStyle(fontSize: 12, height: 1.4,
          color: Color(0xFF617B85), fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        PrimeText(money, style: const TextStyle(fontSize: 37, height: 1.15,
          fontWeight: FontWeight.w800, letterSpacing: -1.1, color: courierGreen)),
        const SizedBox(height: 9),
        PrimeText(metric(order['routeDistanceKm'], 'km') + ' • ' + metric(order['routeDurationMinutes'], 'min'),
          style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF4E6875), fontWeight: FontWeight.w600)),
        const SizedBox(height: 22),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF5F9F9), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _OfferStop(label: 'Retirada', title: (pickup['name'] ?? 'Porto Prime Distribuidora').toString(),
              detail: (pickup['region'] ?? 'Base Porto Prime').toString(), pickup: true),
            const Padding(padding: EdgeInsets.fromLTRB(48, 15, 0, 15),
              child: Divider(height: 1, color: Color(0xFFDFEAEB))),
            _OfferStop(label: 'Entrega', title: (dropoff['neighborhood'] ?? 'Região informada').toString(),
              detail: (dropoff['city'] ?? 'Porto Seguro').toString(), pickup: false),
          ])),
        const SizedBox(height: 14),
        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8, runSpacing: 4, children: [
          PrimeText('#' + shortId, style: const TextStyle(fontSize: 10, height: 1.5, color: Color(0xFF6E838B))),
          const PrimeText('Endereço completo após aceitar.', style: TextStyle(fontSize: 10.5,
            height: 1.5, color: Color(0xFF6E838B))),
        ]),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12),
          child: PrimeText(error!, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.danger))),
        const SizedBox(height: 18),
        accept, const SizedBox(height: 6), reject,
      ]));
  }
}

class _OfferStop extends StatelessWidget {
  const _OfferStop({required this.label, required this.title, required this.detail, required this.pickup});
  final String label, title, detail;
  final bool pickup;
  @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 36, height: 36,
      decoration: BoxDecoration(color: pickup ? const Color(0xFFE0F2EC) : Colors.white,
        borderRadius: BorderRadius.circular(12)),
      child: Icon(pickup ? AppIcons.package : AppIcons.mapPin, size: 18, color: courierGreen)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PrimeText(label, style: const TextStyle(fontSize: 11.5, height: 1.4,
        color: Color(0xFF627D86), fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      PrimeText(title, style: const TextStyle(fontSize: 16, height: 1.35,
        fontWeight: FontWeight.w800, letterSpacing: -.2, color: courierInk)),
      if (detail.trim().isNotEmpty) ...[
        const SizedBox(height: 5),
        PrimeText(detail, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF627D86))),
      ],
    ])),
  ]);
}

class _OfferCountdown extends StatelessWidget {
  const _OfferCountdown({required this.seconds});
  final int seconds;
  @override Widget build(BuildContext context) {
    final urgent = seconds <= 8;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    final color = urgent ? const Color(0xFF926021) : courierGreen;
    return Semantics(label: translateLabel('Tempo para aceitar'), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: urgent ? const Color(0xFFFFF4E3) : const Color(0xFFEDF6F3),
        borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(AppIcons.clock, size: 16, color: color), const SizedBox(width: 7),
        PrimeText('$minutes:$rest', style: TextStyle(fontSize: 13, height: 1.2,
          fontWeight: FontWeight.w800, color: color)),
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
