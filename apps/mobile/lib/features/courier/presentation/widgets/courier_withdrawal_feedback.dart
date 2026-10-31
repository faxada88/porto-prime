import 'package:flutter/material.dart';

/// Acknowledges a real server withdrawal response, not an assumed Pix payment.
bool courierWithdrawalAcknowledged(String status) =>
    const ['PENDING', 'PROCESSING', 'PAID'].contains(status);

/// Visual-only receipt dialog. The payout flow, status and amount are supplied
/// unchanged by the existing wallet API response.
class CourierWithdrawalFeedback extends StatelessWidget {
  const CourierWithdrawalFeedback({
    super.key, required this.status, required this.amount,
  });

  final String status;
  final double? amount;

  static const ink = Color(0xFF092B44);
  static const muted = Color(0xFF627D90);
  static const teal = Color(0xFF00687B);
  static const sea = Color(0xFF00A99B);

  String money(double value) =>
      'R$ ' + value.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final paid = status == 'PAID';
    final processing = status == 'PROCESSING';
    final acknowledged = courierWithdrawalAcknowledged(status);
    final heading = paid
        ? 'Seu saque foi concluído!'
        : processing
          ? 'Seu saque está em processamento'
          : acknowledged ? 'Seu saque foi solicitado'
            : 'Confira seu saque';
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      insetPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: screen.height * .94),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              const _CoastalHeader(),
              Positioned(left: 0, right: 0, top: 100,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: .88, end: 1),
                    duration: reduceMotion ? Duration.zero :
                      const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                    child: _StatusEmblem(paid: paid),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 81),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(heading, textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Manrope', fontWeight: FontWeight.w800,
                  fontSize: 25, height: 1.22, letterSpacing: -.75, color: ink,
                ),
              ),
            ),
            if (amount != null && amount!.isFinite && amount! > 0) ...[
              const SizedBox(height: 18),
              Container(
                constraints: const BoxConstraints(minWidth: 200),
                padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [
                    Color(0xFFE3FAF2), Color(0xFFD6F6ED)]),
                ),
                child: Text(money(amount!), textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Manrope',
                    fontSize: 30, fontWeight: FontWeight.w800,
                    letterSpacing: -.8, color: Color(0xFF00675E))),
              ),
            ],
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFF2F7FA),
                  border: Border.all(color: const Color(0xFFEAF0F5)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, color: ink, size: 20),
                  const SizedBox(width: 11),
                  const Expanded(child: Text('Previsão de conclusão',
                    style: TextStyle(fontFamily: 'Manrope', fontSize: 12,
                      fontWeight: FontWeight.w700, color: ink))),
                  Text(paid ? 'Concluída' : 'A confirmar',
                    style: const TextStyle(fontFamily: 'Manrope',
                      fontSize: 12, fontWeight: FontWeight.w800, color: ink)),
                ]),
              ),
            ),
            const SizedBox(height: 23),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(children: [
                _StatusStep(
                  state: 2,
                  label: 'Solicitação recebida',
                  detail: 'Seu pedido de saque foi registrado.',
                  showConnector: true,
                ),
                _StatusStep(
                  state: paid ? 2 : processing ? 1 : 0,
                  label: 'Repasse em processamento',
                  detail: paid ? 'O processamento foi concluído.' :
                    processing ? 'Aguardando confirmação da transferência.' :
                      'Seu saque aguarda processamento.',
                  showConnector: true,
                ),
                _StatusStep(
                  state: paid ? 2 : 0,
                  label: 'Transferência concluída',
                  detail: paid ? 'O valor foi enviado à sua chave Pix.' :
                    'Aguardando confirmação do pagamento.',
                  showConnector: false,
                ),
              ]),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                padding: const EdgeInsets.fromLTRB(17, 17, 14, 17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEEFCFA), Color(0xFFD9F7F4)]),
                  border: Border.all(color: const Color(0xFFCFF0E8)),
                ),
                child: Row(children: [
                  Container(width: 52, height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.trending_up_rounded,
                      color: Color(0xFF40BF63), size: 29)),
                  const SizedBox(width: 13),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continue entregando!',
                        style: TextStyle(fontFamily: 'Manrope', fontSize: 15,
                          fontWeight: FontWeight.w800, color: ink)),
                      SizedBox(height: 4),
                      Text('Seus ganhos continuam acumulando enquanto o saque é processado.',
                        style: TextStyle(fontFamily: 'Manrope',
                          fontSize: 11, color: muted, height: 1.5)),
                    ],
                  )),
                  const SizedBox(width: 5),
                  Icon(Icons.delivery_dining_rounded,
                    size: 42, color: sea.withValues(alpha: .29)),
                ]),
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: SizedBox(height: 55, width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: teal, foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.delivery_dining_rounded, size: 22),
                    SizedBox(width: 11),
                    Text('Continuar ganhando',
                      style: TextStyle(fontFamily: 'Manrope',
                        fontSize: 15, fontWeight: FontWeight.w800)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26),
              child: Text('Você pode acompanhar seu saque pela carteira.',
                textAlign: TextAlign.center, style: TextStyle(
                  fontFamily: 'Manrope', fontSize: 10,
                  color: muted, height: 1.45)),
            ),
            const SizedBox(height: 18),
          ]),
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.state,
    required this.label,
    required this.detail,
    required this.showConnector,
  });
  final int state; // 0 = future, 1 = underway, 2 = complete.
  final String label, detail;
  final bool showConnector;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 35,
        child: Column(children: [
          Container(width: 31, height: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state == 2 ? const Color(0xFF50C64A) :
                state == 1 ? const Color(0xFF00AFA1) : const Color(0xFFF7FCFB),
              border: Border.all(
                color: state == 2 ? const Color(0xFF50C64A) :
                  const Color(0xFFBEE6DE), width: state == 1 ? 3 : 2),
            ),
            child: state == 2
              ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
              : state == 1
                ? const Icon(Icons.circle, size: 13, color: Colors.white)
                : null,
          ),
          if (showConnector) Expanded(child: Container(
            width: 2.5, constraints: const BoxConstraints(minHeight: 30),
            color: const Color(0xFFD7F1E9))),
        ]),
      ),
      const SizedBox(width: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 19),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Manrope',
              fontSize: 13, fontWeight: FontWeight.w800,
              color: CourierWithdrawalFeedback.ink)),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(fontFamily: 'Manrope',
              fontSize: 11, height: 1.48,
              color: CourierWithdrawalFeedback.muted)),
          ]),
      )),
    ]),
  );
}

class _StatusEmblem extends StatelessWidget {
  const _StatusEmblem({required this.paid});
  final bool paid;
  @override
  Widget build(BuildContext context) => SizedBox(width: 118, height: 118,
    child: Stack(alignment: Alignment.center, children: [
      Container(width: 118, height: 118,
        decoration: const BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            Color(0xFFE1FFF4), Color(0xFF9FE4D9)]))),
      SizedBox(width: 112, height: 112,
        child: CircularProgressIndicator(
          value: paid ? 1 : .72, strokeWidth: 3.4,
          color: const Color(0xFF00B7BD),
          backgroundColor: const Color(0x90FFFFFF))),
      Container(width: 91, height: 91,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: paid ? const Color(0xFF00A17E) : const Color(0xFF009B8E),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x27006479), blurRadius: 19, offset: Offset(0, 5)),
          ],
        ),
        child: Icon(paid ? Icons.check_rounded : Icons.hourglass_top_rounded,
          color: Colors.white, size: 45)),
    ]),
  );
}

class _CoastalHeader extends StatelessWidget {
  const _CoastalHeader();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 156,
    width: double.infinity,
    child: Stack(fit: StackFit.expand, children: [
      Image.asset('assets/reference_home/coast-banner.webp',
        fit: BoxFit.cover, alignment: Alignment.centerRight,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(gradient: LinearGradient(
            colors: [Color(0xFFEDFBFC), Color(0xFF48C1E7)])))),
      const DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xEFFFFFFF), Color(0x6DEAFBFB), Color(0x00FFFFFF)],
          stops: [.0, .44, 1],
        ),
      )),
      const Positioned(top: 24, left: 24, child: _HeaderBrand()),
      const Positioned(bottom: 0, left: 0, right: 0,
        child: SizedBox(height: 36,
          child: CustomPaint(painter: _CoastalWavePainter()))),
    ]),
  );
}

class _HeaderBrand extends StatelessWidget {
  const _HeaderBrand();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: const [
      SizedBox(width: 38, height: 38,
        child: CustomPaint(painter: _LogoPainter())),
      SizedBox(width: 7),
      Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Porto Prime', style: TextStyle(fontFamily: 'Manrope',
            fontSize: 17, fontWeight: FontWeight.w800,
            color: CourierWithdrawalFeedback.ink, letterSpacing: -.8)),
          Text('D E L I V E R Y', style: TextStyle(fontFamily: 'Manrope',
            fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF54758C))),
        ]),
    ],
  );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawCircle(Offset(w * .46, h * .46), w * .40,
      Paint()..color = const Color(0xFFFFCE59));
    canvas.drawCircle(Offset(w * .46, h * .46), w * .23,
      Paint()..color = Colors.white);
    final wave = Path()..moveTo(0, h * .66)
      ..quadraticBezierTo(w * .43, h * .34, w, h * .55)
      ..lineTo(w, h * .76)
      ..quadraticBezierTo(w * .48, h * .6, w * .16, h)..close();
    canvas.drawPath(wave, Paint()..color = const Color(0xFF00ABD3));
    final deep = Path()..moveTo(w * .1, h * .85)
      ..quadraticBezierTo(w * .55, h * .59, w, h * .68)
      ..lineTo(w, h)..lineTo(w * .1, h)..close();
    canvas.drawPath(deep, Paint()..color = const Color(0xFF006B91));
  }
  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => false;
}

class _CoastalWavePainter extends CustomPainter {
  const _CoastalWavePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .48)
      ..quadraticBezierTo(size.width * .28, -size.height * .28,
        size.width * .54, size.height * .42)
      ..quadraticBezierTo(size.width * .8, size.height * 1.04,
        size.width, size.height * .1)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(covariant _CoastalWavePainter oldDelegate) => false;
}
