import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/courier_dashboard_map.dart';

/// Only the two daily totals belong on Home; the remaining details live in their tabs.
class CourierDailyMetrics extends StatelessWidget {
  const CourierDailyMetrics({super.key, required this.summary,
    required this.onEarnings, required this.onDeliveries});
  final Map<String, dynamic> summary;
  final VoidCallback onEarnings, onDeliveries;

  @override Widget build(BuildContext context) {
    final earnings = summary.containsKey('earningsToday')
      ? 'R\$ ' + (double.tryParse(summary['earningsToday'].toString()) ?? 0)
          .toStringAsFixed(2).replaceAll('.', ',')
      : '—';
    Widget cell(IconData icon, String label, String value, VoidCallback onTap) =>
      Material(color: Colors.transparent, child: InkWell(onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 17, color: const Color(0xFF617985)),
              const SizedBox(width: 7),
              Expanded(child: PrimeText(label, style: const TextStyle(fontSize: 11, height: 1.3,
                color: Color(0xFF617985), fontWeight: FontWeight.w500))),
            ]),
            const SizedBox(height: 8),
            PrimeText(value, style: const TextStyle(fontSize: 21, height: 1.2,
              letterSpacing: -.5, fontWeight: FontWeight.w800, color: courierInk)),
          ]))));
    return Container(decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(23), border: Border.all(color: const Color(0xFFE0EAEE))),
      child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: cell(AppIcons.wallet, 'Ganhos hoje', earnings, onEarnings)),
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8EFF1)),
        Expanded(child: cell(AppIcons.package, 'Entregas hoje',
          (summary['deliveriesToday'] ?? '—').toString(), onDeliveries)),
      ])));
  }
}

class CourierOperationsNav extends StatelessWidget {
  const CourierOperationsNav({super.key, required this.online, required this.active,
    required this.busy, required this.onHome, required this.onWallet, required this.onAction,
    required this.onHistory, required this.onProfile, this.index = 0});
  final bool online, active, busy;
  final int index;
  final VoidCallback onHome, onWallet, onAction, onHistory, onProfile;
  @override Widget build(BuildContext context) => ColoredBox(color: const Color(0xFFF5F9FA),
    child: SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF9AB5BF), width: 1.2),
          boxShadow: const [BoxShadow(color: Color(0x0C16434D), blurRadius: 22, offset: Offset(0, -4))]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _item(0, AppIcons.home, 'Início', onHome),
          _item(1, AppIcons.package, 'Entregas', onAction),
          _item(2, AppIcons.wallet, 'Carteira', onWallet),
          _item(3, Icons.bar_chart_rounded, 'Histórico', onHistory),
          _item(4, AppIcons.user, 'Perfil', onProfile),
        ]))));
  Widget _item(int value, IconData icon, String label, VoidCallback tap) {
    final selected = index == value;
    return Expanded(child: Semantics(selected: selected, button: true,
      child: Tooltip(message: translateLabel(label), child: InkWell(onTap: busy ? null : tap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(selected && value == 0 ? Icons.home_rounded : icon, size: 23, color: selected ? courierGreen : const Color(0xFF5B7380)),
            const SizedBox(height: 6),
            PrimeText(label, maxLines: 2, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, height: 1.25,
                color: selected ? courierGreen : const Color(0xFF5B7380),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
            const SizedBox(height: 6),
            Container(height: 2, width: 22, decoration: BoxDecoration(
              color: selected ? courierGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(2))),
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

