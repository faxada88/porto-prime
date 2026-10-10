import '../../../addresses/presentation/pages/address_book_page.dart';
import '../../../wallet/presentation/pages/partner_wallet_page.dart';
import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';
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
        child: PrimePageViewport(child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 126),
          children: [
            const _ProfileHeader(),
            const SizedBox(height: 24),
            _GuestAccessHero(
              onLogin: () => _auth(context),
              onCreate: () => _accountMenu(context),
            ),
            const SizedBox(height: 14),
            _ApplicationShortcut(
              onTap: () => _courierStatus(context),
            ),
            const SizedBox(height: 24),
            const _SectionLabel(
              eyebrow: 'ESTAMOS POR AQUI',
              title: 'Como podemos ajudar?',
              subtitle: 'Suporte e informações para você pedir com tranquilidade.',
            ),
            const SizedBox(height: 12),
            _MenuSurface(
              children: [
                _MenuLine(
                  icon: AppIcons.support_agent_rounded,
                  title: 'Ajuda e suporte',
                  subtitle: 'Fale com a equipe Porto Prime',
                  onTap: () => _support(context),
                ),
                _MenuLine(
                  icon: AppIcons.shield_rounded,
                  title: 'Privacidade e segurança',
                  subtitle: 'Como protegemos sua conta e seus dados',
                  onTap: () => _simpleMessage(
                    context,
                    'Privacidade e segurança',
                    'Seus dados são usados somente nos fluxos necessários para sua conta, pedidos, pagamentos e entregas.',
                  ),
                  last: true,
                ),
              ],
            ),
          ],
        )),
      );
}

class _GuestAccessHero extends StatelessWidget {
  const _GuestAccessHero({required this.onLogin, required this.onCreate});

  final VoidCallback onLogin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceOcean,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.person_rounded,
                  color: AppColors.primaryDark, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Tudo seu, em um só lugar.',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            const Text(
              'Entre para acompanhar seus pedidos e cuidar da sua conta. Ainda não tem cadastro? Comece por aqui.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: AppFontSize.body,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onLogin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: const Text('Entrar na minha conta'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCreate,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: const Text('Criar uma conta'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppColors.stroke),
            const SizedBox(height: 18),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.shield_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Seus dados protegidos. Seu próximo pedido mais perto.',
                      style: TextStyle(color: AppColors.muted,
                          fontSize: AppFontSize.caption, height: 1.5)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PORTO PRIME',
              style: TextStyle(color: AppColors.primary,
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.display, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text('Seu espaço', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Sua conta. Suas escolhas. Tudo por perto.',
              style: TextStyle(color: AppColors.muted,
                  fontSize: AppFontSize.body, height: 1.5)),
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
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Ink(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
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
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .10),
                              ),
                            ),
                            child: const Icon(
                              AppIcons.person_rounded,
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
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppIcons.lock_rounded,
                                  size: 12,
                                  color: Color(0xFFFFD889),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'ACESSO SEGURO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppFontSize.caption,
                                    fontWeight: AppFontWeight.display,
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
                          fontWeight: AppFontWeight.display,
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
                                fontSize: AppFontSize.caption,
                                height: 1.4,
                                fontWeight: AppFontWeight.medium,
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
                              AppIcons.arrow_forward_rounded,
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 126),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: AppColors.oceanDeep, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.display,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.muted,
                    fontWeight: AppFontWeight.medium,
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
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.display,
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
              fontWeight: AppFontWeight.display,
              letterSpacing: -.45,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: AppFontSize.caption,
                height: 1.45,
                fontWeight: AppFontWeight.medium,
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
                                fontWeight: AppFontWeight.display,
                                letterSpacing: -.2,
                              ),
                            ),
                          ),
                          Text(
                            badge,
                            style: const TextStyle(
                              fontSize: AppFontSize.caption,
                              color: AppColors.muted,
                              fontWeight: AppFontWeight.display,
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
                          fontSize: AppFontSize.caption,
                          height: 1.4,
                          fontWeight: AppFontWeight.medium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  AppIcons.arrow_forward_ios_rounded,
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.stroke),
            ),
            child: const Row(
              children: [
                _MiniIconBox(
                  icon: AppIcons.manage_search_rounded,
                  background: Colors.white,
                  foreground: AppColors.primaryDark,
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
                          fontWeight: AppFontWeight.display,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Consulte o status e responda pendências pelo CPF.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: AppFontSize.caption,
                          height: 1.35,
                          fontWeight: AppFontWeight.medium,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  AppIcons.arrow_forward_rounded,
                  color: AppColors.primaryDark,
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
          borderRadius: BorderRadius.circular(AppRadius.sm),
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
                fontWeight: AppFontWeight.display,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  color: AppColors.muted,
                  fontWeight: AppFontWeight.medium,
                ),
              ),
            ),
            trailing: const Icon(
              AppIcons.chevron_right_rounded,
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Row(
          children: [
            _MiniIconBox(
              icon: AppIcons.wb_sunny_rounded,
              background: Colors.white,
              foreground: AppColors.sun,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Feito em Porto Seguro para praia, festa, descanso e aquele brinde que não pode esperar.',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  height: 1.45,
                  fontWeight: AppFontWeight.strong,
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
          icon: AppIcons.person_rounded,
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
            icon: const Icon(AppIcons.login_rounded, size: 20),
            label: const Text(
              'Entrar na minha conta',
              style: TextStyle(fontWeight: AppFontWeight.display),
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
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.display,
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
          icon: AppIcons.shopping_bag_rounded,
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
          icon: AppIcons.two_wheeler_rounded,
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
          icon: AppIcons.storefront_rounded,
          accent: AppColors.violet600,
          background: AppColors.lavender,
          onTap: () {
            Navigator.pop(ctx);
            _register(context, 'PARTNER');
          },
        ),
        const SizedBox(height: 14),
        Material(
          color: AppColors.sand50,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () {
              Navigator.pop(ctx);
              _courierStatus(context);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.sun200),
              ),
              child: const Row(
                children: [
                  _MiniIconBox(
                    icon: AppIcons.fact_check_rounded,
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
                            fontWeight: AppFontWeight.display,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Consulte pelo CPF e responda solicitações do Admin.',
                          style: TextStyle(
                            color: Color(0xFF866A3E),
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    AppIcons.arrow_forward_rounded,
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
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
                          fontWeight: AppFontWeight.display,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: AppFontSize.caption,
                          height: 1.35,
                          fontWeight: AppFontWeight.medium,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  AppIcons.chevron_right_rounded,
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
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.elevated,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MiniIconBox(
                      icon: AppIcons.edit_note_rounded,
                      background: AppColors.sand,
                      foreground: Color(0xFF9B6817),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      (requirement['title'] ?? 'Pendência').toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.08,
                        fontWeight: AppFontWeight.display,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      (requirement['description'] ?? '').toString(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: AppFontSize.caption,
                        height: 1.45,
                        fontWeight: AppFontWeight.medium,
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
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
                  content: Text(PrimeMessages.friendly(e)),
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
              icon: AppIcons.manage_search_rounded,
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
              icon: AppIcons.badge_rounded,
              keyboardType: TextInputType.number,
            ),
            if (error != null) ...[
              const SizedBox(height: 2),
              _InlineNotice(
                icon: AppIcons.error_outline_rounded,
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      AppIcons.privacy_tip_rounded,
                      color: AppColors.oceanDeep,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A consulta é protegida pelo CPF informado na candidatura. Nenhum login é necessário nesta etapa.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: AppFontSize.caption,
                          height: 1.45,
                          fontWeight: AppFontWeight.medium,
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
                  icon: AppIcons.verified_rounded,
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
                            ? AppIcons.search_rounded
                            : AppIcons.refresh_rounded,
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
                        style: const TextStyle(fontWeight: AppFontWeight.display),
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
    final access = application['userStatus']?.toString();
    final raw = access == 'BLOCKED' ? 'REJECTED' : access == 'SUSPENDED' ? 'SUSPENDED' : access == 'PENDING' ? 'PENDING' : (application['approvalStatus'] ?? 'PENDING').toString();
    final config = _statusConfig(raw);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.background, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
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
                        fontWeight: AppFontWeight.display,
                        letterSpacing: -.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (application['document'] ?? 'CPF confirmado').toString(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.medium,
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
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(config.icon, color: config.foreground, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    config.message,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      height: 1.4,
                      fontWeight: AppFontWeight.strong,
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
        color: open ? AppColors.sand50 : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: open ? AppColors.sun200 : AppColors.stroke,
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
                    ? AppIcons.notification_important_rounded
                    : answered
                        ? AppIcons.mark_chat_read_rounded
                        : AppIcons.verified_rounded,
                background: open ? AppColors.sand : AppColors.mint,
                foreground:
                    open ? AppColors.warning : AppColors.oceanDeep,
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
                        fontWeight: AppFontWeight.display,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (requirement['description'] ?? '').toString(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: AppFontSize.caption,
                        height: 1.45,
                        fontWeight: AppFontWeight.medium,
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
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SUA RESPOSTA',
                    style: TextStyle(
                      color: AppColors.oceanDeep,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.display,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    requirement['response'].toString(),
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      height: 1.4,
                      fontWeight: AppFontWeight.strong,
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
                icon: const Icon(AppIcons.reply_rounded, size: 18),
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.foreground,
          fontSize: AppFontSize.caption,
          fontWeight: AppFontWeight.display,
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
        icon: AppIcons.verified_rounded,
        message:
            'Cadastro aprovado. Seu acesso operacional está liberado conforme as regras da plataforma.',
      );
    case 'REJECTED':
    case 'BLOCKED':
      return const _StatusConfig(
        label: 'NÃO APROVADO',
        background: AppColors.peach,
        foreground: AppColors.coralStrong,
        icon: AppIcons.cancel_rounded,
        message:
            'A candidatura não foi aprovada. Consulte as orientações recebidas antes de uma nova solicitação.',
      );
    case 'SUSPENDED':
      return const _StatusConfig(
        label: 'SUSPENSO',
        background: AppColors.lavender,
        foreground: Color(0xFF66569B),
        icon: AppIcons.pause_circle_rounded,
        message:
            'O acesso está temporariamente suspenso. Entre em contato com o suporte para mais informações.',
      );
    case 'ANSWERED':
      return const _StatusConfig(
        label: 'RESPONDIDA',
        background: AppColors.sky,
        foreground: Color(0xFF356D8D),
        icon: AppIcons.mark_chat_read_rounded,
        message: 'Sua resposta foi enviada e está aguardando revisão.',
      );
    case 'RESOLVED':
      return const _StatusConfig(
        label: 'RESOLVIDA',
        background: AppColors.mint,
        foreground: AppColors.oceanDeep,
        icon: AppIcons.task_alt_rounded,
        message: 'A solicitação foi resolvida.',
      );
    case 'OPEN':
      return const _StatusConfig(
        label: 'AÇÃO NECESSÁRIA',
        background: AppColors.sand,
        foreground: Color(0xFF946316),
        icon: AppIcons.notification_important_rounded,
        message: 'Há uma solicitação aguardando sua resposta.',
      );
    default:
      return const _StatusConfig(
        label: 'EM ANÁLISE',
        background: AppColors.sand,
        foreground: Color(0xFF946316),
        icon: AppIcons.hourglass_top_rounded,
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
        constraints: const BoxConstraints(minWidth: 34),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(
            color: AppColors.oceanDeep,
            fontSize: 11,
            fontWeight: AppFontWeight.display,
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
          icon: AppIcons.lock_person_rounded,
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
          icon: AppIcons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 11),
        _PremiumField(
          controller: password,
          label: 'Senha',
          hint: 'Sua senha de acesso',
          icon: AppIcons.key_rounded,
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
            icon: const Icon(AppIcons.help_outline_rounded, size: 17),
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
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Row(
            children: [
              Icon(
                AppIcons.shield_rounded,
                color: AppColors.oceanDeep,
                size: 18,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Sessão protegida e acesso individual. Nunca compartilhe sua senha.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: AppFontSize.caption,
                    height: 1.4,
                    fontWeight: AppFontWeight.medium,
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
          fontWeight: AppFontWeight.strong,
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
                borderRadius: BorderRadius.circular(AppRadius.sm),
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
                        ? AppIcons.visibility_rounded
                        : AppIcons.visibility_off_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.stroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
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
                icon: AppIcons.error_outline_rounded,
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
                    : const Icon(AppIcons.login_rounded, size: 20),
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
                        style: const TextStyle(fontWeight: AppFontWeight.display),
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
                    color: AppColors.strokeStrong,
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.display,
                    letterSpacing: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.05,
                    fontWeight: AppFontWeight.display,
                    letterSpacing: -.55,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: AppFontSize.caption,
                    height: 1.4,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(AppIcons.close_rounded),
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
          borderRadius: BorderRadius.circular(AppRadius.sm),
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
                  fontSize: AppFontSize.caption,
                  height: 1.4,
                  fontWeight: AppFontWeight.strong,
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
      child: PrimePageViewport(child: ListView(
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
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.display,
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
                        fontWeight: AppFontWeight.medium,
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
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: const Icon(
                  AppIcons.notifications_active_rounded,
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
              icon: AppIcons.hourglass_top_rounded,
              text:
                  'Seu cadastro está em análise. O acesso operacional será liberado após a aprovação administrativa.',
              background: AppColors.sand,
              foreground: Color(0xFF946316),
            ),
          ],
          if (state.isPartner && !pending) ...[
            const SizedBox(height: 20),
            _MenuSurface(children: [
              _MenuLine(icon: AppIcons.wallet, title: 'Carteira e saques', subtitle: 'Saldo, movimentações e repasses', last:true,
                onTap:()=>Navigator.of(context).push(_primeRoute(const PartnerWalletPage()))),
            ]),
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
                    icon: AppIcons.receipt_long_rounded,
                    label: 'Pedidos',
                    subtitle: 'Histórico',
                    onTap: () => _orders(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: AppIcons.location_on_rounded,
                    label: 'Endereços',
                    subtitle: 'Entrega',
                    onTap: () => _addresses(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: AppIcons.support_agent_rounded,
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
                  icon: AppIcons.receipt_long_rounded,
                  title: 'Meus pedidos',
                  subtitle: 'Acompanhe pedidos ativos e histórico',
                  onTap: () => _orders(context),
                ),
                _MenuLine(
                  icon: AppIcons.location_on_rounded,
                  title: 'Endereços de entrega',
                  subtitle: 'Gerencie seus locais salvos',
                  onTap: () => _addresses(context),
                ),
                _MenuLine(
                  icon: AppIcons.support_agent_rounded,
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
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.mintStrong),
            ),
            child: const Row(
              children: [
                _MiniIconBox(
                  icon: AppIcons.bolt_rounded,
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
                          fontWeight: AppFontWeight.display,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Rápida, gelada e acompanhada em tempo real.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.medium,
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
              icon: const Icon(AppIcons.logout_rounded, size: 19),
              label: const Text('Sair da conta'),
            ),
          ),
        ],
      )),
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? 'P' : name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.oceanDeep,
                    fontSize: 25,
                    fontWeight: AppFontWeight.display,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: AppFontWeight.display,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(alignment: Alignment.centerRight, child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.display,
                    letterSpacing: .8,
                  ),
                ),
              )),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Row(
              children: [
                Icon(
                  AppIcons.verified_user_rounded,
                  color: Color(0xFFFFD889),
                  size: 18,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Conta Porto Prime • Porto Seguro, Bahia',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.strong,
                    ),
                  ),
                ),
                Icon(
                  AppIcons.shield_rounded,
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
          icon: AppIcons.lock_reset_rounded,
          eyebrow: 'RECUPERAR ACESSO',
          title: 'Redefina sua senha',
          subtitle:
              'Informe o e-mail cadastrado para iniciar a recuperação da sua conta.',
        ),
        const SizedBox(height: 20),
        _PremiumField(
          controller: email,
          label: 'E-mail da conta',
          icon: AppIcons.alternate_email_rounded,
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
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressBookPage()));
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
          icon: AppIcons.support_agent_rounded,
          eyebrow: 'PORTO PRIME',
          title: title,
          subtitle: message,
        ),
        const SizedBox(height: 16),
        const _InlineNotice(
          icon: AppIcons.verified_user_rounded,
          text:
              'Use sempre os canais oficiais para proteger seus dados e sua conta.',
          background: AppColors.mint,
          foreground: AppColors.oceanDeep,
        ),
      ],
    ),
  );
}
