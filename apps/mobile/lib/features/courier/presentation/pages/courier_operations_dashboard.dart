import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/courier_dashboard_map.dart';

/// The only amount shown on Home. Detailed earnings remain in the wallet.
class CourierWalletShortcut extends StatelessWidget {
  const CourierWalletShortcut({super.key, required this.summary, required this.onTap});
  final Map<String, dynamic> summary;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) {
    final amount = double.tryParse(summary['availableBalance']?.toString() ?? '');
    final money = amount == null ? '—' : 'R\$ ' + amount.toStringAsFixed(2).replaceAll('.', ',');
    return Semantics(button: true, label: translateLabel('Abrir carteira'),
      child: Material(color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFDDE9EC))),
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: const Color(0xFFEDF5F5),
                  borderRadius: BorderRadius.circular(15)),
                child: const Icon(AppIcons.wallet, color: courierGreen, size: 23)),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const PrimeText('Na sua carteira', style: TextStyle(fontSize: 11,
                  height: 1.4, fontWeight: FontWeight.w500, color: Color(0xFF607B87))),
                const SizedBox(height: 3),
                PrimeText(money, style: const TextStyle(fontSize: 22, height: 1.25,
                  letterSpacing: -.6, fontWeight: FontWeight.w800, color: courierInk)),
              ])),
              const SizedBox(width: 14),
              const Icon(AppIcons.arrowUpRight, color: courierGreen, size: 23),
            ])))));
  }
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

/// An operational waiting state, with no simulated offers, scores or incentives.
class CourierStandbySurface extends StatelessWidget {
  const CourierStandbySurface({super.key, required this.online});
  final bool online;
  @override Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 240),
        child: Column(key: ValueKey(online), mainAxisSize: MainAxisSize.min, children: [
          _CourierStandbyArtwork(online: online),
          const SizedBox(height: 17),
          PrimeText(online ? 'Sua próxima entrega' : 'Pronto quando você estiver',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, height: 1.2, letterSpacing: -.7,
              fontWeight: FontWeight.w800, color: courierInk)),
          const SizedBox(height: 10),
          PrimeText(online ? 'Avisaremos assim que uma oferta chegar.'
            : 'Fique online para receber novas entregas.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF6A818D))),
        ]))));
}

class _CourierStandbyArtwork extends StatelessWidget {
  const _CourierStandbyArtwork({required this.online});
  final bool online;
  @override Widget build(BuildContext context) => ExcludeSemantics(child: SizedBox(
    width: 224, height: 158, child: Stack(alignment: Alignment.center, children: [
      Positioned.fill(child: CustomPaint(painter: _StandbyRoutePainter(online))),
      Container(width: 96, height: 96,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: online ? const [Color(0xFF0B7778), Color(0xFF06494E)]
              : const [Color(0xFF81959E), Color(0xFF526973)]),
          borderRadius: BorderRadius.circular(33),
          border: Border.all(color: Colors.white.withValues(alpha: .65), width: 1.5),
          boxShadow: [BoxShadow(color: courierGreen.withValues(alpha: online ? .17 : .06),
            blurRadius: 30, spreadRadius: 1, offset: const Offset(0, 12))]),
        child: const Icon(AppIcons.bike, color: Colors.white, size: 47)),
      Positioned(left: 139, top: 101, child: Container(width: 30, height: 30,
        decoration: BoxDecoration(color: online ? const Color(0xFFE1F4EB) : const Color(0xFFEDF1F3),
          shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF5F9FA), width: 3)),
        child: Icon(online ? AppIcons.check : AppIcons.clock,
          size: 15, color: online ? const Color(0xFF21886D) : const Color(0xFF6B818B)))),
    ])));
}

class _StandbyRoutePainter extends CustomPainter {
  const _StandbyRoutePainter(this.online);
  final bool online;
  @override void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 67, Paint()..color = const Color(0xFFE8F2F3));
    canvas.drawCircle(center, 75, Paint()..color = const Color(0xFFDDECEF)
      ..style = PaintingStyle.stroke..strokeWidth = 1);
    final path = Path()..moveTo(8, 112)..cubicTo(48, 112, 27, 42, 63, 42)
      ..moveTo(162, 118)..cubicTo(200, 118, 181, 52, 215, 52);
    final stroke = Paint()..color = const Color(0xFFBBD4D9)
      ..strokeWidth = 1.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 8) {
        canvas.drawPath(metric.extractPath(distance, (distance + 3).clamp(0.0, metric.length).toDouble()), stroke);
      }
    }
    for (final point in [const Offset(8, 112), const Offset(215, 52)]) {
      canvas.drawCircle(point, 5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, Paint()..color = online ? const Color(0xFF76A7AA) : const Color(0xFFA0B5BE));
    }
  }
  @override bool shouldRepaint(covariant _StandbyRoutePainter oldDelegate) => online != oldDelegate.online;
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

