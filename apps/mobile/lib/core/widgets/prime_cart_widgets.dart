import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Cart presentation; totals, availability and actions are supplied by CartPage.
class PrimeCartEmpty extends StatelessWidget {
  const PrimeCartEmpty({super.key, required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 480),
    child: Container(width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(color: AppColors.surface,
        borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.stroke)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ExcludeSemantics(child: SizedBox(width: 190, height: 164,
          child: CustomPaint(painter: _EmptyCartArtwork()))),
        const SizedBox(height: 20),
        const Text('Seu carrinho está vazio', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, height: 1.15, letterSpacing: -.8,
            fontWeight: FontWeight.w800, color: AppColors.ocean900)),
        const SizedBox(height: 12),
        const Text('O próximo momento bom começa com a sua escolha.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14,
            height: 1.6, color: AppColors.muted)),
        const SizedBox(height: 26),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: onExplore,
          style: FilledButton.styleFrom(backgroundColor: AppColors.ocean900,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: Text('Explorar produtos', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white))),
            SizedBox(width: 12), Icon(AppIcons.arrowRight, size: 20, color: AppColors.sun500),
          ]))),
        const SizedBox(height: 20),
        const Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 8, children: [
          _CartNote(icon: AppIcons.cart, label: 'Escolha seus favoritos'),
          _CartNote(icon: AppIcons.shield, label: 'Pagamento seguro'),
        ]),
      ]),
    ),
  ));
}

class PrimeCartSummary extends StatelessWidget {
  const PrimeCartSummary({super.key, required this.subtotal, required this.working,
    required this.storeKnown, required this.storeOpen, required this.storeMessage,
    required this.onContinue});
  final String subtotal, storeMessage;
  final bool working, storeKnown, storeOpen;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(2, 14, 2, 4),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.stroke))),
    child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (storeKnown && !storeOpen) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(storeMessage, style: const TextStyle(
            fontSize: 12, height: 1.5, color: AppColors.coral600))),
        Semantics(value: 'Subtotal dos produtos: $subtotal',
          child: FilledButton(
            onPressed: working || !storeKnown || !storeOpen ? null : onContinue,
            style: FilledButton.styleFrom(backgroundColor: AppColors.ocean900,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(child: Text(working ? 'Preparando…' : !storeKnown ? 'Verificando loja…'
                : storeOpen ? 'Continuar para entrega' : 'Loja fechada',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
              const SizedBox(width: 12),
              if (working) const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              else const Icon(AppIcons.arrowRight, size: 20),
            ]))),
        const SizedBox(height: 10),
        const Text('Frete e total no próximo passo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.muted)),
      ]),
  );
}

class _CartNote extends StatelessWidget {
  const _CartNote({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: AppColors.ocean700), const SizedBox(width: 7),
    Flexible(child: Text(label, style: const TextStyle(fontSize: 10,
      height: 1.4, color: AppColors.muted))),
  ]);
}

class _EmptyCartArtwork extends CustomPainter {
  const _EmptyCartArtwork();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save(); canvas.scale(size.width / 190, size.height / 164);
    canvas.drawCircle(const Offset(95,78),72,Paint()..color=AppColors.ocean50);
    canvas.drawCircle(const Offset(144,30),19,Paint()..color=AppColors.sun200);
    canvas.drawOval(const Rect.fromLTWH(48,139,102,9),Paint()..color=AppColors.ocean100);
    final line = Paint()..color=AppColors.ocean900..style=PaintingStyle.stroke
      ..strokeWidth=3..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
    final basket=Path()..moveTo(49,59)..lineTo(153,59)..lineTo(140,105)
      ..quadraticBezierTo(139,110,133,110)..lineTo(65,110)..close();
    canvas.drawPath(basket,Paint()..color=AppColors.ocean100);canvas.drawPath(basket,line);
    canvas.drawPath(Path()..moveTo(34,43)..lineTo(44,43)..quadraticBezierTo(48,43,49,49)
      ..lineTo(65,119)..lineTo(137,119),line);
    for(final x in [75.0,128.0]) {
      canvas.drawCircle(Offset(x,132),6,Paint()..color=AppColors.ocean900);
      canvas.drawCircle(Offset(x,132),2,Paint()..color=AppColors.sun500);
    }
    canvas.drawLine(const Offset(78,72),const Offset(83,96),line);
    canvas.drawLine(const Offset(103,72),const Offset(103,96),line);
    canvas.drawLine(const Offset(128,72),const Offset(123,96),line);
    canvas.drawCircle(const Offset(102,36),18,Paint()..color=AppColors.sun500);
    canvas.drawLine(const Offset(94,36),const Offset(110,36),line);
    canvas.drawLine(const Offset(102,28),const Offset(102,44),line);
    canvas.drawCircle(const Offset(37,96),3,Paint()..color=AppColors.ocean500);
    canvas.drawCircle(const Offset(165,110),4,Paint()..color=AppColors.sun500);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _EmptyCartArtwork old) => false;
}
