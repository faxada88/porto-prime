import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/courier_portrait.dart';
import '../../../../core/widgets/prime_ui.dart';
import 'courier_dashboard_map.dart' show courierGreen, courierInk;

/// Availability is one action. The avatar also exposes the existing logout.
class CourierDashboardHeader extends StatefulWidget {
  const CourierDashboardHeader({super.key, required this.name, required this.photo,
    required this.online, required this.active, required this.unreadCount,
    required this.onNotifications, required this.onProfile, required this.onLogout,
    required this.onRoute, required this.onChanged});
  final String name;
  final String? photo;
  final bool online, active;
  final int unreadCount;
  final VoidCallback onNotifications, onProfile, onRoute;
  final VoidCallback? onLogout;
  final Future<void> Function(bool)? onChanged;
  @override State<CourierDashboardHeader> createState() => _CourierDashboardHeaderState();
}

class _CourierDashboardHeaderState extends State<CourierDashboardHeader> {
  bool _changing = false;
  Future<void> _toggle() async {
    if (_changing || widget.onChanged == null) return;
    setState(() => _changing = true);
    try { await widget.onChanged!(!widget.online); }
    catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: PrimeText(PrimeMessages.friendly(error))));
    } finally { if (mounted) setState(() => _changing = false); }
  }

  @override Widget build(BuildContext context) {
    final names = widget.name.trim().split(RegExp(r'\s+'));
    final name = names.first.isEmpty ? 'Motoboy' : names.first;
    return SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: _CourierBrand()),
          const SizedBox(width: 12),
          Badge(isLabelVisible: widget.unreadCount > 0,
            label: Text(widget.unreadCount > 9 ? '9+' : widget.unreadCount.toString()),
            child: IconButton.filledTonal(onPressed: widget.onNotifications,
              tooltip: translateLabel('Atualizações'),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFFEDF3F5),
                foregroundColor: courierGreen, minimumSize: const Size(44, 44)),
              icon: const Icon(AppIcons.bell, size: 23))),
          const SizedBox(width: 12),
          PopupMenuButton<String>(tooltip: translateLabel('Minha conta'),
            enabled: widget.onLogout != null,
            onSelected: (value) {
              if (value == 'profile') { widget.onProfile(); }
              if (value == 'logout') { widget.onLogout?.call(); }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'profile', child: Row(children: [
                const Icon(AppIcons.user, size: 19), const SizedBox(width: 10),
                Flexible(child: PrimeText('Meu perfil'))])),
              PopupMenuItem(value: 'logout', child: Row(children: [
                const Icon(AppIcons.logout, size: 19), const SizedBox(width: 10),
                Flexible(child: PrimeText('Sair da conta'))])),
            ],
            child: SizedBox(width: 46, height: 46, child: Stack(children: [
              CourierPortrait(photo: widget.photo, size: 46),
              Positioned(right: 0, bottom: 0, child: Container(width: 14, height: 14,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: widget.online ? const Color(0xFF159447) : const Color(0xFF83939B),
                  border: Border.all(color: Colors.white, width: 2.5)))),
            ]))),
        ]),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, box) {
          final stacked = box.maxWidth < 330 || MediaQuery.textScalerOf(context).scale(14) > 19;
          final greeting = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PrimeText('Olá,', style: TextStyle(fontSize: 14, height: 1.3,
              color: Color(0xFF56707D))),
            const SizedBox(height: 3),
            Text('$name 👋', style: const TextStyle(fontSize: 31, height: 1.2,
              fontWeight: FontWeight.w800, letterSpacing: -.9, color: courierInk)),
            const SizedBox(height: 7),
            PrimeText(widget.active ? 'Boa entrega!' : 'Pronto para mais entregas?',
              style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF56707D))),
          ]);
          final control = CourierReferenceAvailability(
            online: widget.online, active: widget.active, changing: _changing,
            onTap: widget.active ? widget.onRoute : widget.onChanged == null ? null : _toggle);
          if (stacked) return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [greeting, const SizedBox(height: 15), control]);
          return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: greeting), const SizedBox(width: 16),
            SizedBox(width: 150, child: control),
          ]);
        }),
      ])));
  }
}

class CourierReferenceAvailability extends StatelessWidget {
  const CourierReferenceAvailability({super.key, required this.online,
    required this.active, required this.changing, required this.onTap});
  final bool online, active, changing;
  final VoidCallback? onTap;
  @override Widget build(BuildContext context) {
    final enabled = !changing && onTap != null;
    final action = active ? 'Ver detalhes da rota' : online ? 'Ficar offline' : 'Ficar online';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(button: true, enabled: enabled, toggled: active ? null : online,
        label: translateLabel(action),
        child: ExcludeSemantics(child: Material(color: Colors.transparent,
          child: InkWell(onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(40),
            child: AnimatedContainer(
              duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 180),
              padding: const EdgeInsets.fromLTRB(16, 7, 7, 7),
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(colors: online
                  ? const [Color(0xFF075D61), Color(0xFF087D79)]
                  : const [Color(0xFF59717C), Color(0xFF738991)]),
                boxShadow: const [BoxShadow(color: Color(0x14075D61), blurRadius: 12, offset: Offset(0, 4))]),
              child: Row(children: [
                Expanded(child: PrimeText(active ? 'EM ENTREGA' : online ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(color: Colors.white, fontSize: 14,
                    height: 1.2, fontWeight: FontWeight.w800, letterSpacing: .5))),
                const SizedBox(width: 8),
                Container(width: 38, height: 38,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: changing ? const Padding(padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: courierGreen))
                    : active ? const Icon(AppIcons.route, color: courierGreen, size: 20)
                    : online ? null : const Icon(AppIcons.power, color: Color(0xFF59717C), size: 19)),
              ])))))),
      const SizedBox(height: 7),
      PrimeText(active ? 'Ver detalhes da rota' : online
        ? 'Você está recebendo entregas' : 'Toque para ficar online',
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, height: 1.4,
          color: Color(0xFF456E73))),
    ]);
  }
}

class _CourierBrand extends StatelessWidget {
  const _CourierBrand();
  @override Widget build(BuildContext context) => Row(children: [
    const SizedBox(width: 33, height: 36, child: CustomPaint(painter: _CrownPainter())),
    const SizedBox(width: 8),
    const Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'PORTO ', style: TextStyle(color: courierGreen)),
          TextSpan(text: 'PRIME', style: TextStyle(color: Color(0xFFDDA839))),
        ]), style: TextStyle(fontSize: 17, height: 1.2, fontWeight: FontWeight.w800)),
        SizedBox(height: 3),
        Text('D E L I V E R Y', style: TextStyle(fontSize: 7,
          letterSpacing: 1.5, fontWeight: FontWeight.w600, color: courierGreen)),
      ]))),
  ]);
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();
  @override void paint(Canvas canvas, Size size) {
    canvas.save(); canvas.scale(size.width / 30, size.height / 32);
    final crown = Path()..moveTo(2, 10)..lineTo(8, 15)..lineTo(15, 2)
      ..lineTo(22, 15)..lineTo(28, 10)..lineTo(25, 24)..lineTo(5, 24)..close();
    canvas.drawPath(crown, Paint()..shader = const LinearGradient(
      colors: [Color(0xFFFFDA75), Color(0xFFD99622)])
      .createShader(const Rect.fromLTWH(0, 0, 30, 28)));
    canvas.drawPath(Path()..moveTo(8, 15)..lineTo(15, 2)..lineTo(15, 24)..lineTo(5, 24)..close(),
      Paint()..color = const Color(0xFFFFE5A2).withValues(alpha: .35));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 26, 20, 3),
      const Radius.circular(1.5)), Paint()..color = const Color(0xFFE5AC37));
    canvas.restore();
  }
  @override bool shouldRepaint(covariant _CrownPainter oldDelegate) => false;
}
