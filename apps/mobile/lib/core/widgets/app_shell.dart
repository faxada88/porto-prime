import 'package:flutter/material.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  static const pages = [HomePage(), CategoriesPage(), CartPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Início'),
        NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Categorias'),
        NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag_rounded), label: 'Carrinho'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
      ],
    ),
  );
}
