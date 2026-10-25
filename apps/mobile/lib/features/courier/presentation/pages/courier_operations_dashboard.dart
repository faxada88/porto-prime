import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/courier_dashboard_map.dart';

String courierDashboardMoney(dynamic value) {
  final amount = double.tryParse(value?.toString() ?? '');
  return amount == null ? '—' : 'R\$ ' + amount.toStringAsFixed(2).replaceAll('.', ',');
}

class CourierDailyMetrics extends StatelessWidget {
  const CourierDailyMetrics({super.key, required this.summary,
    required this.onEarnings, required this.onDeliveries, required this.onWallet});
  final Map<String, dynamic> summary;
  final VoidCallback onEarnings, onDeliveries, onWallet;
  @override Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final large = MediaQuery.textScalerOf(context).scale(14) > 19;
    final cards = [
      _MetricCard(icon: AppIcons.wallet, label: 'Ganhos de hoje',
        value: courierDashboardMoney(summary['earningsToday']), onTap: onEarnings),
      _MetricCard(icon: AppIcons.package, label: 'Entregas hoje',
        value: (summary['deliveriesToday'] ?? '—').toString(), onTap: onDeliveries),
      _MetricCard(icon: Icons.bar_chart_rounded, label: 'Saldo disponível',
        value: courierDashboardMoney(summary['availableBalance']), onTap: onWallet),
    ];
    if (large) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(height: 10), cards[i],
      ],
    ]);
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(width: 8), Expanded(child: cards[i]),
      ],
    ]));
  });
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => Material(color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: Color(0xFFE4EDF0))),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 31, height: 31, alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF0F5F6),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 19, color: courierGreen)),
          const SizedBox(height: 11),
          PrimeText(value, style: const TextStyle(fontSize: 17, height: 1.25,
            fontWeight: FontWeight.w800, letterSpacing: -.5, color: courierInk)),
          const SizedBox(height: 5),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: PrimeText(label, style: const TextStyle(fontSize: 10, height: 1.35,
              color: Color(0xFF6A8390)))),
            const SizedBox(width: 2), const Icon(AppIcons.chevronRight, size: 12, color: courierGreen),
          ]),
        ]))));
}

/// Only server totals are shown; a limited ledger is never treated as a monthly total.
class CourierEarningsOverview extends StatelessWidget {
  const CourierEarningsOverview({super.key, required this.summary, required this.onWallet});
  final Map<String, dynamic> summary;
  final VoidCallback onWallet;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [
      const Expanded(child: PrimeText('Seus ganhos', style: TextStyle(fontSize: 20,
        height: 1.3, fontWeight: FontWeight.w800, letterSpacing: -.5, color: courierInk))),
      TextButton(onPressed: onWallet, style: TextButton.styleFrom(foregroundColor: courierGreen,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          PrimeText('Ver carteira', style: TextStyle(fontSize: 12)),
          SizedBox(width: 2), Icon(AppIcons.chevronRight, size: 16),
        ])),
    ]),
    const SizedBox(height: 8),
    LayoutBuilder(builder: (context, box) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 19;
      Widget card(String label, dynamic value, String? count) => Material(color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFFE4EDF0))),
        child: InkWell(onTap: onWallet, borderRadius: BorderRadius.circular(17),
          child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: PrimeText(label, style: const TextStyle(fontSize: 11,
                height: 1.3, color: Color(0xFF56707D)))),
              const SizedBox(width: 3), const Icon(Icons.bar_chart_rounded,
                size: 18, color: courierGreen),
            ]),
            const SizedBox(height: 10),
            PrimeText(courierDashboardMoney(value), style: const TextStyle(fontSize: 16,
              height: 1.3, letterSpacing: -.4, fontWeight: FontWeight.w800, color: courierInk)),
            const SizedBox(height: 5),
            PrimeText(count ?? 'Disponível para saque', style: const TextStyle(fontSize: 10,
              height: 1.35, color: Color(0xFF6A8390))),
          ]))));
      String? deliveries(String key) {
        final count = summary[key];
        return count == null ? '—' : count == 1 ? '$count entrega' : '$count entregas';
      }
      final cards = [
        card('Hoje', summary['earningsToday'], deliveries('deliveriesToday')),
        card('Semana', summary['earningsWeek'], deliveries('deliveriesWeek')),
        card('Carteira', summary['availableBalance'], null),
      ];
      if (large) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 10), cards[i],
        ],
      ]);
      return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 8), Expanded(child: cards[i]),
        ],
      ]));
    }),
  ]);
}

class CourierOperationsNav extends StatelessWidget {
  const CourierOperationsNav({super.key, required this.online, required this.active,
    required this.busy, required this.onHome, required this.onWallet, required this.onAction,
    required this.onHistory, required this.onProfile, this.index = 0});
  final bool online, active, busy;
  final int index;
  final VoidCallback onHome, onWallet, onAction, onHistory, onProfile;
  @override Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      border: Border.fromBorderSide(BorderSide(color: Color(0xFFD9E7EB), width: 1)),
      boxShadow: [BoxShadow(color: Color(0x0C16434D), blurRadius: 24, offset: Offset(0, -5))]),
    child: SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(12, 8, 12, 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _item(0, AppIcons.home, 'Início', onHome),
        _item(1, AppIcons.package, 'Entregas', onAction),
        _item(2, AppIcons.wallet, 'Carteira', onWallet),
        _item(3, Icons.bar_chart_rounded, 'Histórico', onHistory),
        _item(4, AppIcons.user, 'Perfil', onProfile),
      ])));
  Widget _item(int value, IconData icon, String label, VoidCallback tap) {
    final selected = index == value;
    return Expanded(child: Semantics(selected: selected, button: true,
      child: Tooltip(message: translateLabel(label), child: InkWell(onTap: busy ? null : tap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(selected && value == 0 ? Icons.home_rounded : icon, size: 25,
              color: selected ? courierGreen : const Color(0xFF5B7380)),
            const SizedBox(height: 6),
            PrimeText(label, maxLines: 2, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, height: 1.25,
                color: selected ? courierGreen : const Color(0xFF5B7380),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
            const SizedBox(height: 6),
            Container(height: 2.5, width: 24, decoration: BoxDecoration(
              color: selected ? courierGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(3))),
          ]))))));
  }
}

class CourierDashboardEmpty extends StatelessWidget {
  const CourierDashboardEmpty({super.key, required this.online});
  final bool online;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23),
      border: Border.all(color: const Color(0xFFE0EAEE))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEAF5EF),
        borderRadius: BorderRadius.circular(14)),
        child: Icon(online ? AppIcons.radar : AppIcons.bike, color: courierGreen, size: 23)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PrimeText(online ? 'Buscando entregas' : 'Pronto para rodar?',
          style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w800, color: courierInk)),
        const SizedBox(height: 5),
        PrimeText(online ? 'Avisaremos quando uma oferta chegar.' : 'Fique online quando estiver disponível.',
          style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF617985))),
      ])),
    ]));
}

class CourierDashboardUpdate {
  const CourierDashboardUpdate({required this.id, required this.title, required this.detail,
    required this.icon, required this.onTap});
  final String id, title, detail;
  final IconData icon;
  final VoidCallback onTap;
}

class CourierUpdatesSheet extends StatelessWidget {
  const CourierUpdatesSheet({super.key, required this.rows, required this.readIds,
    required this.onReadAll, required this.onSelect});
  final List<CourierDashboardUpdate> rows;
  final Set<String> readIds;
  final VoidCallback onReadAll;
  final ValueChanged<CourierDashboardUpdate> onSelect;
  @override Widget build(BuildContext context) => SafeArea(top: false, child: Container(
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: Container(width: 38, height: 4,
        decoration: BoxDecoration(color: AppColors.strokeStrong, borderRadius: BorderRadius.circular(4)))),
      const SizedBox(height: 14),
      Row(children: [
        const Expanded(child: PrimeText('Atualizações', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        IconButton(onPressed: () => Navigator.pop(context), tooltip: translateLabel('Fechar'),
          icon: const Icon(AppIcons.close)),
      ]),
      if (rows.any((r) => !readIds.contains(r.id)))
        Align(alignment: Alignment.centerRight, child: TextButton(
          onPressed: onReadAll, child: const PrimeText('Marcar todas como lidas'))),
      if (rows.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Column(children: [
        Icon(AppIcons.checkCircle, color: courierGreen, size: 38), SizedBox(height: 12),
        PrimeText('Tudo em dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 8), PrimeText('Novas entregas e movimentações aparecerão aqui.',
          textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, height: 1.5)),
      ])),
      Flexible(child: ListView.separated(shrinkWrap: true, itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final row = rows[i], read = readIds.contains(rows[i].id);
          return ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 5),
            onTap: () => onSelect(row),
            leading: CircleAvatar(backgroundColor: const Color(0xFFEAF6F0),
              child: Icon(row.icon, color: courierGreen, size: 20)),
            title: PrimeText(row.title, style: TextStyle(fontSize: 14,
              fontWeight: read ? FontWeight.w500 : FontWeight.w800)),
            subtitle: PrimeText(row.detail, style: const TextStyle(fontSize: 12, height: 1.4)),
            trailing: read ? const Icon(AppIcons.chevronRight, size: 17)
              : Container(width: 7, height: 7, decoration: const BoxDecoration(color: courierGreen, shape: BoxShape.circle)));
        })),
    ])));
}

