import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Seu carrinho', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        const Center(child: Column(children: [
          Icon(Icons.shopping_bag_outlined, size: 72, color: AppColors.primary),
          SizedBox(height: 18),
          Text('Seu carrinho está vazio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('Adicione suas bebidas favoritas para continuar.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
        ])),
        const Spacer(),
      ]),
    ),
  );
}
