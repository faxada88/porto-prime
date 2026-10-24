import 'package:flutter/material.dart';
import '../localization/prime_localization.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'ice_product_option.dart';

/// Compatibility entry point: both the optional sheet and category share one form.
Future<void> showIceSelector(BuildContext context, {required String categoryName,
 IceType? initialType, String? initialProductId}) => showModalBottomSheet<void>(
 context: context, isScrollControlled: true, useSafeArea: true,
 backgroundColor: const Color(0xFFF5FAFC),
 shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
 builder: (context) => FractionallySizedBox(heightFactor: .9, child: Column(children: [
  Padding(padding: const EdgeInsets.fromLTRB(20, 8, 8, 0), child: Row(children: [
   Expanded(child: Container(alignment: Alignment.center, child: Container(width: 38, height: 4,
    decoration: BoxDecoration(color: const Color(0xFFB8CED7), borderRadius: BorderRadius.circular(4))))),
   IconButton(tooltip: translateLabel('Fechar'), onPressed: () => Navigator.pop(context),
    icon: const Icon(Icons.close_rounded)),
  ])),
  Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16),
   child: IceOrderPanel(categoryName: categoryName, initialType: initialType,
    initialProductId: initialProductId, closeOnAdd: true))),
 ])));

/// One selection, one real product ID and one total. No duplicate product cards.
class IceOrderPanel extends StatefulWidget {
 const IceOrderPanel({super.key, required this.categoryName, this.initialType,
  this.initialProductId, this.closeOnAdd = false});
 final String categoryName;
 final IceType? initialType;
 final String? initialProductId;
 final bool closeOnAdd;
 @override State<IceOrderPanel> createState() => _IceOrderPanelState();
}
class _IceOrderPanelState extends State<IceOrderPanel> {
 String? selectedId;
 int quantity = 1;
 @override void initState() { super.initState(); selectedId = widget.initialProductId; }
 List<Map<dynamic, dynamic>> get items => AppState.instance.products.whereType<Map>()
  .where((p) => p['category']?['name'] == widget.categoryName && p['archived'] != true).toList();
 Map<dynamic, dynamic>? preferred(Iterable<Map<dynamic, dynamic>> values) {
  final list = values.toList();
  for (final item in list) {
   if (AppState.instance.canIncreaseQuantity(item['id'].toString())) return item;
  }
  return list.isEmpty ? null : list.first;
 }
 Map<dynamic, dynamic>? current(List<Map<dynamic, dynamic>> products) {
  for (final product in products) {
   if (product['id'].toString() == selectedId) return product;
  }
  if (widget.initialType != null && selectedId == null) {
   final match = preferred(products.where((p) => IceProductOption.fromProduct(p)?.type == widget.initialType));
   if (match != null) return match;
  }
  return preferred(products.where((p) => icePackageKilograms(p) != null
   && AppState.instance.canIncreaseQuantity(p['id'].toString()))) ?? preferred(products);
 }
 void choose(Map<dynamic, dynamic> product) => setState(() {
  selectedId = product['id'].toString(); quantity = 1;
 });
 void add(String id, int count) {
  final state = AppState.instance;
  if (!items.any((p) => p['id'].toString() == id)) return;
  var added = 0;
  while (added < count && state.canIncreaseQuantity(id)) {
   state.addProduct(id); added++;
  }
  if (added == 0) return;
  final messenger = ScaffoldMessenger.of(context);
  if (widget.closeOnAdd) {
   Navigator.of(context).pop();
  } else {
   setState(() => quantity = 1);
  }
  messenger.showSnackBar(const SnackBar(content: PrimeText('Gelo adicionado ao carrinho'),
   duration: Duration(seconds: 2)));
 }
 @override Widget build(BuildContext context) => AnimatedBuilder(
  animation: Listenable.merge([AppState.instance, AppLanguage.instance]),
  builder: (context, _) {
   final state = AppState.instance;
   final products = items;
   final product = current(products);
   if (product == null) {
    return Container(padding: const EdgeInsets.all(28),
     decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
     child: const Column(children: [
      Icon(Icons.ac_unit_rounded, size: 40, color: Color(0xFF6798AA)),
      SizedBox(height: 14),
      PrimeText('Novas opções de gelo em breve.', textAlign: TextAlign.center,
       style: TextStyle(fontSize: 16, height: 1.4, color: Color(0xFF527582))),
     ]));
   }
   final option = IceProductOption.fromProduct(product);
   final options = iceOptionsFor(products, widget.categoryName);
   final other = products.where((p) => IceProductOption.fromProduct(p) == null).toList();
   final selectedWeight = icePackageKilograms(product);
   final weightPool = option == null ? other : options
    .where((o) => o.type == option.type).map((o) => o.product).toList();
   final candidates = weightPool.where((p) => icePackageKilograms(p) == selectedWeight).toList();
   final id = product['id'].toString();
   final rawRemaining = state.stockLimit(id) - (state.cart[id] ?? 0);
   final remaining = rawRemaining < 0 ? 0 : rawRemaining;
   final count = remaining == 0 ? 1 : quantity > remaining ? remaining : quantity;
   final canAdd = state.canIncreaseQuantity(id) && count <= remaining;
   final price = double.tryParse(product['price'].toString()) ?? 0.0;
   final weights = <int>{3, 6, 10, 20, ...weightPool.map(icePackageKilograms).whereType<int>()}.toList()..sort();
   final url = (product['imageUrl'] ?? '').toString().trim();
   final availability = state.stockLimit(id) > 0 ? 'Em estoque' : 'Indisponível';
   return Container(padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
     border: Border.all(color: const Color(0xFFBBD7E3), width: 1.3)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
     Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(width: 64, height: 68, padding: const EdgeInsets.all(6),
       decoration: BoxDecoration(color: const Color(0xFFEDF7FC), borderRadius: BorderRadius.circular(17)),
       child: ClipRRect(borderRadius: BorderRadius.circular(12), child: url.isEmpty
        ? CustomPaint(painter: _IcePainter(crushed: option?.type == IceType.crushed))
        : Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) =>
         CustomPaint(painter: _IcePainter(crushed: option?.type == IceType.crushed))))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
       const PrimeText('Escolha seu gelo', style: TextStyle(fontSize: 21, height: 1.15,
        fontWeight: FontWeight.w800, color: Color(0xFF123F49))),
       const SizedBox(height: 6),
       const PrimeText('Escolha, adicione e pronto.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF527582))),
      ])),
     ]),
     if (options.isNotEmpty) ...[
      const SizedBox(height: 22),
      const _IceLabel('Tipo'),
      const SizedBox(height: 9),
      Wrap(spacing: 8, runSpacing: 8, children: [
       for (final type in IceType.values) _IceChoice(label: type.label,
        selected: option?.type == type,
        icon: type == IceType.cubes ? Icons.ac_unit_rounded : Icons.grain_rounded,
        onTap: options.any((o) => o.type == type) ? () {
         final sameWeight = options.where((o) => o.type == type && o.kilograms == selectedWeight);
         final next = preferred(sameWeight.where((o) => state.canIncreaseQuantity(o.id)).map((o) => o.product))
          ?? preferred(options.where((o) => o.type == type).map((o) => o.product));
         if (next != null) choose(next);
        } : null),
       if (other.isNotEmpty) _IceChoice(label: 'Outras opções', selected: option == null,
        onTap: () { final next = preferred(other); if (next != null) choose(next); }),
      ]),
     ],
     const SizedBox(height: 18),
     InputDecorator(
      decoration: PrimeInputDecoration(labelText: 'Peso do pacote',
       prefixIcon: const Icon(Icons.inventory_2_outlined, size: 21, color: Color(0xFF397B97)),
       filled: true, fillColor: const Color(0xFFF1F8FC),
       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFAFCDD9))),
       enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFAFCDD9)))),
      child: DropdownButtonHideUnderline(child: DropdownButton<int>(
       key: const ValueKey('ice-weight-dropdown'),
       isExpanded: true, value: selectedWeight, borderRadius: BorderRadius.circular(18),
       dropdownColor: Colors.white, menuMaxHeight: 360,
       icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF245D6B)),
       hint: PrimeText(selectedWeight == null && weightPool.every((p) => icePackageKilograms(p) == null)
        ? 'Peso não informado' : 'Selecione o peso',
        style: const TextStyle(fontSize: 14, color: Color(0xFF527582))),
       selectedItemBuilder: (context) => [
        for (final weight in weights) Align(alignment: Alignment.centerLeft,
         child: Text(weight.toString() + ' kg', style: const TextStyle(fontSize: 16,
          fontWeight: FontWeight.w800, color: Color(0xFF123F49)))),
       ],
       items: [
        for (final weight in weights) DropdownMenuItem<int>(
         value: weight, enabled: weightPool.any((p) => icePackageKilograms(p) == weight),
         child: Row(children: [
          Text(weight.toString() + ' kg', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          if (!weightPool.any((p) => icePackageKilograms(p) == weight))
           const Expanded(child: PrimeText('Indisponível', maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end, style: TextStyle(fontSize: 11, color: AppColors.muted))),
         ])),
       ],
       onChanged: (weight) {
        final next = preferred(weightPool.where((p) => icePackageKilograms(p) == weight));
        if (next != null) choose(next);
       },
      ))),
     const SizedBox(height: 20),
     if (candidates.length > 1) InputDecorator(
      decoration: PrimeInputDecoration(labelText: 'Produto', contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCFDEE5)))),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
       isExpanded: true, value: id,
       items: candidates.map((p) => DropdownMenuItem<String>(value: p['id'].toString(),
        child: PrimeText(p['name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF123F49))))).toList(),
       onChanged: (value) { for (final p in candidates) { if (p['id'].toString() == value) { choose(p); break; } } },
      )))
     else PrimeText(product['name'].toString(), style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF123F49))),
     const SizedBox(height: 6),
     PrimeText(availability, style: const TextStyle(fontSize: 11, color: Color(0xFF527582))),
     const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Divider(height: 1, color: Color(0xFFE0ECF0))),
     Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16, runSpacing: 14, children: [
       Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _IceLabel('Quantidade'), const SizedBox(height: 7),
        Container(decoration: BoxDecoration(color: const Color(0xFFF1F8FB),
         borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFC9DDE5))),
         child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(tooltip: translateLabel('Diminuir quantidade'), icon: const Icon(Icons.remove_rounded, size: 21),
           onPressed: count > 1 ? () => setState(() => quantity = count - 1) : null),
          SizedBox(width: 28, child: Text(count.toString(), textAlign: TextAlign.center,
           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF123F49)))),
          IconButton(tooltip: translateLabel('Aumentar quantidade'), icon: const Icon(Icons.add_rounded, size: 21),
           onPressed: canAdd && count < remaining ? () => setState(() => quantity = count + 1) : null),
         ])),
       ]),
       Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const _IceLabel('Total'), const SizedBox(height: 7),
        Text(r'R$ ' + (price * count).toStringAsFixed(2).replaceAll('.', ','),
         style: const TextStyle(fontSize: 25, height: 1.3, fontWeight: FontWeight.w800, color: Color(0xFF123F49))),
       ]),
      ]),
     const SizedBox(height: 18),
     FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF245D6B), foregroundColor: Colors.white,
       minimumSize: const Size(0, 52), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      onPressed: canAdd ? () => add(id, count) : null, icon: const Icon(Icons.add_shopping_cart_rounded, size: 21),
      label: PrimeText(!state.storeStatusKnown ? 'Aguarde um instante' : !state.storeOpen ? 'Loja fechada no momento'
       : !canAdd ? (remaining == 0 && state.stockLimit(id) > 0 ? 'Limite de estoque atingido' : 'Indisponível')
       : 'Adicionar ao carrinho', textAlign: TextAlign.center,
       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
    ]));
  });
}

class _IceLabel extends StatelessWidget {
 const _IceLabel(this.label);
 final String label;
 @override Widget build(BuildContext context) => PrimeText(label,
  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF527582)));
}
class _IceChoice extends StatelessWidget {
 const _IceChoice({required this.label, required this.selected, required this.onTap, this.icon, this.translate = true});
 final String label;
 final bool selected, translate;
 final IconData? icon;
 final VoidCallback? onTap;
 @override Widget build(BuildContext context) => Semantics(button: true, selected: selected, enabled: onTap != null,
  child: OutlinedButton(
   onPressed: onTap,
   style: OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF215465), backgroundColor: selected ? const Color(0xFFE4F3F8) : Colors.white,
    minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    side: BorderSide(color: selected ? const Color(0xFF4B879D) : const Color(0xFFCFDEE5), width: selected ? 1.8 : 1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
   child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
    if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
    Flexible(child: Text(translate ? AppLanguage.instance.translate(label) : label, textAlign: TextAlign.center,
     style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w800 : FontWeight.w600))),
   ])));
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
