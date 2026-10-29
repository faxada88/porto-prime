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
  static const _pfUrl =
      'https://www.gov.br/pf/pt-br/assuntos/antecedentes-criminais';

  static const _items = <({String title, String detail, IconData icon})>[
    (
      title: 'CPF em mãos',
      detail: 'Você vai informar e validar o CPF logo na primeira etapa.',
      icon: AppIcons.badge_outlined,
    ),
    (
      title: 'CNH válida',
      detail: 'Tenha número, categoria e validade da habilitação.',
      icon: AppIcons.credit_card_outlined,
    ),
    (
      title: 'Dados do veículo',
      detail: 'Marca, modelo, ano e placa usados nas entregas.',
      icon: AppIcons.two_wheeler_outlined,
    ),
    (
      title: 'Preciso emitir uma nova certidão',
      detail:
          'Use esta opção se você ainda não tem uma certidão válida da Polícia Federal.',
      icon: AppIcons.shield_outlined,
    ),
    (
      title: 'Celular, WhatsApp e e-mail disponíveis',
      detail:
          'Você receberá avisos sobre análise, pendências e aprovação do cadastro.',
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

  Future<void> _openFederalCertificate() async {
    final uri = Uri.parse(_pfUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o site da Polícia Federal agora.',
          ),
        ),
      );
    }
  }

  Future<void> _showScreenshotChecklist() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          height: MediaQuery.sizeOf(ctx).height * .88,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: const Text(
                          'CHECKLIST PARA PRINT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Color(0xFFB77818),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Cadastro de\nmotoboy Porto Prime',
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tire uma captura desta tela e use como lembrete antes de iniciar seu cadastro.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _printItem(
                        AppIcons.badge_outlined,
                        'CPF',
                        'Documento e número do CPF.',
                      ),
                      _printItem(
                        AppIcons.credit_card_outlined,
                        'CNH válida',
                        'Número de registro, categoria e validade.',
                      ),
                      _printItem(
                        AppIcons.two_wheeler_outlined,
                        'Dados do veículo',
                        'Marca, modelo, ano e placa do veículo usado nas entregas.',
                      ),
                      _printItem(
                        AppIcons.shield_outlined,
                        'Antecedentes criminais',
                        'Emita uma nova certidão ou use uma já emitida há menos de 90 dias.',
                      ),
                      _printItem(
                        AppIcons.phone_outlined,
                        'Celular, WhatsApp e e-mail',
                        'Tenha acesso aos canais usados durante a análise do cadastro.',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.mintStrong),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              AppIcons.info_outline_rounded,
                              color: AppColors.oceanDeep,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Quando estiver com todos os itens prontos, volte ao Porto Prime e marque o checklist para liberar o formulário de cadastro.',
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.45,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Center(
                        child: Text(
                          'PORTO PRIME • CADASTRO DE MOTOBOY',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(AppIcons.close_rounded, size: 18),
                  label: const Text(
                    'Fechar checklist',
                    style: TextStyle(fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFB77818),
              size: 20,
            ),
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
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 9.7,
                    height: 1.4,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            AppIcons.check_rounded,
            color: AppColors.oceanDeep,
            size: 18,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRecentCertificate() async {
    if (_hasRecentCertificate) {
      setState(() => _hasRecentCertificate = false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .45),
      builder: (d) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  AppIcons.shield_rounded,
                  color: Color(0xFFB77818),
                  size: 31,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sua certidão ainda está válida?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Confirme somente se a certidão de antecedentes criminais da Polícia Federal foi emitida há menos de 90 dias.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: const Text(
                  'Se ela tiver 90 dias ou mais, estiver vencida ou você não souber a data de emissão, escolha emitir uma nova certidão.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.pop(d, true),
                  child: const Text(
                    'Sim, foi emitida há menos de 90 dias',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(d, false),
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
      if (!_checked.add(index)) {
        _checked.remove(index);
      }
    });
  }

  Widget _checkCard({
    required IconData icon,
    required String title,
    required String detail,
    required bool selected,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    const accent = Color(0xFFB77818);
    return Opacity(
      opacity: disabled ? .48 : 1,
      child: Material(
        color: selected ? AppColors.mint : AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? AppColors.mintStrong : AppColors.stroke,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : AppColors.sand,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.oceanDeep : accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 9.8,
                          height: 1.42,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.oceanDeep : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          selected ? AppColors.oceanDeep : AppColors.stroke,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          AppIcons.check_rounded,
                          size: 17,
                          color: Colors.white,
                        )
                      : disabled
                          ? const Icon(
                              AppIcons.close_rounded,
                              size: 15,
                              color: AppColors.muted,
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

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB77818);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.stroke),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: widget.onClose,
                      icon: const Icon(AppIcons.close_rounded),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        AppIcons.two_wheeler_rounded,
                        color: accent,
                        size: 22,
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
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.25,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'PREPARAÇÃO • ANTES DO CPF',
                            style: TextStyle(
                              fontSize: 8.5,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .75,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.sand, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: accent.withValues(alpha: .15),
                        ),
                      ),
                      child: const Icon(
                        AppIcons.fact_check_rounded,
                        color: accent,
                        size: 29,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Prepare tudo.\nCadastre uma vez.',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.02,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Confirme o que você já tem em mãos. Se faltar algo, abra o checklist para print e volte quando estiver pronto.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.55,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.stroke),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Documentos necessários',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                  ),
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
                                  _ready ? 'Desmarcar todos' : 'Marcar todos',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (var index = 0; index < _items.length; index++) ...[
                            _checkCard(
                              icon: _items[index].icon,
                              title: _items[index].title,
                              detail: index == 3 && _hasRecentCertificate
                                  ? 'Desativado porque você confirmou que já possui uma certidão válida.'
                                  : _items[index].detail,
                              selected: _checked.contains(index),
                              disabled:
                                  index == 3 && _hasRecentCertificate,
                              onTap: index == 3 && _hasRecentCertificate
                                  ? null
                                  : () => _toggle(index),
                            ),
                            if (index == 3) ...[
                              const SizedBox(height: 10),
                              _checkCard(
                                icon: AppIcons.verified_user_rounded,
                                title:
                                    'Já tenho uma certidão emitida há menos de 90 dias',
                                detail: _hasRecentCertificate
                                    ? 'Confirmado. Você não precisa emitir uma nova certidão agora.'
                                    : 'Marque somente se você já possui a certidão oficial dentro do prazo de 90 dias.',
                                selected: _hasRecentCertificate,
                                onTap: _confirmRecentCertificate,
                              ),
                            ],
                            if (index != _items.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                AppIcons.shield_rounded,
                                color: accent,
                                size: 21,
                              ),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Ainda não tem uma certidão válida?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Você pode emitir gratuitamente pela Polícia Federal, baixar o PDF e depois voltar para continuar.',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.45,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _hasRecentCertificate
                                  ? null
                                  : _openFederalCertificate,
                              icon: const Icon(
                                AppIcons.externalLink,
                                size: 17,
                              ),
                              label: Text(
                                _hasRecentCertificate
                                    ? 'Certidão válida já confirmada'
                                    : 'Emitir certidão oficial',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showScreenshotChecklist,
                              icon: const Icon(
                                AppIcons.fact_check_rounded,
                                size: 17,
                              ),
                              label: const Text(
                                'Abrir checklist para print',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          AppIcons.info_outline_rounded,
                          color: AppColors.muted,
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A confirmação da certidão serve para preparar o cadastro. O documento ainda poderá ser conferido pela equipe Porto Prime durante a análise.',
                            style: TextStyle(
                              fontSize: 9.5,
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: _ready ? widget.onReady : null,
                    icon: Icon(
                      _ready
                          ? AppIcons.arrow_forward_rounded
                          : AppIcons.fact_check_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _ready
                          ? 'Tenho tudo. Começar cadastro'
                          : '$_completedCount de 5 itens prontos',
                      style: const TextStyle(fontWeight: FontWeight.w900),
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
