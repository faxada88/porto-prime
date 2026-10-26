import '../localization/prime_localization.dart';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'courier_portrait.dart';
import 'prime_brand.dart';

/// Scrollable app-owned sheets; native camera/gallery remain managed by image_picker.
class PrimeIdentitySheet extends StatelessWidget {
  const PrimeIdentitySheet({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final available = (MediaQuery.sizeOf(context).height - keyboard - MediaQuery.viewPaddingOf(context).top - MediaQuery.paddingOf(context).bottom).clamp(0.0, MediaQuery.sizeOf(context).height).toDouble();
    return AnimatedPadding(duration: AppMotion.resolve(context, AppMotion.fast),
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(top: false, child: Center(heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 560, maxHeight: available * .96),
          child: Container(padding: const EdgeInsets.fromLTRB(22,12,22,24),
            decoration: const BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Center(child: Container(width: 38, height: 4,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(color: AppColors.strokeStrong, borderRadius: BorderRadius.circular(8)))),
                  ...children]),
            )),
        )),
      ),
    );
  }
}

class PrimeLoginIntro extends StatelessWidget {
  const PrimeLoginIntro({super.key, required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Column(children: [
    ClipRRect(borderRadius: BorderRadius.circular(22), child: Stack(children: [
      Positioned.fill(child: Image.asset('assets/reference_home/account-coast.webp',
        fit: BoxFit.cover, alignment: Alignment.topRight, cacheWidth: 900,
        excludeFromSemantics: true)),
      Container(width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xF5FFFFFF), Color(0xA6FFFFFF), Color(0x22FFFFFF)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Expanded(child: Text('PORTO PRIME', style: TextStyle(
            color: Color(0xFF00656C), fontSize: 19, fontWeight: FontWeight.w800))),
            IconButton(tooltip: translateLabel('Fechar entrada'), onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Color(0xFF073E43)))]),
          const SizedBox(height: 24),
          const PrimeText('Seu próximo pedido começa com você.', style: TextStyle(
            fontSize: 29, height: 1.1, letterSpacing: -.8,
            fontWeight: FontWeight.w800, color: Color(0xFF073E43))),
          const SizedBox(height: 12),
          const PrimeText('Crie sua conta para pedir, acompanhar a entrega e usar todos os benefícios do Porto Prime.',
            style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF657787))),
        ])),
    ])),
    const SizedBox(height: 24),
    const Icon(Icons.workspace_premium_rounded, size: 38, color: Color(0xFFFFBB32)),
    const SizedBox(height: 14),
    const PrimeText('Bom ter você\naqui de novo.', textAlign: TextAlign.center,
      style: TextStyle(fontSize: 30, height: 1.12, letterSpacing: -.9,
        fontWeight: FontWeight.w800, color: Color(0xFF073E43))),
    const SizedBox(height: 12),
    const PrimeText('Entre com seu e-mail e senha para continuar de onde parou.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF778596))),
  ]);
}

class PrimePhotoSource extends StatelessWidget {
  const PrimePhotoSource({super.key, required this.onCamera, required this.onGallery, required this.onClose});
  final VoidCallback onCamera, onGallery, onClose;
  @override
  Widget build(BuildContext context) => PrimeIdentitySheet(children: [
    Row(children: [const Expanded(child: PrimeText('Sua foto. Sua identidade.', style: TextStyle(
      fontSize: 24, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -.5, color: AppColors.ocean900))),
      IconButton(tooltip: translateLabel( 'Fechar opções de foto'), onPressed: onClose, icon: const Icon(AppIcons.close))]),
    const SizedBox(height: 10),
    const PrimeText('Mostre seu rosto com clareza. Essa imagem ajuda o cliente a reconhecer quem fará a entrega.',
      style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.muted)),
    const SizedBox(height: 24),
    _PhotoOption(icon: AppIcons.camera, title: 'Tirar uma selfie',
      subtitle: 'Usar a câmera do dispositivo', onTap: onCamera, primary: true),
    const SizedBox(height: 12),
    _PhotoOption(icon: AppIcons.image, title: 'Escolher da galeria',
      subtitle: 'Selecionar uma foto que você já tem', onTap: onGallery),
    const SizedBox(height: 20),
    const PrimeText('Boa iluminação, rosto descoberto e sem outras pessoas na imagem.',
      style: TextStyle(fontSize: 11, height: 1.5, color: AppColors.muted)),
  ]);
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({required this.icon, required this.title, required this.subtitle,
    required this.onTap, this.primary = false});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) => Material(color: primary ? AppColors.ocean900 : AppColors.surfaceSoft,
    borderRadius: BorderRadius.circular(20), clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 26, color: primary ? AppColors.sun500 : AppColors.ocean700),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PrimeText(title, style: TextStyle(fontSize: 15, height: 1.3, fontWeight: FontWeight.w800,
            color: primary ? Colors.white : AppColors.ocean900)), const SizedBox(height: 6),
          PrimeText(subtitle, style: TextStyle(fontSize: 12, height: 1.5,
            color: primary ? AppColors.ocean100 : AppColors.muted)),
        ])),
        const SizedBox(width: 8), Icon(AppIcons.arrowUpRight, size: 18,
          color: primary ? AppColors.sun500 : AppColors.ocean700),
      ])),
    ));
}

class PrimePhotoReview extends StatelessWidget {
  const PrimePhotoReview({super.key, required this.photo, required this.onRetake, required this.onUse});
  final String photo;
  final VoidCallback onRetake, onUse;
  @override
  Widget build(BuildContext context) => Dialog(insetPadding: const EdgeInsets.all(20),
    backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 440,
      maxHeight: MediaQuery.sizeOf(context).height * .84),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PrimeText('É assim que vão\nreconhecer você.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, height: 1.2, letterSpacing: -.6,
              fontWeight: FontWeight.w800, color: AppColors.ocean900)),
          const SizedBox(height: 24),
          Center(child: CourierPortrait(photo: photo, size: 150)),
          const SizedBox(height: 24),
          const PrimeText('Confira se o rosto está nítido e bem enquadrado. O cliente verá esta foto na entrega.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.muted)),
          const SizedBox(height: 24),
          FilledButton(onPressed: onUse, style: FilledButton.styleFrom(backgroundColor: AppColors.ocean900,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17)),
            child: const PrimeText('Salvar foto', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800))),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetake, style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
            child: const PrimeText('Escolher outra', textAlign: TextAlign.center)),
        ])),
    ));
}

class PrimePhotoProfileCard extends StatelessWidget {
  const PrimePhotoProfileCard({super.key, required this.photo, required this.registration,
    required this.saving, required this.onChoose});
  final String? photo;
  final bool registration, saving;
  final VoidCallback onChoose;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surfaceOcean, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: photo == null ? AppColors.sun200 : AppColors.stroke)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 16, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.center, children: [
        CourierPortrait(photo: photo, size: 72),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: photo == null ? AppColors.sand100 : AppColors.ocean100,
            borderRadius: BorderRadius.circular(20)),
          child: PrimeText(photo == null ? 'FOTO DO PERFIL' : 'FOTO SELECIONADA',
            style: const TextStyle(fontSize: 10, height: 1.5, fontWeight: FontWeight.w800, color: AppColors.ocean900))),
      ]),
      const SizedBox(height: 18),
      PrimeText(photo == null ? 'Seu rosto transmite confiança.' : 'Seu rosto, sua entrega.',
        style: const TextStyle(fontSize: 19, height: 1.25, letterSpacing: -.4,
          fontWeight: FontWeight.w800, color: AppColors.ocean900)),
      const SizedBox(height: 9),
      PrimeText(photo == null ? (registration ? 'Adicione sua foto para concluir o cadastro.' : 'Adicione sua foto para aparecer ao cliente.')
        : 'Esta é a imagem que o cliente verá na entrega.',
        style: const TextStyle(fontSize: 12, height: 1.6, color: AppColors.muted)),
      const SizedBox(height: 18),
      FilledButton(onPressed: saving ? null : onChoose,
        style: FilledButton.styleFrom(backgroundColor: AppColors.ocean900,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (saving) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          else const Icon(AppIcons.camera, size: 19), const SizedBox(width: 10),
          Flexible(child: PrimeText(saving ? 'Preparando foto…' : photo == null ? 'Adicionar minha foto' : 'Alterar foto',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
        ])),
    ]));
}
