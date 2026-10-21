import 'dart:ui';
import 'package:flutter/material.dart';
import '../localization/prime_localization.dart';

/// Guest account landing only; every action is supplied by ProfilePage.
class TropicalAccountWelcome extends StatelessWidget {
  const TropicalAccountWelcome({super.key, required this.onCreate, required this.onLogin,
    required this.onSupport, required this.onPartnership, required this.onPrivacy});
  final VoidCallback onCreate, onLogin, onSupport, onPartnership, onPrivacy;
  static const ink = Color(0xFF102B44);
  static const background = 'assets/reference_home/account-coast.webp';

  @override
  Widget build(BuildContext context) => ColoredBox(color: const Color(0xFF06364D),
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(background, fit: BoxFit.cover, alignment: Alignment.topCenter,
          excludeFromSemantics: true, errorBuilder: (_, error, stack) => const ColoredBox(color: Color(0xFF07566D))),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xB7002848), Color(0x5000324D), Color(0x08003A49)],
          stops: [0, .50, 1]))),
        SafeArea(bottom: false, child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const PrimeText('BEM-VINDO(A) AO PORTO PRIME', style: TextStyle(color: Color(0xFFCEE9F3),
              fontSize: 9, letterSpacing: 1.3, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, box) {
              final roomy = box.maxWidth >= 330 && MediaQuery.textScalerOf(context).scale(14) <= 18;
              return Stack(children: [
                Padding(padding: EdgeInsets.only(right: roomy ? 76 : 0),
                  child: const PrimeText('Seu próximo\npedido começa\ncom você.', style: TextStyle(
                    color: Colors.white, fontSize: 28, height: 1.02, letterSpacing: -1.1,
                    fontWeight: FontWeight.w800, shadows: [Shadow(color: Color(0x40002542), blurRadius: 12)]))),
                if (roomy) const Positioned(right: 0, bottom: 1, child: _DestinationSignature()),
              ]);
            }),
            const SizedBox(height: 13),
            const FractionallySizedBox(widthFactor: .85, alignment: Alignment.centerLeft,
              child: PrimeText('Crie sua conta para pedir, acompanhar a entrega e usar todos os benefícios do Porto Prime.',
                style: TextStyle(color: Color(0xFFEBF7FC), fontSize: 11.5, height: 1.4))),
            const SizedBox(height: 14),
            const _Benefits(),
            const SizedBox(height: 13),
            _AccessButton(label: 'Criar minha conta', icon: Icons.person_add_alt_1_rounded,
              onTap: onCreate, primary: true),
            const SizedBox(height: 10),
            _AccessButton(label: 'Entrar na minha conta', icon: Icons.login_rounded,
              onTap: onLogin, primary: false),
            const SizedBox(height: 13),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFFDAF4FF), size: 14),
              SizedBox(width: 6), Flexible(child: PrimeText('Uma conta. Tudo organizado e seguro.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFEBF7FC), fontSize: 10, height: 1.4))),
            ]),
            const SizedBox(height: 13),
            Container(padding: const EdgeInsets.fromLTRB(17, 15, 17, 8),
              decoration: BoxDecoration(color: const Color(0xF7FCFDFF), borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xCCFFFFFF), width: 1.2),
                boxShadow: const [BoxShadow(color: Color(0x34002B45), blurRadius: 26, offset: Offset(0, 9))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const PrimeText('ESTAMOS POR PERTO', style: TextStyle(color: Color(0xFF6B829B),
                  fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                const PrimeText('Precisa de ajuda?', style: TextStyle(color: ink, fontSize: 19,
                  height: 1.2, letterSpacing: -.6, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _HelpAction(title: 'Ajuda e suporte', subtitle: 'Fale com a equipe Porto Prime',
                  icon: Icons.chat_bubble_rounded, color: const Color(0xFF00AE70), onTap: onSupport),
                const Divider(height: 1, color: Color(0xFFE6EDF2), indent: 45),
                _HelpAction(title: 'Parcerias e patrocínios', subtitle: 'Conte sua ideia para a Porto Prime',
                  icon: Icons.handshake_rounded, color: const Color(0xFFFF7950), onTap: onPartnership),
                const Divider(height: 1, color: Color(0xFFE6EDF2), indent: 45),
                _HelpAction(title: 'Privacidade e segurança', subtitle: 'Cuidamos dos seus dados com carinho',
                  icon: Icons.shield_rounded, color: const Color(0xFF8F5AE8), onTap: onPrivacy),
              ])),
          ]))),
      ]))));
}

class _DestinationSignature extends StatelessWidget {
  const _DestinationSignature();
  @override Widget build(BuildContext context) => SizedBox(width: 78,
    child: Column(children: [
      const Icon(Icons.wb_sunny_rounded, size: 18, color: Color(0xFFFFD548)),
      Transform.rotate(angle: -.13, child: const Text('Porto\nSeguro', textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'DMSerifDisplay', fontStyle: FontStyle.italic,
          fontSize: 24, height: .78, color: Color(0xFF32D0FF), shadows: [Shadow(color: Color(0xFF063653), blurRadius: 5)]))),
      const SizedBox(height: 10),
      const PrimeText('Muito mais que um destino.', textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFFFE499), fontSize: 7.5, height: 1.25, fontStyle: FontStyle.italic)),
    ]));
}

class _Benefits extends StatelessWidget {
  const _Benefits();
  @override Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final gap = box.maxWidth < 330 ? 7.0 : 9.0;
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Expanded(child: _Benefit(icon: Icons.shopping_bag_rounded, color: Color(0xFFFFC266),
        title: 'Seus pedidos', subtitle: 'Acompanhe tudo em tempo real')),
      SizedBox(width: gap),
      const Expanded(child: _Benefit(icon: Icons.location_on_rounded, color: Color(0xFF4DE89B),
        title: 'Seus endereços', subtitle: 'Gerencie seus endereços')),
      SizedBox(width: gap),
      const Expanded(child: _Benefit(icon: Icons.account_balance_wallet_rounded, color: Color(0xFF42D4FA),
        title: 'Seu saldo', subtitle: 'Cupons, créditos e benefícios')),
    ]));
  });
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.color, required this.title, required this.subtitle});
  final IconData icon;
  final Color color;
  final String title, subtitle;
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xA60A3549), borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x5FFFFFFF), width: 1)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 28, height: 28, alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(11),
              gradient: RadialGradient(colors: [color.withValues(alpha: .38), color.withValues(alpha: .03)])),
            child: Icon(icon, color: color, size: 27, shadows: const [Shadow(color: Color(0x60001422), blurRadius: 8, offset: Offset(0, 3))])),
          const SizedBox(height: 6),
          PrimeText(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white,
            fontSize: 10.5, height: 1.25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          PrimeText(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD4E8EE), fontSize: 9, height: 1.35)),
        ]))));
}

class _AccessButton extends StatelessWidget {
  const _AccessButton({required this.label, required this.icon, required this.onTap, required this.primary});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  @override Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), boxShadow: [
      BoxShadow(color: primary ? const Color(0x55FFC72C) : const Color(0x33002641), blurRadius: 17, offset: const Offset(0, 5))]),
    child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(19), clipBehavior: Clip.antiAlias,
      child: Ink(decoration: BoxDecoration(borderRadius: BorderRadius.circular(19),
        gradient: LinearGradient(colors: primary ? const [Color(0xFFFFE471), Color(0xFFFFC72C)] : const [Colors.white, Color(0xFFF0F6FF)]),
        border: Border.all(color: primary ? const Color(0xFFFFE174) : const Color(0xFFDAE6EE))),
        child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
          child: Row(children: [Icon(icon, color: TropicalAccountWelcome.ink, size: 22),
            const SizedBox(width: 9), Expanded(child: PrimeText(label, textAlign: TextAlign.center,
              style: const TextStyle(color: TropicalAccountWelcome.ink, fontSize: 14, height: 1.2, fontWeight: FontWeight.w800))),
            const SizedBox(width: 9), const Icon(Icons.arrow_forward_rounded, color: TropicalAccountWelcome.ink, size: 20),
          ]))))));
}

class _HelpAction extends StatelessWidget {
  const _HelpAction({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => Material(color: Colors.transparent,
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [
        Container(width: 33, height: 33, alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PrimeText(title, style: const TextStyle(color: TropicalAccountWelcome.ink, fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3), PrimeText(subtitle, style: const TextStyle(color: Color(0xFF72869A), fontSize: 9.5, height: 1.35)),
        ])),
        const SizedBox(width: 6), const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF7791A4)),
      ]))));
}
