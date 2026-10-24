import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/courier_dashboard_map.dart';

class CourierDailyMetrics extends StatefulWidget {
  const CourierDailyMetrics({super.key, required this.summary, required this.profile,
    required this.online, required this.onEarnings, required this.onDeliveries, required this.onRating});
  final Map<String, dynamic> summary, profile;
  final bool online;
  final VoidCallback onEarnings, onDeliveries, onRating;
  @override State<CourierDailyMetrics> createState() => _CourierDailyMetricsState();
}
class _CourierDailyMetricsState extends State<CourierDailyMetrics> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin<CourierDailyMetrics> {
  final _onlineTime = Stopwatch();
  Timer? _timer;
  bool _foreground = true;
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncClock();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _foreground && _onlineTime.isRunning) setState(() {});
    });
  }
  void _syncClock() {
    if (widget.online && _foreground) { _onlineTime.start(); } else { _onlineTime.stop(); }
  }
  @override void didUpdateWidget(covariant CourierDailyMetrics oldWidget) {
    super.didUpdateWidget(oldWidget); _syncClock();
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncClock();
    if (mounted) setState(() {});
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this); _timer?.cancel(); _onlineTime.stop(); super.dispose();
  }
  String get _duration {
    final minutes = _onlineTime.elapsed.inMinutes;
    return minutes < 60 ? minutes.toString() + 'min'
      : (minutes ~/ 60).toString() + 'h ' + (minutes % 60).toString() + 'min';
  }
  void _showClock() => showDialog<void>(context: context, builder: (context) => AlertDialog(
    title: const PrimeText('Tempo online'),
    content: const PrimeText('Tempo online nesta sessão. A contagem pausa quando você fica offline ou sai do aplicativo.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const PrimeText('Entendi'))],
  ));
  @override bool get wantKeepAlive => true;
  @override Widget build(BuildContext context) {
    super.build(context);
    return Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFE3ECEF)),
      boxShadow: const [BoxShadow(color: Color(0x090E3E49), blurRadius: 18, offset: Offset(0, 6))]),
    child: LayoutBuilder(builder: (context, box) {
      final rating = double.tryParse((widget.profile['ratingAverage'] ??
        widget.profile['averageRating'] ?? widget.profile['rating'] ?? '').toString());
      final values = [
        widget.summary.containsKey('earningsToday')
          ? 'R\$ ' + (double.tryParse(widget.summary['earningsToday'].toString()) ?? 0).toStringAsFixed(2).replaceAll('.', ',') : '—',
        (widget.summary['deliveriesToday'] ?? '—').toString(),
        _duration,
        rating != null && rating > 0 && rating <= 5 ? rating.toStringAsFixed(1).replaceAll('.', ',') : '—',
      ];
      final labels = ['Ganhos hoje', 'Entregas hoje', 'Tempo online', 'Avaliação'];
      final icons = [AppIcons.wallet, Icons.bar_chart_rounded, AppIcons.clock, Icons.star_border_rounded];
      final taps = [widget.onEarnings, widget.onDeliveries, _showClock, widget.onRating];
      final columns = box.maxWidth < 370 || MediaQuery.textScalerOf(context).scale(12) > 15 ? 2 : 4;
      Widget cell(int i) => Material(color: Colors.transparent,
        child: InkWell(onTap: taps[i], borderRadius: BorderRadius.circular(18),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icons[i], size: 21, color: courierInk),
              const SizedBox(height: 9),
              PrimeText(values[i], style: const TextStyle(fontSize: 17, height: 1.25,
                fontWeight: FontWeight.w800, letterSpacing: -.4, color: courierInk)),
              const SizedBox(height: 4),
              PrimeText(labels[i], style: const TextStyle(fontSize: 10.5, height: 1.3,
                color: Color(0xFF5B7380), fontWeight: FontWeight.w500)),
            ]))));
      Widget row(int offset) => IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = offset; i < offset + columns; i++) ...[
          if (i > offset) const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEDF2F4)),
          Expanded(child: cell(i)),
        ]]));
      return Column(mainAxisSize: MainAxisSize.min, children: [
        row(0), if (columns == 2) ...[
          const Divider(height: 1, color: Color(0xFFEDF2F4)), row(2),
        ],
      ]);
    }),
  );
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
  const CourierDashboardEmpty({super.key, required this.online, required this.onRefresh});
  final bool online;
  final VoidCallback onRefresh;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFDDE9ED))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFE7F7EF),
          borderRadius: BorderRadius.circular(15)), child: const Icon(AppIcons.radar, color: courierGreen, size: 25)),
        const SizedBox(width: 12),
        Expanded(child: PrimeText(online ? 'Seu radar está ativo' : 'Você está offline',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: courierInk))),
      ]),
      const SizedBox(height: 12),
      PrimeText(online ? 'A próxima oferta aparece aqui automaticamente.' : 'Conecte-se para receber novas entregas.',
        style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF5B7380))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: onRefresh, icon: const Icon(AppIcons.refresh, size: 17),
        label: const PrimeText('Atualizar entregas')),
    ]),
  );
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

