import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/localization/prime_localization.dart';
import 'courier_dashboard_map.dart' show courierGreen, courierInk;

/// Confirms the server response, never a local assumption that a Pix was paid.
bool courierWithdrawalAcknowledged(String status) =>
    const ['PENDING', 'PROCESSING', 'PAID'].contains(status);

class CourierWithdrawalFeedback extends StatefulWidget {
  const CourierWithdrawalFeedback({super.key, required this.status, required this.amount});
  final String status;
  final double? amount;
  @override State<CourierWithdrawalFeedback> createState() => _CourierWithdrawalFeedbackState();
}

class _CourierWithdrawalFeedbackState extends State<CourierWithdrawalFeedback>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _celebration = AnimationController(vsync: this,
    duration: const Duration(milliseconds: 2800));
  bool _foreground = true, _reduceMotion = false, _tickerEnabled = true;
  @override void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }
  void _sync() {
    if (_reduceMotion || !courierWithdrawalAcknowledged(widget.status)) {
      _celebration.stop();
      _celebration.value = 1;
    } else if (_foreground && _tickerEnabled && _celebration.value < 1) {
      _celebration.forward();
    } else {
      _celebration.stop();
    }
  }
  @override void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.of(context);
    _sync();
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _celebration.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final acknowledged = courierWithdrawalAcknowledged(widget.status);
    final title = switch (widget.status) {
      'PENDING' => 'Boa! Saque solicitado',
      'PROCESSING' => 'Seu saque está em processamento',
      'PAID' => 'Saque pago!',
      _ => 'Confira seu saque',
    };
    final label = switch (widget.status) {
      'PENDING' => 'Aguardando processamento',
      'PROCESSING' => 'Em processamento',
      'PAID' => 'Pagamento confirmado',
      _ => 'Consulte o status na carteira',
    };
    final amount = widget.amount;
    return Dialog(backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),
        side: const BorderSide(color: Color(0xFFD9ECE8))),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 400,
        maxHeight: MediaQuery.sizeOf(context).height * .85),
        child: Stack(children: [
          SingleChildScrollView(child: Padding(padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Center(child: AnimatedBuilder(animation: _celebration, builder: (context, child) {
                final entrance = (_celebration.value / .18).clamp(0.0, 1.0).toDouble();
                return Transform.scale(scale: .82 + .18 * Curves.easeOutBack.transform(entrance), child: child);
              }, child: Container(width: 108, height: 108,
                decoration: const BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0xFFD2F3E9), Color(0xFFF1FAF7)])),
                child: Center(child: Container(width: 72, height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: courierGreen,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [BoxShadow(color: Color(0x1A075A5E), blurRadius: 16, offset: Offset(0, 5))]),
                  child: Icon(acknowledged ? Icons.check_rounded : Icons.receipt_long_rounded,
                    size: 38, color: Colors.white)))))),
              const SizedBox(height: 22),
              Semantics(liveRegion: true, child: PrimeText(title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, height: 1.25, fontWeight: FontWeight.w800,
                  letterSpacing: -.5, color: courierInk))),
              if (amount != null && amount.isFinite && amount > 0) ...[
                const SizedBox(height: 18),
                Text('R\$ ' + amount.toStringAsFixed(2).replaceAll('.', ','), textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 34, height: 1.15, fontWeight: FontWeight.w800,
                    letterSpacing: -1, color: courierGreen)),
              ],
              const SizedBox(height: 14),
              Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEEF7F4),
                  borderRadius: BorderRadius.circular(14)),
                child: PrimeText(label, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w700,
                    color: courierGreen)))),
              const SizedBox(height: 16),
              const PrimeText('Acompanhe as atualizações na carteira.', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF56707D))),
              const SizedBox(height: 25),
              FilledButton(onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(backgroundColor: courierGreen, foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                child: const PrimeText('Voltar à carteira', textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800, height: 1.3))),
            ]))),
          Positioned.fill(child: ExcludeSemantics(child: IgnorePointer(child: RepaintBoundary(
            child: CustomPaint(painter: _WithdrawalConfetti(_celebration)))))),
        ])));
  }
}

/// One short burst; the painter never intercepts taps or schedules another burst.
class _WithdrawalConfetti extends CustomPainter {
  _WithdrawalConfetti(this.progress) : super(repaint: progress);
  final Animation<double> progress;
  static final _pieces = () {
    final random = math.Random(73);
    return List.generate(58, (_) => (angle: -math.pi + .18 + random.nextDouble() * (math.pi - .36),
      speed: .45 + random.nextDouble() * .45, delay: random.nextDouble() * .07,
      spin: random.nextDouble() * math.pi * 6, width: 3.0 + random.nextDouble() * 3.0,
      color: const [Color(0xFF087F78), Color(0xFF59C6AD), Color(0xFFE6B85C),
        Color(0xFF92D7E1), Color(0xFFC7E4DB)][random.nextInt(5)]));
  }();
  @override void paint(Canvas canvas, Size size) {
    if (progress.value >= 1 || progress.value == 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final piece in _pieces) {
      if (progress.value < piece.delay) continue;
      final t = (progress.value - piece.delay) / (1 - piece.delay);
      final x = size.width * .5 + math.cos(piece.angle) * size.width * piece.speed * t;
      final y = size.height * .23 + math.sin(piece.angle) * size.height * piece.speed * t
          + size.height * 1.05 * t * t;
      final fade = (1 - t) * .9;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * t);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero,
        width: piece.width, height: piece.width * (1.15 + .45 * math.sin(t * math.pi * 5).abs())),
        const Radius.circular(1)), Paint()..color = piece.color.withValues(alpha: fade));
      canvas.restore();
    }
    canvas.restore();
  }
  @override bool shouldRepaint(covariant _WithdrawalConfetti oldDelegate) => progress != oldDelegate.progress;
}
