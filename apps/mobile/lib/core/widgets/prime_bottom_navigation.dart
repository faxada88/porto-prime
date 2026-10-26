import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import 'prime_animated_navigation.dart';

/// Keeps the shell's original destination IDs, badge counts and callbacks.
class PrimeBottomNavigation extends StatelessWidget {
  const PrimeBottomNavigation({super.key, required this.index,
    required this.onSelect, this.orderCount = 0, this.cartCount = 0, this.showOrders = false});
  final int index, cartCount, orderCount;
  final bool showOrders;
  final ValueChanged<int> onSelect;

  @override Widget build(BuildContext context) => PrimeAnimatedNavigation(
    selectedValue: index, onSelect: onSelect, destinations: [
      const PrimeNavigationDestination(value: 0, label: 'Início', icon: AppIcons.home,
        selectedIcon: Icons.home_rounded),
      if (showOrders) PrimeNavigationDestination(value: 1, label: 'Pedidos',
        icon: AppIcons.receipt_long_rounded, badgeCount: orderCount,
        semanticLabel: orderCount > 0 ? 'Pedidos, $orderCount pedidos ativos' : 'Pedidos'),
      PrimeNavigationDestination(value: 2, label: 'Carrinho', icon: AppIcons.cart,
        badgeCount: cartCount, semanticLabel: cartCount > 0 ? 'Carrinho, $cartCount itens' : 'Carrinho'),
      const PrimeNavigationDestination(value: 4, label: 'Ofertas', icon: AppIcons.tag),
      const PrimeNavigationDestination(value: 3, label: 'Conta', icon: AppIcons.user),
    ]);
}
