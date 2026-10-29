import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class CourierPreflightPage extends StatefulWidget {
  const CourierPreflightPage({
    super.key,
    required this.onClose,
    required this.onReady,
  });

  final VoidCallback onClose;
  final VoidCallback onReady;

  @override
  State<CourierPreflightPage> createState() => _CourierPreflightPageState();
}

class _CourierPreflightPageState extends State<CourierPreflightPage> {
  static const _accent = Color(0xFFF0A93A);
  static const _accentSoft = Color(0xFFFFF1D5);
  static const _pfUrl =
      'https://www.gov.br/pf/pt-br/assuntos/antecedentes-criminais';

  static const _items = <({String title, String detail, IconData icon})>[
    (
      title: 'CPF em mãos',
      detail: 'Documento pronto para validação na primeira etapa.',
      icon: AppIcons.badge_outlined,
    ),
    (
      title: 'CNH válida',
      detail: 'Número de registro, categoria e validade disponíveis.',
      icon: AppIcons.credit_card_outlined,
    ),
    (
      title: 'Dados do veículo',
      detail: 'Marca, modelo, ano e placa do veículo de entrega.',
      icon: AppIcons.two_wheeler_outlined,
    ),
    (
      title: 'Preciso emitir uma nova certidão',
      detail: 'Use esta opção se você ainda não tem uma certidão válida.',
      icon: AppIcons.shield_outlined,
    ),
    (
      title: 'Celular, WhatsApp e e-mail',
      detail: 'Tenha acesso aos canais usados durante a análise.',
      icon: AppIcons.phone_outlined,
    ),
  ];

  final Set<int> _checked = <int>{};
  bool _hasRecentCertificate = false;

  bool get _certificateReady =>
      _checked.contains(3) || _hasRecentCertificate;

  int get _completedCount {
    var total = 0;
    if (_checked.contains(0)) total++;
    if (_checked.contains(1)) total++;
    if (_checked.contains(2)) total++;
    if (_certificateReady) total++;
    if (_checked.contains(4)) total++;
    return total;
  }

  bool get _ready => _completedCount == 5;
  double get _progress => _completedCount / 5;

  Future<void> _openFederalCertificate() async {
    final uri = Uri.parse(_pfUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o site da Polícia Federal agora.'),
        ),
      );
    }
  }

  void _toggleAll() {
    setState(() {
      if (_ready) {
        _checked.clear();
        _hasRecentCertificate = false;
        return;
      }
      _hasRecentCertificate = false;
      _checked
        ..clear()
        ..addAll(const [0, 1, 2, 3, 4]);
    });
  }

  void _toggle(int index) {
    if (index == 3 && _hasRecentCertificate) return;
    setState(() {
      if (!_checked.add(index)) _checked.remove(index);
    });
  }

  Future<void> _confirmRecentCertificate() async {
    if (_hasRecentCertificate) {
      setState(() => _hasRecentCertificate = false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.ocean900.withValues(alpha: .66),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppShadows.floating,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentSoft, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _accent.withValues(alpha: .22),
                  ),
                ),
                child: const Icon(
                  AppIcons.shield_rounded,
                  color: Color(0xFF9A6419),
                  size: 31,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sua certidão ainda está válida?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.04,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Confirme somente se a certidão oficial da Polícia Federal foi emitida há menos de 90 dias.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      AppIcons.info_outline_rounded,
                      color: AppColors.ocean700,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Se estiver vencida, tiver 90 dias ou mais, ou você não souber a data de emissão, escolha emitir uma nova certidão.',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    'Sim, foi emitida há menos de 90 dias',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'Não tenho certeza',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _hasRecentCertificate = true;
        _checked.remove(3);
      });
    }
  }

  Future<void> _showScreenshotChecklist() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ocean900.withValues(alpha: .58),
      builder: (sheetContext) => SafeArea(
        child: Container(
          height: MediaQuery.sizeOf(sheetContext).height * .9,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppShadows.floating,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.strokeStrong,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.ocean900,
                              AppColors.ocean700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PORTO PRIME • CHECKLIST',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.ocean300,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tudo pronto para\nseu cadastro.',
                              style: TextStyle(
                                fontSize: 28,
                                height: 1.02,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tire um print desta tela e use como lembrete.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFD6E7E3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _printItem(
                        AppIcons.badge_outlined,
                        'CPF',
                        'Documento pronto para validação.',
                      ),
                      _printItem(
                        AppIcons.credit_card_outlined,
                        'CNH válida',
                        'Registro, categoria e validade.',
                      ),
                      _printItem(
                        AppIcons.two_wheeler_outlined,
                        'Dados do veículo',
                        'Marca, modelo, ano e placa.',
                      ),
                      _printItem(
                        AppIcons.shield_outlined,
                        'Antecedentes criminais',
                        'Certidão oficial em PDF, válida por até 90 dias.',
                      ),
                      _printItem(
                        AppIcons.phone_outlined,
                        'Contato disponível',
                        'Celular, WhatsApp e e-mail acessíveis.',
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'PORTO PRIME • CADASTRO DE MOTOBOY',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: AppColors.subtle,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(AppIcons.close_rounded, size: 18),
                    label: const Text(
                      'Fechar checklist',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _printItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF9A6419), size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 9.8,
                    height: 1.4,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            AppIcons.check_circle_rounded,
            color: AppColors.ocean700,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _progressHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.ocean900,
            AppColors.ocean800,
            AppColors.ocean700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.elevated,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -42,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .055),
              ),
            ),
          ),
          Positioned(
            right: 38,
            bottom: -64,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: .11),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .12),
                      ),
                    ),
                    child: const Text(
                      'PREPARAÇÃO INTELIGENTE',
                      style: TextStyle(
                        color: AppColors.ocean300,
                        fontSize: 8,
                        letterSpacing: .95,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .09),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .13),
                      ),
                    ),
                    child: Text(
                      '$_completedCount/5',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Chegue pronto.\nCadastre uma vez.',
                style: TextStyle(
                  fontSize: 31,
                  height: 1.01,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.15,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Organize tudo antes de começar e evite interromper sua candidatura no meio do caminho.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: Color(0xFFD5E5E1),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: .12),
                  valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    _ready
                        ? 'Tudo pronto para começar'
                        : '$_completedCount de 5 itens confirmados',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: _ready ? AppColors.ocean300 : Colors.white70,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (_ready)
                    const Icon(
                      AppIcons.check_circle_rounded,
                      color: AppColors.ocean300,
                      size: 18,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _standardCard({
    required int index,
    required String order,
  }) {
    final item = _items[index];
    final selected = _checked.contains(index);
    final disabled = index == 3 && _hasRecentCertificate;

    return AnimatedOpacity(
      duration: AppMotion.standard,
      opacity: disabled ? .42 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => _toggle(index),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: AppMotion.standard,
            curve: AppMotion.curve,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceOcean : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? AppColors.ocean300
                    : AppColors.stroke,
                width: selected ? 1.3 : 1,
              ),
              boxShadow: selected ? AppShadows.soft : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.standard,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.ocean100
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item.icon,
                        color: selected
                            ? AppColors.ocean700
                            : const Color(0xFF9A6419),
                        size: 22,
                      ),
                    ),
                    Positioned(
                      left: -4,
                      top: -5,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.ocean800
                              : AppColors.ink,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          order,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disabled
                            ? 'Nova certidão não necessária'
                            : item.title,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        disabled
                            ? 'Você confirmou uma certidão emitida há menos de 90 dias.'
                            : item.detail,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.43,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: AppMotion.standard,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.ocean800
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.ocean800
                          : AppColors.strokeStrong,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          AppIcons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : disabled
                          ? const Icon(
                              AppIcons.close_rounded,
                              color: AppColors.subtle,
                              size: 15,
                            )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _certificateChoice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBF3), Color(0xFFFFF5E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _accent.withValues(alpha: .22),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _accent.withValues(alpha: .18),
                  ),
                ),
                child: const Icon(
                  AppIcons.shield_rounded,
                  color: Color(0xFF9A6419),
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Já possui uma certidão válida?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Você pode usar uma certidão emitida há menos de 90 dias.',
                      style: TextStyle(
                        fontSize: 9.7,
                        height: 1.4,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Material(
            color: _hasRecentCertificate
                ? AppColors.ocean800
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: _confirmRecentCertificate,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _hasRecentCertificate
                        ? AppColors.ocean800
                        : _accent.withValues(alpha: .26),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasRecentCertificate
                          ? AppIcons.check_circle_rounded
                          : AppIcons.shield_outlined,
                      color: _hasRecentCertificate
                          ? Colors.white
                          : const Color(0xFF9A6419),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _hasRecentCertificate
                            ? 'Certidão válida confirmada'
                            : 'Já tenho uma certidão com menos de 90 dias',
                        style: TextStyle(
                          color: _hasRecentCertificate
                              ? Colors.white
                              : AppColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(
                      AppIcons.chevron_right_rounded,
                      size: 18,
                      color: _hasRecentCertificate
                          ? Colors.white
                          : AppColors.muted,
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

  Widget _certificateTools() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOcean,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ocean100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.verified_user_rounded,
                color: AppColors.ocean700,
                size: 21,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Central da certidão',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'OFICIAL',
                  style: TextStyle(
                    fontSize: 7.5,
                    color: AppColors.ocean700,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .75,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Se precisar, emita pelo portal oficial da Polícia Federal ou abra o checklist compacto para tirar um print.',
            style: TextStyle(
              fontSize: 10,
              height: 1.45,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _hasRecentCertificate
                  ? null
                  : _openFederalCertificate,
              icon: const Icon(AppIcons.externalLink, size: 17),
              label: Text(
                _hasRecentCertificate
                    ? 'Certidão válida já confirmada'
                    : 'Emitir certidão oficial',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showScreenshotChecklist,
              icon: const Icon(AppIcons.fact_check_rounded, size: 17),
              label: const Text(
                'Abrir versão para print',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: IconButton(
                      tooltip: 'Fechar',
                      onPressed: widget.onClose,
                      icon: const Icon(AppIcons.close_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accentSoft,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      AppIcons.two_wheeler_rounded,
                      color: Color(0xFF9A6419),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cadastro de motoboy',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: -.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'PREPARAÇÃO • ANTES DO CPF',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .85,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _progressHero(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'O que você precisa',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                  letterSpacing: -.3,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Confirme os itens que já estão prontos.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _toggleAll,
                          icon: Icon(
                            _ready
                                ? AppIcons.close_rounded
                                : AppIcons.check_circle_rounded,
                            size: 17,
                          ),
                          label: Text(
                            _ready ? 'Desmarcar' : 'Marcar todos',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _standardCard(index: 0, order: '01'),
                    const SizedBox(height: 10),
                    _standardCard(index: 1, order: '02'),
                    const SizedBox(height: 10),
                    _standardCard(index: 2, order: '03'),
                    const SizedBox(height: 10),
                    _standardCard(index: 3, order: '04'),
                    const SizedBox(height: 10),
                    _certificateChoice(),
                    const SizedBox(height: 10),
                    _standardCard(index: 4, order: '05'),
                    const SizedBox(height: 16),
                    _certificateTools(),
                    const SizedBox(height: 14),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          AppIcons.info_outline_rounded,
                          color: AppColors.subtle,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Marcar um item significa apenas que você está com ele em mãos. A candidatura ainda passa pela análise da equipe Porto Prime.',
                            style: TextStyle(
                              fontSize: 9.3,
                              height: 1.45,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ocean900.withValues(alpha: .06),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: AnimatedContainer(
                  duration: AppMotion.standard,
                  width: double.infinity,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: _ready
                        ? const LinearGradient(
                            colors: [
                              AppColors.ocean900,
                              AppColors.ocean700,
                            ],
                          )
                        : null,
                    color: _ready ? null : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _ready ? AppShadows.soft : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _ready ? widget.onReady : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _ready
                                    ? Colors.white.withValues(alpha: .12)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                _ready
                                    ? AppIcons.arrow_forward_rounded
                                    : AppIcons.fact_check_rounded,
                                color: _ready
                                    ? Colors.white
                                    : AppColors.subtle,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _ready
                                        ? 'Começar meu cadastro'
                                        : '$_completedCount de 5 itens prontos',
                                    style: TextStyle(
                                      color: _ready
                                          ? Colors.white
                                          : AppColors.subtle,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _ready
                                        ? 'Tudo conferido. Vamos para o CPF.'
                                        : 'Confirme todos os itens para avançar.',
                                    style: TextStyle(
                                      color: _ready
                                          ? Colors.white70
                                          : AppColors.subtle,
                                      fontSize: 8.8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_ready)
                              const Icon(
                                AppIcons.chevron_right_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
