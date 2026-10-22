import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Presentation only: selection is owned by the existing shell/router.
class PrimeBottomNavigation extends StatelessWidget {
  const PrimeBottomNavigation({super.key, required this.index,
    required this.onSelect, this.orderCount = 0, this.cartCount = 0});
  final int index, cartCount, orderCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(10, 7, 10, 8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Center(heightFactor: 1, child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          foregroundDecoration:BoxDecoration(borderRadius:BorderRadius.circular(28),border:Border.all(color:const Color(0xFFD9E4E7),width:1.2)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD9E4E7),width:1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x1A233E48), blurRadius: 24, offset: Offset(0, 8)),
              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(color: AppColors.surface, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(children: [
                _destination(context, 0, 'Início', AppIcons.home),
                _destination(context, 1, 'Pedidos', AppIcons.receipt_long_rounded),
                _destination(context, 2, 'Carrinho', AppIcons.cart),
                _destination(context, 4, 'Ofertas', AppIcons.tag),
                _destination(context, 3, 'Conta', AppIcons.user),
              ]),
            )),
          ),
        ),
      )),
    ),
  );

  Widget _destination(BuildContext context, int value, String label, IconData icon) {
    final selected = index == value;
    final count=value==1?orderCount:value==2?cartCount:0;
    return Expanded(child: Semantics(button: true, selected: selected,
      label: translateLabel( count > 0 ? '$label, $count ${value==1?'pedidos ativos':'itens'}' : label),
      excludeSemantics: true, onTap: () => onSelect(value),
      child: Material(color: Colors.transparent, child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: AppMotion.resolve(context, AppMotion.standard),
          curve: AppMotion.curve,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(color: Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(duration: AppMotion.resolve(context, AppMotion.standard),
              width: 42, height: 26, decoration: BoxDecoration(color:Colors.transparent,borderRadius:BorderRadius.circular(14)), child: Stack(clipBehavior: Clip.none,
              alignment: Alignment.center, children: [
                Icon(selected && value == 0 ? Icons.home_rounded : icon, size: selected ? 25 : 24,
                  color: selected ? const Color(0xFF004A50) : const Color(0xFF435761)),
                if (count > 0) Positioned(top: -5, right: 2,
                  child: Container(constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: AppColors.coral600,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1.5)),
                    alignment: Alignment.center,
                    child: PrimeText(count > 99 ? '99+' : '$count',
                      textScaler: TextScaler.noScaling,
                      style: const TextStyle(fontSize: 10, height: 1.2,
                        fontWeight: FontWeight.w800, color: Colors.white)))),
              ])),
            const SizedBox(height: 2),
            SizedBox(height: 13, child: FittedBox(fit: BoxFit.scaleDown,
              child: PrimeText(label, style: TextStyle(fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: selected ? const Color(0xFF004A50) : const Color(0xFF435761))))),
            const SizedBox(height:4),
            AnimatedContainer(duration:AppMotion.resolve(context,AppMotion.standard),
              height:2,width:selected?20:6,decoration:BoxDecoration(
                color:selected?const Color(0xFF004A50):Colors.transparent,borderRadius:BorderRadius.circular(4))),
          ]),
        ),
      )),
    ));
  }
}
