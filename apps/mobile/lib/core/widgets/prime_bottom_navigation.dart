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
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(10, 6, 10, 8),
    child: Center(heightFactor: 1, child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(gradient: const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF003B3E),Color(0xFF002D31)]),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.ocean800),
          boxShadow: AppShadows.floating),
        child: Row(children: [
          _destination(context, 0, 'Início', AppIcons.home),
          _destination(context, 1, 'Buscar', AppIcons.search),
          _destination(context, 2, 'Carrinho', AppIcons.cart),
          _destination(context, 3, 'Conta', AppIcons.user),
        ]),
      ),
    )),
  );

  Widget _destination(BuildContext context, int value, String label, IconData icon) {
    final selected = index == value;
    final highlight = const Color(0xFFDEF7ED);
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
          decoration: BoxDecoration(color: selected ? highlight : Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 25, child: Stack(clipBehavior: Clip.none,
              alignment: Alignment.center, children: [
                Icon(icon, size: selected ? 24 : 23,
                  color: selected ? AppColors.ocean900 : Colors.white),
                if (value == 2 && cartCount > 0) Positioned(top: -5, right: -14,
                  child: Container(constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: AppColors.coral600,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.ocean900, width: 1.5)),
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
                color: selected ? AppColors.ocean900 : Colors.white)))),
          ]),
        ),
      )),
    ));
  }
}
