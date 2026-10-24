import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Presentation only: selection is owned by the existing shell/router.
class PrimeBottomNavigation extends StatelessWidget {
  const PrimeBottomNavigation({super.key, required this.index,
    required this.onSelect, this.orderCount = 0, this.cartCount = 0, this.showOrders = false});
  final int index, cartCount, orderCount;
  final bool showOrders;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF7FAFB),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      child: Center(heightFactor: 1, child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5F7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF668F99), width: 1.8),
            boxShadow: const [
              BoxShadow(color: Color(0x0D3F7883), blurRadius: 18, spreadRadius: 1, offset: Offset(0, 5)),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white, width: 1.2),
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF3FBFC)],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Material(color: Colors.transparent, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                child: Row(children: [
                  _destination(context, 0, 'Início', AppIcons.home),
                  if (showOrders) _destination(context, 1, 'Pedidos', AppIcons.receipt_long_rounded),
                  _destination(context, 2, 'Carrinho', AppIcons.cart),
                  _destination(context, 4, 'Ofertas', AppIcons.tag),
                  _destination(context, 3, 'Conta', AppIcons.user),
                ]),
              )),
            ),
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
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          decoration: BoxDecoration(color: Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(duration: AppMotion.resolve(context, AppMotion.standard),
              width: 42, height: 26, decoration: BoxDecoration(color:Colors.transparent,borderRadius:BorderRadius.circular(14)), child: Stack(clipBehavior: Clip.none,
              alignment: Alignment.center, children: [
                Icon(selected && value == 0 ? Icons.home_rounded : icon, size: selected ? 25 : 24,
                  color: selected ? const Color(0xFF246D77) : const Color(0xFF566D75)),
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
                color: selected ? const Color(0xFF246D77) : const Color(0xFF566D75))))),
            const SizedBox(height:4),
            AnimatedContainer(duration:AppMotion.resolve(context,AppMotion.standard),
              height:2,width:selected?20:6,decoration:BoxDecoration(
                color:selected?const Color(0xFF246D77):Colors.transparent,borderRadius:BorderRadius.circular(4))),
          ]),
        ),
      )),
    ));
  }
}
