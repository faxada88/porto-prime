import 'package:flutter/material.dart';
import '../localization/prime_localization.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'ice_product_option.dart';

Future<void> showIceSelector(BuildContext context, {required String categoryName,
 IceType? initialType, String? initialProductId}) => showModalBottomSheet<void>(
 context: context, isScrollControlled: true, useSafeArea: true,
 backgroundColor: Colors.transparent,
 builder: (_) => _IceSelector(categoryName: categoryName,
  initialType: initialType, initialProductId: initialProductId));

class IceSelectionBanner extends StatelessWidget {
 const IceSelectionBanner({super.key, required this.categoryName});
 final String categoryName;
 @override Widget build(BuildContext context) => Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
   gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFEDF9FF), Color(0xFFDFEEF2)]),
   borderRadius: BorderRadius.circular(24),
   border: Border.all(color: const Color(0xFFBDDDE8))),
  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
   Row(children: [
    const SizedBox(width: 52, height: 52, child: CustomPaint(painter: _IcePainter(crushed: false))),
    const SizedBox(width: 12),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
     PrimeText('Gelo na medida certa', style: TextStyle(fontSize: 21, height: 1.15,
      fontWeight: FontWeight.w800, color: Color(0xFF123F49))),
     SizedBox(height: 6),
     PrimeText('Escolha o tipo, o peso e pronto.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF527582))),
    ])),
   ]),
   const SizedBox(height: 18),
   Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: _IceTypeTile(type: IceType.cubes, selected: false,
     onTap: () => showIceSelector(context, categoryName: categoryName, initialType: IceType.cubes))),
    const SizedBox(width: 12),
    Expanded(child: _IceTypeTile(type: IceType.crushed, selected: false,
     onTap: () => showIceSelector(context, categoryName: categoryName, initialType: IceType.crushed))),
   ]),
   const SizedBox(height: 12),
   OutlinedButton.icon(onPressed: () => showIceSelector(context, categoryName: categoryName),
    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF123F49),
     side: const BorderSide(color: Color(0xFF95BFCC)), minimumSize: const Size(0, 48),
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    icon: const Icon(Icons.tune_rounded, size: 19),
    label: const PrimeText('Escolher meu gelo', style: TextStyle(fontWeight: FontWeight.w700))),
  ]));
}

class _IceSelector extends StatefulWidget {
 const _IceSelector({required this.categoryName, this.initialType, this.initialProductId});
 final String categoryName;
 final IceType? initialType;
 final String? initialProductId;
 @override State<_IceSelector> createState() => _IceSelectorState();
}

class _IceSelectorState extends State<_IceSelector> {
 IceType type = IceType.cubes;
 int kilograms = 3, quantity = 1;
 String? productId;
 List<IceProductOption> get options => iceOptionsFor(AppState.instance.products, widget.categoryName);
 @override void initState() {
  super.initState();
  final all = options;
  final requested = all.where((o) => o.id == widget.initialProductId).toList();
  final preferred = all.where((o) => (widget.initialType == null || o.type == widget.initialType)
   && AppState.instance.canIncreaseQuantity(o.id)).toList();
  final matchingType = all.where((o) => widget.initialType == null || o.type == widget.initialType).toList();
  final IceProductOption? first = requested.isNotEmpty ? requested.first
   : preferred.isNotEmpty ? preferred.first : matchingType.isNotEmpty ? matchingType.first : null;
  type = widget.initialType ?? first?.type ?? IceType.cubes;
  if (first != null && first.type == type) {
   kilograms = first.kilograms;
   productId = first.id;
  }
 }
 void chooseType(IceType value) {
  final matching = options.where((o) => o.type == value).toList();
  final available = matching.where((o) => AppState.instance.canIncreaseQuantity(o.id)).toList();
  final sameWeight = available.where((o) => o.kilograms == kilograms).toList();
  final next = sameWeight.isNotEmpty ? sameWeight.first : available.isNotEmpty
   ? available.first : matching.isNotEmpty ? matching.first : null;
  setState(() {
   type = value; kilograms = next?.kilograms ?? kilograms;
   productId = next?.id; quantity = 1;
  });
 }
 void add(IceProductOption option, int count) {
  final state = AppState.instance;
  var added = 0;
  while (added < count && state.canIncreaseQuantity(option.id)) {
   state.addProduct(option.id); added++;
  }
  if (added == 0) return;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  navigator.pop();
  messenger.showSnackBar(const SnackBar(content: PrimeText('Gelo adicionado ao carrinho'),
   duration: Duration(seconds: 2)));
 }
 @override Widget build(BuildContext context) => AnimatedBuilder(
  animation: Listenable.merge([AppState.instance, AppLanguage.instance]),
  builder: (context, _) {
   final state = AppState.instance;
   final all = options;
   final candidates = all.where((o) => o.type == type && o.kilograms == kilograms).toList();
   final chosen = candidates.where((o) => o.id == productId).toList();
   final available = candidates.where((o) => state.canIncreaseQuantity(o.id)).toList();
   final IceProductOption? selected = chosen.isNotEmpty ? chosen.first
    : available.isNotEmpty ? available.first : candidates.isNotEmpty ? candidates.first : null;
   final rawRemaining = selected == null ? 0 : state.stockLimit(selected.id) - (state.cart[selected.id] ?? 0);
   final remaining = rawRemaining < 0 ? 0 : rawRemaining;
   final count = remaining > 0 && quantity > remaining ? remaining : quantity;
   final canAdd = selected != null && state.canIncreaseQuantity(selected.id) && count <= remaining;
   final price = selected == null ? 0.0 : double.tryParse(selected.product['price'].toString()) ?? 0.0;
   final weights = <int>{3, 6, 15, 20, ...all.map((o) => o.kilograms)}.toList()..sort();
   final stickyFooter = MediaQuery.sizeOf(context).height >= 740
    && MediaQuery.textScalerOf(context).scale(14) <= 21;
   final footer = Container(padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
       decoration: const BoxDecoration(color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD7E5EA)))),
       child: SafeArea(top: false, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
         spacing: 16, runSpacing: 12, children: [
          Container(decoration: BoxDecoration(color: const Color(0xFFF0F7FA),
           borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFC9DCE3))),
           child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(tooltip: translateLabel('Diminuir quantidade'),
             onPressed: count > 1 ? () => setState(() => quantity = count - 1) : null,
             icon: const Icon(Icons.remove_rounded, size: 21)),
            SizedBox(width: 30, child: Text(count.toString(), textAlign: TextAlign.center,
             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF123F49)))),
            IconButton(tooltip: translateLabel('Aumentar quantidade'),
             onPressed: canAdd && count < remaining ? () => setState(() => quantity = count + 1) : null,
             icon: const Icon(Icons.add_rounded, size: 21)),
           ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
           const PrimeText('Subtotal', style: TextStyle(fontSize: 11, color: AppColors.muted)),
           Text(selected == null ? '—' : _money(price * count), style: const TextStyle(fontSize: 22,
            fontWeight: FontWeight.w800, color: Color(0xFF123F49))),
          ]),
         ]),
        const SizedBox(height: 14),
        FilledButton.icon(
         style: FilledButton.styleFrom(backgroundColor: const Color(0xFF123F49),
          foregroundColor: Colors.white, minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
         onPressed: canAdd && selected != null ? () => add(selected, count) : null,
         icon: const Icon(Icons.add_shopping_cart_rounded, size: 21),
         label: PrimeText(selected == null ? 'Escolha uma opção' : !state.storeOpen
          ? 'Loja fechada no momento' : !canAdd
          ? (state.stockLimit(selected.id) == 0 ? 'Indisponível' : 'Limite de estoque atingido') : 'Adicionar ao carrinho',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
       ])));
   return DraggableScrollableSheet(initialChildSize: .86, minChildSize: .55, maxChildSize: .96, expand: false,
    builder: (context, scroll) => Container(
     clipBehavior: Clip.antiAlias,
     decoration: const BoxDecoration(color: Color(0xFFF5FAFC),
      borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
     child: Column(children: [
      const SizedBox(height: 9),
      Container(width: 38, height: 4, decoration: BoxDecoration(
       color: const Color(0xFFB8CED7), borderRadius: BorderRadius.circular(4))),
      Padding(padding: const EdgeInsets.fromLTRB(22, 13, 12, 12), child: Row(children: [
       const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PrimeText('Seu gelo, do seu jeito', style: TextStyle(fontSize: 23, height: 1.15,
         fontWeight: FontWeight.w800, color: Color(0xFF123F49))),
        SizedBox(height: 6),
        PrimeText('Escolha uma opção para adicionar.', style: TextStyle(fontSize: 12,
         height: 1.4, color: Color(0xFF527582))),
       ])),
       IconButton(tooltip: translateLabel('Fechar'), onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded, color: Color(0xFF123F49))),
      ])),
      Expanded(child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(22, 6, 22, 22), children: [
       const _SectionLabel('Como você prefere?'),
       const SizedBox(height: 12),
       Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final value in IceType.values) ...[
         if (value == IceType.crushed) const SizedBox(width: 12),
         Expanded(child: _IceTypeTile(type: value, selected: type == value, onTap: () => chooseType(value))),
        ],
       ]),
       const SizedBox(height: 24),
       const _SectionLabel('Qual o peso?'),
       const SizedBox(height: 12),
       LayoutBuilder(builder: (context, box) => Wrap(spacing: 10, runSpacing: 10, children: [
        for (final weight in weights) SizedBox(width: (box.maxWidth - 10) / 2,
         child: ChoiceChip(showCheckmark: false, selected: kilograms == weight,
          onSelected: all.any((o) => o.type == type && o.kilograms == weight)
           ? (_) => setState(() { kilograms = weight; productId = null; quantity = 1; }) : null,
          selectedColor: const Color(0xFF123F49), backgroundColor: Colors.white,
          disabledColor: const Color(0xFFEAF0F3),
          side: BorderSide(color: kilograms == weight ? const Color(0xFF123F49) : const Color(0xFFC9DCE3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          label: Center(child: Text(weight.toString() + ' kg', style: TextStyle(fontSize: 16,
           fontWeight: FontWeight.w800, color: kilograms == weight ? Colors.white : const Color(0xFF527582)))))),
       ])),
       const SizedBox(height: 24),
       if (selected == null) Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const PrimeText('Esta combinação não está disponível. Confira as opções abaixo ou escolha outro tipo.',
         style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF527582))))
       else ...[
        if (candidates.length > 1) ...[
         const _SectionLabel('Escolha seu produto'),
         const SizedBox(height: 10),
         for (final option in candidates) Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(button: true, selected: selected.id == option.id,
           child: InkWell(borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() { productId = option.id; quantity = 1; }),
            child: Padding(padding: const EdgeInsets.all(12), child: Row(
             crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(selected.id == option.id ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
               color: const Color(0xFF397B97), size: 22),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
               PrimeText(option.product['name'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
               const SizedBox(height: 4),
               Text(_money(double.tryParse(option.product['price'].toString()) ?? 0), style: const TextStyle(color: AppColors.muted)),
              ])),
             ]))))),
         const SizedBox(height: 12),
        ],
        _SelectedIceProduct(option: selected, available: state.stockLimit(selected.id) > 0),
       ],
       if (!stickyFooter) ...[const SizedBox(height: 20), footer],
      ])),
      if (stickyFooter) footer,
     ])));
  });
}

String _money(double value) => r'R$ ' + value.toStringAsFixed(2).replaceAll('.', ',');

class _SectionLabel extends StatelessWidget {
 const _SectionLabel(this.label);
 final String label;
 @override Widget build(BuildContext context) => PrimeText(label,
  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF123F49)));
}

class _SelectedIceProduct extends StatelessWidget {
 const _SelectedIceProduct({required this.option, required this.available});
 final IceProductOption option;
 final bool available;
 @override Widget build(BuildContext context) {
  final url = (option.product['imageUrl'] ?? '').toString().trim();
  final image = SizedBox(width: 64, height: 70, child: ClipRRect(borderRadius: BorderRadius.circular(12),
   child: url.isEmpty ? CustomPaint(painter: _IcePainter(crushed: option.type == IceType.crushed))
    : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
     CustomPaint(painter: _IcePainter(crushed: option.type == IceType.crushed)))));
  return Container(padding: const EdgeInsets.all(14),
   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFC9DCE3))),
   child: Row(children: [
    image, const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
     PrimeText(option.product['name'].toString(), style: const TextStyle(
      fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF123F49))),
     const SizedBox(height: 7),
     PrimeText(available ? 'Em estoque' : 'Indisponível', style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: available ? const Color(0xFF20785D) : AppColors.muted)),
    ])),
   ]));
 }
}

class _IceTypeTile extends StatelessWidget {
 const _IceTypeTile({required this.type, required this.selected, required this.onTap});
 final IceType type;
 final bool selected;
 final VoidCallback onTap;
 @override Widget build(BuildContext context) => Semantics(button: true, selected: selected,
  label: translateLabel(type.label), child: Material(color: selected ? const Color(0xFFE2F2FA) : Colors.white,
   borderRadius: BorderRadius.circular(18),
   child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
    child: Container(padding: const EdgeInsets.all(14),
     decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
      border: Border.all(color: selected ? const Color(0xFF397B97) : const Color(0xFFC6DDE7), width: selected ? 2 : 1)),
     child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
       SizedBox(width: 42, height: 42, child: CustomPaint(painter: _IcePainter(crushed: type == IceType.crushed))),
       const Spacer(),
       if (selected) const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF397B97)),
      ]),
      const SizedBox(height: 10),
      PrimeText(type.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF123F49))),
     ])))));
}

class _IcePainter extends CustomPainter {
 const _IcePainter({required this.crushed});
 final bool crushed;
 @override void paint(Canvas canvas, Size size) {
  canvas.save(); canvas.scale(size.width / 48, size.height / 48);
  final fill = Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
   colors: [Color(0xFFFAFFFF), Color(0xFF8ECADD)]).createShader(const Rect.fromLTWH(0, 0, 48, 48));
  final border = Paint()..color = const Color(0xFF6EABBF)..style = PaintingStyle.stroke..strokeWidth = 1.3;
  if (crushed) {
   for (final point in const [Offset(7, 24), Offset(19, 19), Offset(31, 26), Offset(15, 33), Offset(29, 36), Offset(24, 7)]) {
    final path = Path()..moveTo(point.dx, point.dy - 5)..lineTo(point.dx + 8, point.dy)
     ..lineTo(point.dx + 4, point.dy + 8)..lineTo(point.dx - 5, point.dy + 5)..close();
    canvas.drawPath(path, fill); canvas.drawPath(path, border);
   }
  } else {
   for (final point in const [Offset(8, 22), Offset(23, 20), Offset(16, 7)]) {
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(point.dx, point.dy, 19, 19), const Radius.circular(5));
    canvas.drawRRect(rect, fill); canvas.drawRRect(rect, border);
    canvas.drawLine(Offset(point.dx + 4, point.dy + 5), Offset(point.dx + 12, point.dy + 5),
     Paint()..color = Colors.white..strokeWidth = 2..strokeCap = StrokeCap.round);
   }
  }
  canvas.restore();
 }
 @override bool shouldRepaint(covariant _IcePainter oldDelegate) => crushed != oldDelegate.crushed;
}
