import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Categorias', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Encontre sua bebida favorita.', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 22),
        Expanded(child: GridView.builder(
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35),
          itemBuilder: (_, i) {
            const names = ['Cervejas', 'Whiskies', 'Gin & Vodka', 'Vinhos', 'Refrigerantes', 'Gelo & mais'];
            const icons = [Icons.sports_bar_rounded, Icons.liquor_rounded, Icons.local_bar_rounded, Icons.wine_bar_rounded, Icons.local_drink_rounded, Icons.ac_unit_rounded];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Icon(icons[i], color: AppColors.primaryDark, size: 31),
                Text(names[i], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            );
          },
        )),
      ]),
    ),
  );
}
