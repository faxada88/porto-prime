import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'prime_brand.dart';

/// Account presentation only. Authentication and routing stay with ProfilePage.
class PrimeAccountWelcome extends StatelessWidget {
  const PrimeAccountWelcome({super.key, required this.onLogin, required this.onCreate});
  final VoidCallback onLogin, onCreate;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surface,
      borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.stroke),
      boxShadow: AppShadows.soft),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ColoredBox(color: AppColors.ocean900, child: Stack(children: [
        const Positioned.fill(child: ExcludeSemantics(child: IgnorePointer(
          child: CustomPaint(painter: _AccountArtwork())))),
        Padding(padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [PrimeBrandMark(size: 38), SizedBox(width: 12),
              Expanded(child: Text('SUA CONEXÃO COM PORTO',
                style: TextStyle(color: AppColors.ocean300, fontSize: 10,
                  height: 1.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)))]),
            const SizedBox(height: 26),
            const Text('Tudo seu,\nem um só lugar.', style: TextStyle(
              fontSize: 32, height: 1.12, letterSpacing: -1,
              color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            const Text('Seus pedidos, seus endereços e sua conta.\nSempre perto de você.',
              style: TextStyle(color: AppColors.ocean100, fontSize: 13, height: 1.6)),
          ])),
      ])),
      Padding(padding: const EdgeInsets.all(22), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FilledButton(onPressed: onLogin,
            style: FilledButton.styleFrom(backgroundColor: AppColors.sun500,
              foregroundColor: AppColors.ocean900,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(AppIcons.user, size: 19), SizedBox(width: 11),
              Flexible(child: Text('Entrar na minha conta', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
              SizedBox(width: 11), Icon(AppIcons.arrowRight, size: 18),
            ])),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onCreate,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.ocean900,
              side: const BorderSide(color: AppColors.strokeStrong),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: const Text('Criar minha conta', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
          const SizedBox(height: 17),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(AppIcons.lock, size: 14, color: AppColors.ocean700), SizedBox(width: 8),
            Flexible(child: Text('Seu acesso seguro à Porto Prime', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, height: 1.5, color: AppColors.muted))),
          ]),
        ])),
    ]),
  );
}

class PrimeAccountActionTile extends StatelessWidget {
  const PrimeAccountActionTile({super.key, required this.icon, required this.title,
    required this.subtitle, required this.onTap, this.highlighted = false});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Material(
    color: highlighted ? AppColors.sand50 : Colors.transparent,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(17),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(color: highlighted ? AppColors.sun200 : AppColors.ocean50,
            borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: AppColors.ocean900, size: 21)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, height: 1.3,
            fontWeight: FontWeight.w800, letterSpacing: -.2, color: AppColors.ocean900)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted)),
        ])),
        const SizedBox(width: 10),
        const Padding(padding: EdgeInsets.only(top: 12),
          child: Icon(AppIcons.chevronRight, size: 17, color: AppColors.ocean700)),
      ]))),
  );
}

class PrimeAccountIdentity extends StatelessWidget {
  const PrimeAccountIdentity({super.key, required this.name, required this.email,
    required this.roleLabel});
  final String name, email, roleLabel;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.ocean900,
      borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.soft),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 14, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(width: 58, height: 58, alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.sun500,
              borderRadius: BorderRadius.circular(20)),
            child: Padding(padding: const EdgeInsets.all(8), child: FittedBox(fit: BoxFit.scaleDown,
              child: Text(name.isEmpty ? 'P' : name.substring(0,1).toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ocean900))))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: AppColors.ocean800, borderRadius: BorderRadius.circular(30)),
            child: Text(roleLabel, style: const TextStyle(color: AppColors.ocean100,
              fontSize: 10, height: 1.4, fontWeight: FontWeight.w800, letterSpacing: 1))),
        ]),
      const SizedBox(height: 22),
      Text(name, style: const TextStyle(fontSize: 25, height: 1.2,
        fontWeight: FontWeight.w800, letterSpacing: -.6, color: Colors.white)),
      const SizedBox(height: 7),
      Text(email, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.ocean100)),
      const SizedBox(height: 20),
      const Divider(color: AppColors.ocean800, height: 1),
      const SizedBox(height: 14),
      const Text('Sua conta Porto Prime', style: TextStyle(fontSize: 11,
        height: 1.5, color: AppColors.ocean300, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _AccountArtwork extends CustomPainter {
  const _AccountArtwork();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width - 135, 34);
    final wash=Paint()..color=AppColors.ocean500.withValues(alpha:.09);
    canvas.drawCircle(const Offset(95,70),92,wash);
    final line=Paint()..color=AppColors.ocean300.withValues(alpha:.10)
      ..style=PaintingStyle.stroke..strokeWidth=1.4;
    canvas.drawCircle(const Offset(95,70),70,line);
    canvas.drawCircle(const Offset(95,70),103,line);
    canvas.drawCircle(const Offset(83,51),18,line);
    canvas.drawPath(Path()..moveTo(48,107)..cubicTo(48,62,118,62,118,107),line);
    canvas.drawCircle(const Offset(30,32),6,Paint()..color=AppColors.sun500.withValues(alpha:.16));
    canvas.drawCircle(const Offset(110,140),9,Paint()..color=AppColors.ocean300.withValues(alpha:.10));
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _AccountArtwork old) => false;
}
