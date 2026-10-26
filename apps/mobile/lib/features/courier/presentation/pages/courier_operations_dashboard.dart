import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_animated_navigation.dart';
import '../widgets/courier_dashboard_map.dart';

class CourierOperationsNav extends StatelessWidget {
  const CourierOperationsNav({super.key, required this.online, required this.active,
    required this.busy, required this.onHome, required this.onWallet, required this.onAction,
    required this.onHistory, required this.onProfile, this.index = 0});
  final bool online, active, busy;
  final int index;
  final VoidCallback onHome, onWallet, onAction, onHistory, onProfile;
  void _select(int value) {
    if (busy) return;
    final callbacks = [onHome, onAction, onWallet, onHistory, onProfile];
    if (value >= 0 && value < callbacks.length) callbacks[value]();
  }
  @override Widget build(BuildContext context) => PrimeAnimatedNavigation(
    selectedValue: index, enabled: !busy, maxWidth: 760, onSelect: _select,
    destinations: const [
      PrimeNavigationDestination(value: 0, label: 'Início', icon: AppIcons.home,
        selectedIcon: Icons.home_rounded),
      PrimeNavigationDestination(value: 1, label: 'Entregas', icon: AppIcons.package),
      PrimeNavigationDestination(value: 2, label: 'Carteira', icon: AppIcons.wallet),
      PrimeNavigationDestination(value: 3, label: 'Histórico', icon: Icons.bar_chart_rounded),
      PrimeNavigationDestination(value: 4, label: 'Perfil', icon: AppIcons.user),
    ]);
}

/// A single compact summary, only while waiting. Session time is measured locally.
class CourierWaitingPanel extends StatelessWidget {
  const CourierWaitingPanel({super.key, required this.online, required this.summary,
    required this.onlineTime, required this.minimumHeight, required this.onEarnings,
    required this.onDeliveries});
  final bool online;
  final Map<String, dynamic> summary;
  final Duration onlineTime;
  final double minimumHeight;
  final VoidCallback onEarnings, onDeliveries;
  @override Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final radarSize = (box.maxWidth * .82).clamp(200.0, 320.0).toDouble();
    return ConstrainedBox(constraints: BoxConstraints(minHeight: minimumHeight),
      child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [
            CourierSearchingRadar(online: online, size: radarSize),
            const SizedBox(height: 14),
            PrimeText(online ? 'Buscando entregas' : 'Pronto para rodar?',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 20,
                height: 1.3, letterSpacing: -.5, fontWeight: FontWeight.w800, color: courierInk)),
            if (!online) ...[const SizedBox(height: 8),
            const PrimeText('Fique online para receber novas entregas.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5,
                height: 1.6, color: Color(0xFF66818C)))],
          ])),
          const SizedBox(height: 18),
          _WaitingSummary(summary: summary, onlineTime: onlineTime,
            onEarnings: onEarnings, onDeliveries: onDeliveries),
        ])));
  });
}

class _WaitingSummary extends StatelessWidget {
  const _WaitingSummary({required this.summary, required this.onlineTime,
    required this.onEarnings, required this.onDeliveries});
  final Map<String, dynamic> summary;
  final Duration onlineTime;
  final VoidCallback onEarnings, onDeliveries;
  @override Widget build(BuildContext context) {
    final value = double.tryParse(summary['earningsToday']?.toString() ?? '');
    final money = value == null ? '—' : 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
    final hours = onlineTime.inHours;
    final minutes = onlineTime.inMinutes.remainder(60);
    final time = hours == 0 ? '$minutes min' : '$hours h $minutes min';
    final large = MediaQuery.textScalerOf(context).scale(12) > 18;
    Widget cell(IconData icon, String value, String label, VoidCallback? onTap) =>
      Material(color: Colors.transparent, child: InkWell(onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 30, height: 30,
              decoration: const BoxDecoration(color: Color(0xFFEEF6F6), shape: BoxShape.circle),
              child: Icon(icon, color: courierGreen, size: 18)),
            const SizedBox(height: 10),
            PrimeText(value, style: const TextStyle(fontSize: 16, height: 1.3,
              fontWeight: FontWeight.w800, color: courierInk)),
            const SizedBox(height: 4),
            PrimeText(label, style: const TextStyle(fontSize: 10, height: 1.35,
              color: Color(0xFF66818C))),
          ]))));
    final cells = [
      cell(AppIcons.wallet, money, 'Ganhos de hoje', onEarnings),
      cell(AppIcons.package, (summary['deliveriesToday'] ?? '—').toString(), 'Entregas hoje', onDeliveries),
      Tooltip(message: translateLabel('Tempo online nesta sessão. A contagem pausa quando você fica offline ou sai do aplicativo.'),
        child: cell(AppIcons.clock, time, 'Tempo online', null)),
    ];
    return Container(decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2ECEF))),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: large ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFE6EEF0)), cells[i],
        ],
      ]) : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(height: 52,
            child: VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE6EEF0))),
          Expanded(child: cells[i]),
        ],
      ]));
  }
}

class CourierSearchingRadar extends StatefulWidget {
  const CourierSearchingRadar({super.key, required this.online, required this.size});
  final bool online;
  final double size;
  @override State<CourierSearchingRadar> createState() => _CourierSearchingRadarState();
}
class _CourierSearchingRadarState extends State<CourierSearchingRadar> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _orbit = AnimationController(vsync: this,
    duration: const Duration(seconds: 16));
  bool _foreground = true, _reduceMotion = false, _tickerEnabled = true;
  @override void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }
  void _sync() {
    if (widget.online && _foreground && !_reduceMotion && _tickerEnabled) {
      if (!_orbit.isAnimating) _orbit.repeat();
    } else { _orbit.stop(); }
  }
  @override void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled; _sync();
  }
  @override void didUpdateWidget(covariant CourierSearchingRadar oldWidget) { super.didUpdateWidget(oldWidget); _sync(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed; _sync();
  }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _orbit.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ExcludeSemantics(child: RepaintBoundary(child: SizedBox(
    width: widget.size, height: widget.size,
      child: CustomPaint(painter: _RadarPainter(
        online: widget.online, orbit: _orbit),
        child: Center(child: Container(width: widget.size * .34, height: widget.size * .34,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF9FDFD),
            border: Border.all(color: const Color(0xFFC2E8E2), width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x16067469), blurRadius: 14, offset: Offset(0, 6))]),
          child: Icon(Icons.delivery_dining_rounded, color: widget.online ? courierGreen : const Color(0xFF80989F),
            size: widget.size * .17)))))));
}
class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.online, required this.orbit}) : super(repaint: orbit);
  final bool online;
  final Animation<double> orbit;
  @override void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final tint = online ? const Color(0xFF31B6A4) : const Color(0xFF9AB9BC);
    final pulse = online ? (math.sin(orbit.value * math.pi * 4) + 1) / 2 : 0.0;
    for (var i = 5; i >= 1; i--) {
      final ring = radius * (.23 + i * .125);
      canvas.drawCircle(center, ring + pulse * 2,
        Paint()..color = tint.withValues(alpha: .027 + (5 - i) * .019));
    }
    const rings = [(radius: .49, direction: 1.0, offset: .4, dots: 1),
      (radius: .72, direction: -1.0, offset: 2.4, dots: 2),
      (radius: .94, direction: 1.0, offset: -.8, dots: 2)];
    for (final ring in rings) {
      final orbitRadius = radius * ring.radius;
      canvas.drawCircle(center, orbitRadius, Paint()..color = tint.withValues(alpha: .14)
        ..style = PaintingStyle.stroke..strokeWidth = .8);
      for (var dot = 0; dot < ring.dots; dot++) {
        final angle = orbit.value * math.pi * 2 * ring.direction + ring.offset + dot * math.pi;
        final dotSize = radius * (ring.dots == 1 ? .020 : dot == 0 ? .030 : .019);
        final point = center + Offset(math.cos(angle), math.sin(angle)) * orbitRadius;
        if (online) {
          canvas.drawArc(Rect.fromCircle(center: center, radius: orbitRadius),
            angle - ring.direction * .35, ring.direction * .35, false,
            Paint()..color = tint.withValues(alpha: .32)..style = PaintingStyle.stroke
              ..strokeWidth = 2..strokeCap = StrokeCap.round);
          canvas.drawCircle(point, dotSize + radius * .025,
            Paint()..color = tint.withValues(alpha: .10));
        }
        canvas.drawCircle(point, dotSize, Paint()..color = online ? courierGreen : tint);
        canvas.drawCircle(point, dotSize * .32, Paint()..color = Colors.white);
      }
    }
  }
  @override bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
    orbit != oldDelegate.orbit || online != oldDelegate.online;
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
        separatorBuilder: (_, _) => const Divider(height: 1),
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

