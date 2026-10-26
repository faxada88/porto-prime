import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class CheckoutProgress extends StatelessWidget {
 const CheckoutProgress({super.key,required this.step});
 final int step;
 @override
 Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
  final vertical = box.maxWidth < 360 || MediaQuery.textScalerOf(context).scale(14) > 19;
  final items = List.generate(3, (index) => Semantics(
   selected: index == step, child: Padding(padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [Container(width: 28, height: 28,
     decoration: BoxDecoration(color: index <= step ? AppColors.ocean700 : AppColors.surfaceMuted,
      shape: BoxShape.circle), child: Icon(index < step ? AppIcons.check :
       index == 0 ? AppIcons.cart : index == 1 ? AppIcons.mapPin : AppIcons.lock,
       size: 15, color: index <= step ? Colors.white : AppColors.muted)),
     const SizedBox(width: 8), Expanded(child: PrimeText(['Carrinho','Entrega','Pagamento'][index],
      style: TextStyle(fontSize: 12, height: 1.3, fontWeight: index == step ? FontWeight.w800 : FontWeight.w500,
       color: index <= step ? AppColors.ocean900 : AppColors.muted))),
    ]))));
  return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
   color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md),
   border: Border.all(color: AppColors.stroke)), child: vertical
    ? Column(mainAxisSize: MainAxisSize.min, children: items)
    : Row(children: [for (final item in items) Expanded(child: item)]));
 });

}
class CheckoutPriceLine extends StatelessWidget {
 const CheckoutPriceLine({super.key,required this.label,required this.value,this.strong=false});
 final String label,value;final bool strong;
 @override
 Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
  final labelWidget = PrimeText(label, style: TextStyle(color: strong ? AppColors.ink : AppColors.muted,
   fontWeight: strong ? FontWeight.w800 : FontWeight.w500));
  final valueWidget = PrimeText(value, style: TextStyle(fontSize: strong ? 23 : 14,
   fontWeight: FontWeight.w800, color: strong ? AppColors.ocean900 : AppColors.ink));
  final stack = box.maxWidth < 340 || MediaQuery.textScalerOf(context).scale(14) > 19;
  return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: stack
   ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget,
      const SizedBox(height: 4), valueWidget])
   : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: labelWidget),
      const SizedBox(width: 12), Flexible(child: valueWidget)]));
 });

}
String checkoutMoney(dynamic value)=>'R\$ ${(double.tryParse(value.toString())??0).toStringAsFixed(2).replaceAll('.',',')}';

