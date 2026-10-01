import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Perfil', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: const Row(children: [
            CircleAvatar(radius: 28, backgroundColor: Color(0xFFE0F5ED), child: Icon(Icons.person_rounded, color: AppColors.primaryDark)),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Olá!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 3),
              Text('Entre para acompanhar seus pedidos', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ])),
            Icon(Icons.chevron_right_rounded),
          ]),
        ),
        const SizedBox(height: 18),
        for (final item in const [
          ('Meus pedidos', Icons.receipt_long_outlined),
          ('Endereços', Icons.location_on_outlined),
          ('Pagamentos', Icons.credit_card_outlined),
          ('Ajuda', Icons.help_outline_rounded),
        ])
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            leading: Icon(item.$2, color: AppColors.primaryDark),
            title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
      ],
    ),
  );
}
