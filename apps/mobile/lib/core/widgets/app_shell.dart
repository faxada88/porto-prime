import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  static const pages = [HomePage(), CategoriesPage(), CartPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF15211F).withValues(alpha: .96),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: Row(children: [
          _item(0, Icons.home_rounded, 'Início'),
          _item(1, Icons.grid_view_rounded, 'Descobrir'),
          _item(2, Icons.shopping_bag_rounded, 'Sacola', badge: true),
          _item(3, Icons.person_rounded, 'Perfil'),
        ]),
      ),
    ),
  );

  Widget _item(int value, IconData icon, String label, {bool badge = false}) {
    final selected = index == value;
    return Expanded(child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => index = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(19)),
        child: Stack(alignment: Alignment.center, children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 22, color: selected ? AppColors.oceanDeep : Colors.white70),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? AppColors.ink : Colors.white70)),
          ]),
          if (badge) Positioned(top: 8, right: 18, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle))),
        ]),
      ),
    ));
  }
}
