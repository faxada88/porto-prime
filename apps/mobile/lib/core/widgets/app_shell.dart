import 'package:flutter/material.dart';
import 'customer_demand_notice.dart';

import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/courier/presentation/pages/courier_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../navigation/app_nav.dart';
import '../state/app_state.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const pages = [
    HomePage(),
    CategoriesPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    AppNav.instance.index.addListener(_changed);
  }

  @override
  void dispose() {
    AppNav.instance.index.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final state = AppState.instance;
      if (state.isCourier) return const CourierPage();

      final index = AppNav.instance.index.value;

      return Scaffold(
        extendBody: true,
        body: Column(children:[if(state.publicHighDemand) const CustomerDemandNotice(),Expanded(child:IndexedStack(index:index,children:pages))]),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            height: AppControl.navHeight,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.midnight,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.ocean800),
              boxShadow: AppShadows.floating,
            ),
            child: Row(
              children: [
                _item(
                  value: 0,
                  icon: AppIcons.home,
                  label: 'Início',
                  current: index,
                ),
                _item(
                  value: 1,
                  icon: AppIcons.search,
                  label: 'Buscar',
                  current: index,
                ),
                _item(
                  value: 2,
                  icon: AppIcons.bag,
                  label: 'Carrinho',
                  current: index,
                  badgeCount: state.cartCount,
                ),
                _item(
                  value: 3,
                  icon: AppIcons.user,
                  label: 'Perfil',
                  current: index,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _item({
    required int value,
    required IconData icon,
    required String label,
    required int current,
    int badgeCount = 0,
  }) {
    final selected = current == value;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => AppNav.instance.go(value),
          child: AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.standard),
            curve: AppMotion.curve,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: .09) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? AppColors.ocean500.withValues(alpha: .4) : Colors.transparent,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.resolve(context, AppMotion.standard),
                      curve: AppMotion.curve,
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.action
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: AppIconSize.md,
                        color: selected ? Colors.white : AppColors.ocean300,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? Colors.white : AppColors.ocean300,
                        fontSize: AppFontSize.caption,
                        letterSpacing: .05,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 3,
                    right: 8,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.coral600,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
