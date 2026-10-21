import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Presentation only: selection is owned by the existing shell/router.
class PrimeBottomNavigation extends StatelessWidget {
  const PrimeBottomNavigation({super.key, required this.index,
    required this.onSelect, this.cartCount = 0});
  final int index, cartCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => ColoredBox(color:Colors.white,child:SafeArea(
    top:false,
    minimum: const EdgeInsets.fromLTRB(0, 0, 0, 0),
    child: Center(heightFactor: 1, child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color:Colors.white,
          border:const Border(top:BorderSide(color:Color(0xFFE1EAED))),
          boxShadow:const [BoxShadow(color:Color(0x08000000),blurRadius:14,offset:Offset(0,-4))]),
        child: Row(children: [
          _destination(context, 0, 'Início', AppIcons.home),
          _destination(context, 1, 'Buscar', AppIcons.search),
          _destination(context, 2, 'Carrinho', AppIcons.cart),
          _destination(context, 3, 'Conta', AppIcons.user),
        ]),
      ),
    )),
  ));

  Widget _destination(BuildContext context, int value, String label, IconData icon) {
    final selected = index == value;
    final highlight = AppColors.ocean100;
    return Expanded(child: Semantics(button: true, selected: selected,
      label: value == 2 && cartCount > 0 ? '$label, $cartCount itens' : label,
      excludeSemantics: true, onTap: () => onSelect(value),
      child: Material(color: Colors.transparent, child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: AppMotion.resolve(context, AppMotion.standard),
          curve: AppMotion.curve,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          decoration: BoxDecoration(color: Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(duration: AppMotion.resolve(context, AppMotion.standard),
              width: 58, height: 32, decoration: BoxDecoration(color:selected?highlight:Colors.transparent,borderRadius:BorderRadius.circular(14)), child: Stack(clipBehavior: Clip.none,
              alignment: Alignment.center, children: [
                Icon(icon, size: selected ? 24 : 23,
                  color: selected ? AppColors.ocean700 : AppColors.muted),
                if (value == 2 && cartCount > 0) Positioned(top: -5, right: 2,
                  child: Container(constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: AppColors.coral600,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1.5)),
                    alignment: Alignment.center,
                    child: Text(cartCount > 99 ? '99+' : '$cartCount',
                      textScaler: TextScaler.noScaling,
                      style: const TextStyle(fontSize: 10, height: 1.2,
                        fontWeight: FontWeight.w800, color: Colors.white)))),
              ])),
            const SizedBox(height: 5),
            SizedBox(height: 17, child: FittedBox(fit: BoxFit.scaleDown,
              child: Text(label, style: TextStyle(fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.ocean700 : AppColors.muted)))),
          ]),
        ),
      )),
    ));
  }
}
