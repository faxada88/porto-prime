import 'package:flutter/material.dart';

/// Only visual presentation; the caller retains its existing Pix request,
/// validation, error handling and API response.
class CourierWithdrawalRequestPanel extends StatelessWidget {
  const CourierWithdrawalRequestPanel({
    super.key,
    required this.availableBalance,
    required this.amountController,
    required this.pixController,
    required this.pixType,
    required this.onPixTypeChanged,
    required this.loading,
    required this.error,
    required this.onCancel,
    required this.onSubmit,
  });

  final double availableBalance;
  final TextEditingController amountController, pixController;
  final String? pixType, error;
  final ValueChanged<String?> onPixTypeChanged;
  final bool loading;
  final VoidCallback onCancel;
  final Future<void> Function() onSubmit;

  static const ink = Color(0xFF092B44);
  static const muted = Color(0xFF607A8E);
  static const teal = Color(0xFF006B7C);
  static const line = Color(0xFFD7E7F1);
  String money(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $whole,${parts[1]}';
  }

  void choose(double value) {
    if (loading || value <= 0) return;
    amountController.text = value.toStringAsFixed(2).replaceAll('.', ',');
    amountController.selection =
        TextSelection.collapsed(offset: amountController.text.length);
  }

  InputDecoration field(String hint, IconData icon, {String? prefix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF7A91A4), fontSize: 15),
        filled: true, fillColor: const Color(0xFFF7FBFD),
        prefixText: prefix,
        prefixStyle: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 16),
        prefixIcon: Icon(icon, size: 21, color: ink),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: line, width: 1.3)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: line, width: 1.3)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF0EA9B5), width: 1.8)),
      );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final narrow = screen.width < 375;
    final padding = narrow ? 18.0 : 25.0;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      elevation: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: screen.height * .93),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 22, padding, 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 48, height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: const Color(0xFFD7E5EE),
                  borderRadius: BorderRadius.circular(9)))),
              Row(children: [
                const _PrimeBrand(),
                const Spacer(),
                IconButton(onPressed: loading ? null : onCancel,
                  tooltip: 'Fechar', icon: const Icon(Icons.close_rounded,
                  color: ink, size: 26)),
              ]),
              const SizedBox(height: 22),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solicitar saque', style: TextStyle(fontFamily: 'Manrope',
                      fontSize: 27, fontWeight: FontWeight.w800, color: ink,
                      height: 1.18, letterSpacing: -1)),
                    SizedBox(height: 10),
                    Text('Transfira seus ganhos para sua conta via Pix.',
                      style: TextStyle(fontFamily: 'Manrope', fontSize: 13,
                        height: 1.5, color: muted, fontWeight: FontWeight.w500)),
                  ],
                )),
                const SizedBox(width: 5),
                SizedBox(width: narrow ? 82 : 128, height: narrow ? 96 : 116,
                  child: const CustomPaint(painter: _WalletPainter())),
              ]),
              const SizedBox(height: 17),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE9FBFA), Color(0xFFD8F3EF)]),
                  border: Border.all(color: const Color(0xFFCDEEE8)),
                ),
                child: Row(children: [
                  Container(width: 51, height: 51,
                    decoration: BoxDecoration(color: const Color(0xFF00A88D),
                      borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                      size: 27, color: Colors.white)),
                  const SizedBox(width: 15),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo disponível', style: TextStyle(
                        fontFamily: 'Manrope', fontSize: 13,
                        fontWeight: FontWeight.w600, color: Color(0xFF395968))),
                      FittedBox(fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(money(availableBalance), style: const TextStyle(
                          fontFamily: 'Manrope', fontSize: 26, letterSpacing: -.8,
                          fontWeight: FontWeight.w800, color: Color(0xFF006D61)))),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 22),
              const _FieldLabel('Valor do saque'),
              const SizedBox(height: 8),
              TextField(controller: amountController,
                enabled: !loading, autofocus: false,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                scrollPadding: const EdgeInsets.all(90),
                style: const TextStyle(fontFamily: 'Manrope', color: ink,
                  fontSize: 17, fontWeight: FontWeight.w700),
                decoration: field('0,00', Icons.account_balance_wallet_outlined,
                  prefix: 'R$ ')),
              const SizedBox(height: 11),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: amountController,
                builder: (_, value, __) {
                  final options = <(String, double)>[
                    ('R$ 50,00', 50), ('R$ 100,00', 100),
                    ('R$ 200,00', 200), ('Máximo', availableBalance),
                  ];
                  return Row(children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(child: Builder(builder: (_) {
                        final amount = options[i].$2;
                        final selected = amount > 0 &&
                          double.tryParse(value.text.replaceAll(',', '.')) == amount;
                        final enabled = !loading && amount > 0 &&
                          amount <= availableBalance;
                        return Material(
                          color: selected ? const Color(0xFF07AFB9) :
                            const Color(0xFFE7F6FC),
                          borderRadius: BorderRadius.circular(15),
                          child: InkWell(
                            onTap: enabled ? () => choose(amount) : null,
                            borderRadius: BorderRadius.circular(15),
                            child: SizedBox(height: 41,
                              child: Center(child: FittedBox(fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(options[i].$1, style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: narrow ? 10 : 11,
                                    fontWeight: FontWeight.w800,
                                    color: selected ? Colors.white : ink)),
                                )))),
                          ),
                        );
                      })),
                    ],
                  ]);
                },
              ),
              const SizedBox(height: 21),
              const _FieldLabel('Tipo de chave Pix'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: pixType,
                style: const TextStyle(fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700, fontSize: 15, color: ink),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: ink),
                decoration: field('Selecione o tipo de chave', Icons.key_rounded),
                items: const [
                  DropdownMenuItem(value: 'CPF', child: Text('CPF')),
                  DropdownMenuItem(value: 'CNPJ', child: Text('CNPJ')),
                  DropdownMenuItem(value: 'EMAIL', child: Text('E-mail')),
                  DropdownMenuItem(value: 'PHONE', child: Text('Celular')),
                  DropdownMenuItem(value: 'RANDOM', child: Text('Aleatória')),
                ],
                onChanged: loading ? null : onPixTypeChanged,
              ),
              const SizedBox(height: 21),
              const _FieldLabel('Chave Pix de recebimento'),
              const SizedBox(height: 8),
              TextField(controller: pixController, enabled: !loading,
                scrollPadding: const EdgeInsets.all(90),
                style: const TextStyle(fontFamily: 'Manrope', fontSize: 15,
                  fontWeight: FontWeight.w600, color: ink),
                decoration: field('Digite sua chave Pix',
                  Icons.person_outline_rounded)),
              const SizedBox(height: 22),
              Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  gradient: const LinearGradient(colors: [
                    Color(0xFFF0FAFE), Color(0xFFE5F7FC)])),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_rounded,
                      color: Color(0xFF00A58D), size: 29),
                    SizedBox(width: 13),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Confira os dados com atenção', style: TextStyle(
                          fontFamily: 'Manrope', fontSize: 13,
                          fontWeight: FontWeight.w800, color: ink)),
                        SizedBox(height: 5),
                        Text('O valor será transferido via Pix para a chave informada.',
                          style: TextStyle(fontFamily: 'Manrope', fontSize: 11,
                            color: muted, height: 1.5)),
                      ],
                    )),
                  ],
                )),
              if (error != null && error!.isNotEmpty) ...[
                const SizedBox(height: 13),
                Container(padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EF),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFF5D5CF))),
                  child: Text(error!, style: const TextStyle(
                    color: Color(0xFFAD4239), fontSize: 12, height: 1.5,
                    fontWeight: FontWeight.w600))),
              ],
              const SizedBox(height: 22),
              ConstrainedBox(constraints: const BoxConstraints(minHeight: 57),
                child: FilledButton.icon(
                  onPressed: loading ? null : () => onSubmit(),
                  style: FilledButton.styleFrom(
                    backgroundColor: teal, foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF84B5BA),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19))),
                  icon: loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 21),
                  label: Text(loading ? 'Enviando solicitação...' : 'Solicitar saque',
                    style: const TextStyle(fontFamily: 'Manrope',
                      fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
    style: const TextStyle(fontFamily: 'Manrope', fontSize: 13,
      fontWeight: FontWeight.w800,
      color: CourierWithdrawalRequestPanel.ink));
}

class _PrimeBrand extends StatelessWidget {
  const _PrimeBrand();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(width: 39, height: 39,
        child: CustomPaint(painter: _PrimeMark())),
      const SizedBox(width: 7),
      const Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Porto Prime', style: TextStyle(fontFamily: 'Manrope',
            fontWeight: FontWeight.w800, color: Color(0xFF092B44),
            fontSize: 17, letterSpacing: -.7)),
          Text('D E L I V E R Y', style: TextStyle(fontFamily: 'Manrope',
            fontSize: 8, fontWeight: FontWeight.w800,
            color: Color(0xFF55788A))),
        ]),
    ]);
}

class _PrimeMark extends CustomPainter {
  const _PrimeMark();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawCircle(Offset(w * .47, h * .46), w * .40,
      Paint()..color = const Color(0xFFFFCF5A));
    canvas.drawCircle(Offset(w * .47, h * .46), w * .23,
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
  bool shouldRepaint(covariant _PrimeMark oldDelegate) => false;
}

class _WalletPainter extends CustomPainter {
  const _WalletPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 150, size.height / 120);
    canvas.drawOval(const Rect.fromLTWH(4, 18, 143, 91),
      Paint()..color = const Color(0xFFE4F8FE));
    canvas.drawOval(const Rect.fromLTWH(40, 102, 110, 11),
      Paint()..color = const Color(0x22005770)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    for (final coin in [
      (const Offset(53, 33), 17.0),
      (const Offset(86, 23), 21.0),
      (const Offset(110, 42), 18.0),
    ]) {
      canvas.drawCircle(coin.$1, coin.$2,
        Paint()..color = const Color(0xFFF0AE38));
      canvas.drawCircle(coin.$1, coin.$2 - 3,
        Paint()..color = const Color(0xFFFFD879));
      canvas.drawCircle(coin.$1, coin.$2 - 5,
        Paint()..color = const Color(0xFFFFECAA)
          ..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(27, 49, 110, 60), const Radius.circular(14)),
      Paint()..shader = const LinearGradient(colors: [
        Color(0xFF0B5D88), Color(0xFF082C58)])
        .createShader(const Rect.fromLTWH(27, 49, 110, 60)));
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(87, 68, 59, 26), const Radius.circular(7)),
      Paint()..color = const Color(0xFF134C73));
    canvas.drawCircle(const Offset(112, 81), 4,
      Paint()..color = const Color(0xFF90DFF2));
    final pix = Path()..moveTo(62, 64)..lineTo(75, 77)
      ..lineTo(62, 90)..lineTo(49, 77)..close();
    canvas.drawPath(pix, Paint()..color = Colors.white);
    canvas.drawLine(const Offset(52, 77), const Offset(72, 77),
      Paint()..color = const Color(0xFF0A5C85)..strokeWidth = 2);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _WalletPainter oldDelegate) => false;
}
