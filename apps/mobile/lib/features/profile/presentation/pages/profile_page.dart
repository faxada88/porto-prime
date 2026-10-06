import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../orders/presentation/pages/orders_page.dart';
import 'registration_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: AppState.instance,
        builder: (_, __) =>
            AppState.instance.loggedIn ? const _Account() : const _Guest(),
      );
}

class _Guest extends StatelessWidget {
  const _Guest();

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 126),
          children: [
            const _ProfileHeader(),
            const SizedBox(height: 22),
            _GuestHero(onTap: () => _accountMenu(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.receipt_long_rounded,
                    label: 'Pedidos',
                    subtitle: 'Acompanhar',
                    onTap: () => _accountMenu(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.location_on_rounded,
                    label: 'Endereços',
                    subtitle: 'Gerenciar',
                    onTap: () => _accountMenu(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.support_agent_rounded,
                    label: 'Suporte',
                    subtitle: 'Falar conosco',
                    onTap: () => _support(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _SectionLabel(
              eyebrow: 'ACESSO PORTO PRIME',
              title: 'Escolha como você faz parte',
              subtitle:
                  'Cliente, motoboy ou parceiro: cada perfil tem uma experiência própria.',
            ),
            const SizedBox(height: 13),
            _AccessCard(
              icon: Icons.shopping_bag_rounded,
              iconBackground: AppColors.sand,
              title: 'Quero comprar',
              subtitle: 'Crie sua conta de cliente e peça em poucos passos.',
              badge: 'CLIENTE',
              onTap: () => _register(context, 'CUSTOMER'),
            ),
            const SizedBox(height: 10),
            _AccessCard(
              icon: Icons.two_wheeler_rounded,
              iconBackground: AppColors.mint,
              title: 'Quero entregar',
              subtitle:
                  'Candidate-se como motoboy e acompanhe toda a análise do cadastro.',
              badge: 'MOTOBOY',
              onTap: () => _register(context, 'COURIER'),
            ),
            const SizedBox(height: 10),
            _ApplicationShortcut(
              onTap: () => _courierStatus(context),
            ),
            const SizedBox(height: 10),
            _AccessCard(
              icon: Icons.storefront_rounded,
              iconBackground: AppColors.lavender,
              title: 'Quero ser parceiro',
              subtitle:
                  'Cadastre seu negócio para participar do ecossistema Porto Prime.',
              badge: 'PARCEIRO',
              onTap: () => _register(context, 'PARTNER'),
            ),
            const SizedBox(height: 28),
            const _SectionLabel(
              eyebrow: 'CONTA & SEGURANÇA',
              title: 'Tudo organizado em um só lugar',
            ),
            const SizedBox(height: 12),
            _MenuSurface(
              children: [
                _MenuLine(
                  icon: Icons.credit_card_rounded,
                  title: 'Pagamentos',
                  subtitle: 'Métodos, cobranças e segurança',
                  onTap: () => _accountMenu(context),
                ),
                _MenuLine(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notificações',
                  subtitle: 'Acompanhe cada etapa do seu pedido',
                  onTap: () => _simpleMessage(
                    context,
                    'Notificações',
                    'Entre na sua conta para configurar alertas, pedidos e atualizações.',
                  ),
                ),
                _MenuLine(
                  icon: Icons.shield_rounded,
                  title: 'Privacidade',
                  subtitle: 'Proteção e uso dos seus dados',
                  onTap: () => _simpleMessage(
                    context,
                    'Privacidade',
                    'Seus dados são usados somente nos fluxos necessários para conta, pedidos, pagamentos e entregas.',
                  ),
                  last: true,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _BahiaSignature(),
          ],
        ),
      );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PORTO PRIME ACCOUNT',
                  style: TextStyle(
                    color: AppColors.ocean,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.7,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Seu espaço',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Conta, entregas e benefícios com a energia de Porto Seguro.',
                  style: TextStyle(
                    color: AppColors.muted,
                    height: 1.4,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.stroke),
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: AppColors.sun,
              size: 25,
            ),
          ),
        ],
      );
}

class _GuestHero extends StatelessWidget {
  const _GuestHero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(31),
          child: Ink(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(31),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF102B27),
                  Color(0xFF075F55),
                  Color(0xFF0C8979),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.oceanDeep.withValues(alpha: .22),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -48,
                  top: -55,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .055),
                    ),
                  ),
                ),
                Positioned(
                  right: 42,
                  bottom: -62,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.sun.withValues(alpha: .10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(23),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .10),
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 12,
                                  color: Color(0xFFFFD889),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'ACESSO SEGURO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Sua Porto Prime\ncomeça aqui.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.8,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Entre ou crie sua conta para liberar a experiência completa.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Container(
                            width: 43,
                            height: 43,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.oceanDeep,
                              size: 21,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Container(
            height: 102,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.oceanDeep, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: AppColors.ocean,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -.45,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(23),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: AppColors.stroke),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: AppColors.ink, size: 25),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.2,
                              ),
                            ),
                          ),
                          Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 7.5,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      );
}

class _ApplicationShortcut extends StatelessWidget {
  const _ApplicationShortcut({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(23),
          child: Ink(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF0CF), Color(0xFFFFF8EA)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: const Color(0xFFF1D9A8)),
            ),
            child: const Row(
              children: [
                _MiniIconBox(
                  icon: Icons.manage_search_rounded,
                  background: Colors.white,
                  foreground: Color(0xFF9B6817),
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Já enviou sua candidatura?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Consulte o status e responda pendências pelo CPF.',
                        style: TextStyle(
                          color: Color(0xFF8D6C35),
                          fontSize: 9.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF9B6817),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
}

class _MiniIconBox extends StatelessWidget {
  const _MiniIconBox({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: foreground, size: 22),
      );
}

class _MenuSurface extends StatelessWidget {
  const _MenuSurface({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.stroke),
          boxShadow: AppShadows.soft,
        ),
        child: Column(children: children),
      );
}

class _MenuLine extends StatelessWidget {
  const _MenuLine({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ListTile(
            onTap: onTap,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            leading: _MiniIconBox(
              icon: icon,
              background: AppColors.mint,
              foreground: AppColors.oceanDeep,
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 20,
            ),
          ),
          if (!last)
            const Divider(
              height: 1,
              indent: 72,
              endIndent: 15,
              color: AppColors.stroke,
            ),
        ],
      );
}

class _BahiaSignature extends StatelessWidget {
  const _BahiaSignature();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0CF), Color(0xFFE9F7F1)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          children: [
            _MiniIconBox(
              icon: Icons.wb_sunny_rounded,
              background: Colors.white,
              foreground: AppColors.sun,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Feito em Porto Seguro para praia, festa, descanso e aquele brinde que não pode esperar.',
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

Future<void> _accountMenu(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .48),
    builder: (ctx) => _PrimeSheet(
      children: [
        const _SheetBrandHeader(
          icon: Icons.person_rounded,
          eyebrow: 'SUA PORTO PRIME',
          title: 'Entre ou crie sua conta',
          subtitle:
              'Escolha o perfil ideal e continue com uma experiência feita para você.',
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _auth(context);
            },
            icon: const Icon(Icons.login_rounded, size: 20),
            label: const Text(
              'Entrar na minha conta',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(child: Divider(color: AppColors.stroke)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'CRIAR UMA NOVA CONTA',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.stroke)),
          ],
        ),
        const SizedBox(height: 14),
        _RoleCard(
          title: 'Cliente',
          subtitle: 'Peça, pague e acompanhe sua entrega em tempo real.',
          icon: Icons.shopping_bag_rounded,
          accent: AppColors.sun,
          background: AppColors.sand,
          onTap: () {
            Navigator.pop(ctx);
            _register(context, 'CUSTOMER');
          },
        ),
        const SizedBox(height: 10),
        _RoleCard(
          title: 'Motoboy',
          subtitle: 'Envie sua candidatura e trabalhe com a Porto Prime.',
          icon: Icons.two_wheeler_rounded,
          accent: AppColors.ocean,
          background: AppColors.mint,
          onTap: () {
            Navigator.pop(ctx);
            _register(context, 'COURIER');
          },
        ),
        const SizedBox(height: 10),
        _RoleCard(
          title: 'Parceiro',
          subtitle: 'Cadastre seu negócio e participe da rede Porto Prime.',
          icon: Icons.storefront_rounded,
          accent: const Color(0xFF6D5AA8),
          background: AppColors.lavender,
          onTap: () {
            Navigator.pop(ctx);
            _register(context, 'PARTNER');
          },
        ),
        const SizedBox(height: 14),
        Material(
          color: const Color(0xFFFFF7E7),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.pop(ctx);
              _courierStatus(context);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF0DEB9)),
              ),
              child: const Row(
                children: [
                  _MiniIconBox(
                    icon: Icons.fact_check_rounded,
                    background: Colors.white,
                    foreground: Color(0xFF9B6817),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acompanhar candidatura',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Consulte pelo CPF e responda solicitações do Admin.',
                          style: TextStyle(
                            color: Color(0xFF866A3E),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF9B6817),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.background,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: accent, size: 25),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      );
}

Future<void> _courierStatus(BuildContext context) async {
  final cpf = TextEditingController();
  Map<String, dynamic>? application;
  String? error;
  bool loading = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .52),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        Future<void> search() async {
          setSheetState(() {
            loading = true;
            error = null;
          });
          try {
            final result = await AppState.instance.courierApplicationStatus(
              cpf.text,
            );
            if (!sheetContext.mounted) return;
            setSheetState(() => application = result);
          } catch (e) {
            if (!sheetContext.mounted) return;
            setSheetState(() {
              application = null;
              error = e.toString().replaceFirst('Exception: ', '');
            });
          } finally {
            if (sheetContext.mounted) {
              setSheetState(() => loading = false);
            }
          }
        }

        Future<void> answer(dynamic requirement) async {
          final response = TextEditingController();
          final sent = await showDialog<bool>(
            context: sheetContext,
            barrierColor: Colors.black.withValues(alpha: .50),
            builder: (dialogContext) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppShadows.elevated,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MiniIconBox(
                      icon: Icons.edit_note_rounded,
                      background: AppColors.sand,
                      foreground: Color(0xFF9B6817),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      (requirement['title'] ?? 'Pendência').toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      (requirement['description'] ?? '').toString(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 17),
                    TextField(
                      controller: response,
                      minLines: 4,
                      maxLines: 7,
                      decoration: InputDecoration(
                        labelText: 'Sua resposta',
                        hintText: 'Digite a informação solicitada pelo Admin...',
                        alignLabelWithHint: true,
                        fillColor: AppColors.canvas,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            child: const Text('Enviar resposta'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );

          if (sent != true || response.text.trim().isEmpty) {
            response.dispose();
            return;
          }

          try {
            await AppState.instance.respondCourierApplicationRequirement(
              requirement['id'].toString(),
              cpf.text,
              response.text.trim(),
            );
            await search();
          } catch (e) {
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                  ),
                ),
              );
            }
          } finally {
            response.dispose();
          }
        }

        final requirements = application?['requirements'] is List
            ? List<dynamic>.from(application!['requirements'])
            : <dynamic>[];

        return _PrimeSheet(
          maxHeightFactor: .93,
          children: [
            const _SheetBrandHeader(
              icon: Icons.manage_search_rounded,
              eyebrow: 'CENTRAL DO MOTOBOY',
              title: 'Acompanhe sua candidatura',
              subtitle:
                  'Consulte a análise pelo CPF e resolva qualquer solicitação enviada pela equipe Porto Prime.',
            ),
            const SizedBox(height: 18),
            _PremiumField(
              controller: cpf,
              label: 'CPF da candidatura',
              hint: '000.000.000-00',
              icon: Icons.badge_rounded,
              keyboardType: TextInputType.number,
            ),
            if (error != null) ...[
              const SizedBox(height: 2),
              _InlineNotice(
                icon: Icons.error_outline_rounded,
                text: error!,
                background: AppColors.peach,
                foreground: AppColors.coralStrong,
              ),
            ],
            if (application == null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_rounded,
                      color: AppColors.oceanDeep,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A consulta é protegida pelo CPF informado na candidatura. Nenhum login é necessário nesta etapa.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (application != null) ...[
              const SizedBox(height: 7),
              _ApplicationOverview(application: application!),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: _SectionLabel(
                      eyebrow: 'ACOMPANHAMENTO',
                      title: 'Pendências da análise',
                    ),
                  ),
                  _SmallCounter(value: requirements.length),
                ],
              ),
              const SizedBox(height: 11),
              if (requirements.isEmpty)
                const _InlineNotice(
                  icon: Icons.verified_rounded,
                  text:
                      'Nenhuma pendência em aberto. Sua candidatura segue em análise normalmente.',
                  background: AppColors.mint,
                  foreground: AppColors.oceanDeep,
                )
              else
                ...requirements.map(
                  (requirement) => _RequirementCard(
                    requirement: Map<String, dynamic>.from(requirement),
                    onAnswer: () => answer(requirement),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: loading ? null : search,
                icon: loading
                    ? const SizedBox.shrink()
                    : Icon(
                        application == null
                            ? Icons.search_rounded
                            : Icons.refresh_rounded,
                        size: 20,
                      ),
                label: loading
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        application == null
                            ? 'Consultar candidatura'
                            : 'Atualizar acompanhamento',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        );
      },
    ),
  );

  cpf.dispose();
}

class _ApplicationOverview extends StatelessWidget {
  const _ApplicationOverview({required this.application});
  final Map<String, dynamic> application;

  @override
  Widget build(BuildContext context) {
    final raw = (application['approvalStatus'] ?? 'PENDING').toString();
    final config = _statusConfig(raw);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.background, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: config.foreground.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 53,
                height: 53,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  config.icon,
                  color: config.foreground,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (application['name'] ?? 'Candidatura').toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (application['document'] ?? 'CPF confirmado').toString(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: raw),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(config.icon, color: config.foreground, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    config.message,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({
    required this.requirement,
    required this.onAnswer,
  });

  final Map<String, dynamic> requirement;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    final status = (requirement['status'] ?? 'OPEN').toString();
    final open = status == 'OPEN';
    final answered = status == 'ANSWERED';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: open ? const Color(0xFFFFFBF3) : Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: open ? const Color(0xFFF0DFBC) : AppColors.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniIconBox(
                icon: open
                    ? Icons.notification_important_rounded
                    : answered
                        ? Icons.mark_chat_read_rounded
                        : Icons.verified_rounded,
                background: open ? AppColors.sand : AppColors.mint,
                foreground:
                    open ? const Color(0xFF9B6817) : AppColors.oceanDeep,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (requirement['title'] ?? 'Pendência').toString(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (requirement['description'] ?? '').toString(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: status),
            ],
          ),
          if (requirement['response'] != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SUA RESPOSTA',
                    style: TextStyle(
                      color: AppColors.oceanDeep,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    requirement['response'].toString(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (open) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAnswer,
                icon: const Icon(Icons.reply_rounded, size: 18),
                label: const Text('Responder solicitação'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.foreground,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.message,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
  final String message;
}

_StatusConfig _statusConfig(String raw) {
  switch (raw.toUpperCase()) {
    case 'APPROVED':
    case 'ACTIVE':
      return const _StatusConfig(
        label: 'APROVADO',
        background: AppColors.mint,
        foreground: AppColors.oceanDeep,
        icon: Icons.verified_rounded,
        message:
            'Cadastro aprovado. Seu acesso operacional está liberado conforme as regras da plataforma.',
      );
    case 'REJECTED':
    case 'BLOCKED':
      return const _StatusConfig(
        label: 'NÃO APROVADO',
        background: AppColors.peach,
        foreground: AppColors.coralStrong,
        icon: Icons.cancel_rounded,
        message:
            'A candidatura não foi aprovada. Consulte as orientações recebidas antes de uma nova solicitação.',
      );
    case 'SUSPENDED':
      return const _StatusConfig(
        label: 'SUSPENSO',
        background: AppColors.lavender,
        foreground: Color(0xFF66569B),
        icon: Icons.pause_circle_rounded,
        message:
            'O acesso está temporariamente suspenso. Entre em contato com o suporte para mais informações.',
      );
    case 'ANSWERED':
      return const _StatusConfig(
        label: 'RESPONDIDA',
        background: AppColors.sky,
        foreground: Color(0xFF356D8D),
        icon: Icons.mark_chat_read_rounded,
        message: 'Sua resposta foi enviada e está aguardando revisão.',
      );
    case 'RESOLVED':
      return const _StatusConfig(
        label: 'RESOLVIDA',
        background: AppColors.mint,
        foreground: AppColors.oceanDeep,
        icon: Icons.task_alt_rounded,
        message: 'A solicitação foi resolvida.',
      );
    case 'OPEN':
      return const _StatusConfig(
        label: 'AÇÃO NECESSÁRIA',
        background: AppColors.sand,
        foreground: Color(0xFF946316),
        icon: Icons.notification_important_rounded,
        message: 'Há uma solicitação aguardando sua resposta.',
      );
    default:
      return const _StatusConfig(
        label: 'EM ANÁLISE',
        background: AppColors.sand,
        foreground: Color(0xFF946316),
        icon: Icons.hourglass_top_rounded,
        message:
            'Sua candidatura está em análise pela equipe Porto Prime. Acompanhe aqui qualquer atualização.',
      );
  }
}

class _SmallCounter extends StatelessWidget {
  const _SmallCounter({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) => Container(
        minWidth: 34,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(
            color: AppColors.oceanDeep,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

Future<void> _auth(BuildContext context) async {
  final email = TextEditingController();
  final password = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .52),
    builder: (ctx) => _PrimeSheet(
      children: [
        const _SheetBrandHeader(
          icon: Icons.lock_person_rounded,
          eyebrow: 'ACESSO SEGURO',
          title: 'Bem-vindo de volta',
          subtitle:
              'Entre com os dados da sua conta para continuar na Porto Prime.',
        ),
        const SizedBox(height: 20),
        _PremiumField(
          controller: email,
          label: 'E-mail',
          hint: 'seuemail@exemplo.com',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 11),
        _PremiumField(
          controller: password,
          label: 'Senha',
          hint: 'Sua senha de acesso',
          icon: Icons.key_rounded,
          secret: true,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _passwordRecovery(context);
            },
            icon: const Icon(Icons.help_outline_rounded, size: 17),
            label: const Text('Esqueci minha senha'),
          ),
        ),
        const SizedBox(height: 6),
        _LoginSubmit(
          context: ctx,
          label: 'Entrar na Porto Prime',
          onSubmit: () async {
            await AppState.instance.login(email.text, password.text);
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: AppColors.oceanDeep,
                size: 18,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Sessão protegida e acesso individual. Nunca compartilhe sua senha.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.8,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  email.dispose();
  password.dispose();
}

Future<void> _register(BuildContext context, String role) async {
  await Navigator.of(context).push(_primeRoute(RegistrationPage(role: role)));
}

class _PremiumField extends StatefulWidget {
  const _PremiumField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.secret = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool secret;
  final TextInputType? keyboardType;

  @override
  State<_PremiumField> createState() => _PremiumFieldState();
}

class _PremiumFieldState extends State<_PremiumField> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        obscureText: widget.secret && obscure,
        keyboardType: widget.keyboardType,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: AppColors.canvas,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              width: 41,
              height: 41,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Icon(
                widget.icon,
                color: AppColors.oceanDeep,
                size: 20,
              ),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 62, minHeight: 61),
          suffixIcon: widget.secret
              ? IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(19),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(19),
            borderSide: const BorderSide(color: AppColors.stroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(19),
            borderSide:
                const BorderSide(color: AppColors.ocean, width: 1.5),
          ),
        ),
      );
}

class _LoginSubmit extends StatelessWidget {
  const _LoginSubmit({
    required this.context,
    required this.label,
    required this.onSubmit,
  });

  final BuildContext context;
  final String label;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext _) => AnimatedBuilder(
        animation: AppState.instance,
        builder: (_, __) => Column(
          children: [
            if (AppState.instance.error != null) ...[
              _InlineNotice(
                icon: Icons.error_outline_rounded,
                text: AppState.instance.error!,
                background: AppColors.peach,
                foreground: AppColors.coralStrong,
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: AppState.instance.loading
                    ? null
                    : () async {
                        try {
                          await onSubmit();
                        } catch (_) {}
                      },
                icon: AppState.instance.loading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.login_rounded, size: 20),
                label: AppState.instance.loading
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      );
}

class _PrimeSheet extends StatelessWidget {
  const _PrimeSheet({
    required this.children,
    this.maxHeightFactor = .90,
  });

  final List<Widget> children;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * maxHeightFactor;

    return Container(
      constraints: BoxConstraints(maxHeight: height),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 22 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DEDA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetBrandHeader extends StatelessWidget {
  const _SheetBrandHeader({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.mint, Color(0xFFF4FBF8)],
              ),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: AppColors.mintStrong),
            ),
            child: Icon(icon, color: AppColors.oceanDeep, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: AppColors.ocean,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.55,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: foreground,
                  fontSize: 9.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Account extends StatelessWidget {
  const _Account();

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final user = state.user!;
    final pending = user['status'] == 'PENDING';

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 126),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MINHA PORTO PRIME',
                      style: TextStyle(
                        color: AppColors.ocean,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sua conta',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Tudo o que importa, sem bagunça.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.oceanDeep,
                  size: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AccountHero(user: user),
          if (pending) ...[
            const SizedBox(height: 12),
            const _InlineNotice(
              icon: Icons.hourglass_top_rounded,
              text:
                  'Seu cadastro está em análise. O acesso operacional será liberado após a aprovação administrativa.',
              background: AppColors.sand,
              foreground: Color(0xFF946316),
            ),
          ],
          if (state.isCustomer) ...[
            const SizedBox(height: 27),
            const _SectionLabel(
              eyebrow: 'MINHA EXPERIÊNCIA',
              title: 'Atalhos da sua conta',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.receipt_long_rounded,
                    label: 'Pedidos',
                    subtitle: 'Histórico',
                    onTap: () => _orders(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.location_on_rounded,
                    label: 'Endereços',
                    subtitle: 'Entrega',
                    onTap: () => _addresses(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.support_agent_rounded,
                    label: 'Suporte',
                    subtitle: 'Ajuda',
                    onTap: () => _support(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MenuSurface(
              children: [
                _MenuLine(
                  icon: Icons.receipt_long_rounded,
                  title: 'Meus pedidos',
                  subtitle: 'Acompanhe pedidos ativos e histórico',
                  onTap: () => _orders(context),
                ),
                _MenuLine(
                  icon: Icons.location_on_rounded,
                  title: 'Endereços de entrega',
                  subtitle: 'Gerencie seus locais salvos',
                  onTap: () => _addresses(context),
                ),
                _MenuLine(
                  icon: Icons.support_agent_rounded,
                  title: 'Ajuda e suporte',
                  subtitle: 'Central de atendimento Porto Prime',
                  onTap: () => _support(context),
                  last: true,
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.mint, Color(0xFFF6FBF8)],
              ),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: AppColors.mintStrong),
            ),
            child: const Row(
              children: [
                _MiniIconBox(
                  icon: Icons.bolt_rounded,
                  background: Colors.white,
                  foreground: AppColors.oceanDeep,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrega do seu jeito',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Rápida, gelada e acompanhada em tempo real.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => state.logout(),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('Sair da conta'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({required this.user});
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final role = (user['role'] ?? 'CUSTOMER').toString();

    final roleLabel = role == 'COURIER'
        ? 'MOTOBOY'
        : role == 'PARTNER'
            ? 'PARCEIRO'
            : 'CLIENTE';

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102B27), Color(0xFF075E54)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.oceanDeep.withValues(alpha: .20),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(21),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? 'P' : name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.oceanDeep,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFFFFD889),
                  size: 18,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Conta Porto Prime • Porto Seguro, Bahia',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.shield_rounded,
                  color: Colors.white54,
                  size: 17,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _passwordRecovery(BuildContext context) {
  final email = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .50),
    builder: (ctx) => _PrimeSheet(
      children: [
        const _SheetBrandHeader(
          icon: Icons.lock_reset_rounded,
          eyebrow: 'RECUPERAR ACESSO',
          title: 'Redefina sua senha',
          subtitle:
              'Informe o e-mail cadastrado para iniciar a recuperação da sua conta.',
        ),
        const SizedBox(height: 20),
        _PremiumField(
          controller: email,
          label: 'E-mail da conta',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        _LoginSubmit(
          context: ctx,
          label: 'Continuar recuperação',
          onSubmit: () async {
            final result =
                await AppState.instance.forgotPassword(email.text);
            if (ctx.mounted) {
              Navigator.pop(ctx);
              final message = result['resetToken'] != null
                  ? 'Solicitação criada. Use o token de desenvolvimento para redefinir sua senha.'
                  : 'Se o e-mail estiver cadastrado, enviaremos as instruções.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          },
        ),
      ],
    ),
  ).whenComplete(email.dispose);
}

void _orders(BuildContext context) {
  Navigator.of(context).push(_primeRoute(const OrdersPage()));
}

Route<T> _primeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final fade =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final slide = Tween<Offset>(
          begin: const Offset(.035, 0),
          end: Offset.zero,
        ).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

void _addresses(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .48),
    builder: (sheetContext) => _PrimeSheet(
      maxHeightFactor: .88,
      children: [
        const _SheetBrandHeader(
          icon: Icons.location_on_rounded,
          eyebrow: 'ENTREGA',
          title: 'Seus endereços',
          subtitle: 'Gerencie os locais usados para receber seus pedidos.',
        ),
        const SizedBox(height: 16),
        if (AppState.instance.addresses.isEmpty)
          const _InlineNotice(
            icon: Icons.location_off_rounded,
            text: 'Você ainda não cadastrou nenhum endereço de entrega.',
            background: AppColors.canvas,
            foreground: AppColors.muted,
          )
        else
          ...AppState.instance.addresses.map(
            (address) => Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  const _MiniIconBox(
                    icon: Icons.home_rounded,
                    background: AppColors.mint,
                    foreground: AppColors.oceanDeep,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${address['street'] ?? ''}, ${address['number'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (address['neighborhood'] ?? '').toString(),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () => _newAddress(sheetContext),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text('Adicionar endereço'),
          ),
        ),
      ],
    ),
  );
}

void _newAddress(BuildContext context) {
  final street = TextEditingController();
  final number = TextEditingController();
  final neighborhood = TextEditingController();
  final cep = TextEditingController();

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .48),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppShadows.elevated,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetBrandHeader(
                icon: Icons.add_location_alt_rounded,
                eyebrow: 'NOVO LOCAL',
                title: 'Adicionar endereço',
                subtitle: 'Cadastre um local para receber seus pedidos.',
              ),
              const SizedBox(height: 18),
              _PremiumField(
                controller: street,
                label: 'Rua / avenida',
                icon: Icons.route_rounded,
              ),
              const SizedBox(height: 10),
              _PremiumField(
                controller: number,
                label: 'Número',
                icon: Icons.numbers_rounded,
              ),
              const SizedBox(height: 10),
              _PremiumField(
                controller: neighborhood,
                label: 'Bairro',
                icon: Icons.map_rounded,
              ),
              const SizedBox(height: 10),
              _PremiumField(
                controller: cep,
                label: 'CEP',
                icon: Icons.local_post_office_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    try {
                      await AppState.instance.addAddress({
                        'street': street.text,
                        'number': number.text,
                        'neighborhood': neighborhood.text,
                        'city': 'Porto Seguro',
                        'state': 'BA',
                        'postalCode': cep.text,
                        'isDefault': true,
                      });
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Salvar endereço'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ).whenComplete(() {
    street.dispose();
    number.dispose();
    neighborhood.dispose();
    cep.dispose();
  });
}

void _support(BuildContext context) {
  _simpleMessage(
    context,
    'Central Porto Prime',
    'Precisa de ajuda? Nossa equipe acompanha pedidos, cadastros, pagamentos e entregas. Entre em contato pelos canais oficiais da Porto Prime.',
  );
}

void _simpleMessage(
  BuildContext context,
  String title,
  String message,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .45),
    builder: (ctx) => _PrimeSheet(
      children: [
        _SheetBrandHeader(
          icon: Icons.support_agent_rounded,
          eyebrow: 'PORTO PRIME',
          title: title,
          subtitle: message,
        ),
        const SizedBox(height: 16),
        const _InlineNotice(
          icon: Icons.verified_user_rounded,
          text:
              'Use sempre os canais oficiais para proteger seus dados e sua conta.',
          background: AppColors.mint,
          foreground: AppColors.oceanDeep,
        ),
      ],
    ),
  );
}
