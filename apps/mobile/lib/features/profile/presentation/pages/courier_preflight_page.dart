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

  Widget _checkRow(int index) {
    final item = _items[index];
    return CheckboxListTile(
      value: _checked.contains(index),
      onChanged: (_) => _toggle(index),
      controlAffinity: ListTileControlAffinity.trailing,
      activeColor: const Color(0xFF073E43),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(item.detail, style: const TextStyle(fontSize: 13, height: 1.4)),
      ),
    );
  }

  Widget _certificateSection() {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: const Text('Certidão de antecedentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(_hasRecentCertificate ? 'Certidão válida confirmada' : _checked.contains(3) ? 'Emissão de nova certidão selecionada' : 'Escolha uma opção', style: const TextStyle(fontSize: 13)),
      ),
      leading: Icon(_certificateReady ? Icons.check_circle : Icons.description_outlined,
        color: _certificateReady ? const Color(0xFF073E43) : AppColors.muted),
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _hasRecentCertificate,
          onChanged: (_) => _confirmRecentCertificate(),
          title: const Text('Já tenho uma certidão válida'),
          subtitle: const Text('Emitida há menos de 90 dias.'),
          activeColor: const Color(0xFF073E43),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _checked.contains(3),
          onChanged: _hasRecentCertificate ? null : (_) => _toggle(3),
          title: const Text('Preciso emitir uma nova'),
          activeColor: const Color(0xFF073E43),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _hasRecentCertificate ? null : _openFederalCertificate,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Abrir site da Polícia Federal'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(onPressed: widget.onClose, tooltip: 'Fechar', icon: const Icon(Icons.close)),
        title: const Text('Cadastro de motoboy', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                const Text('Vamos começar', style: TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w700, color: Color(0xFF073E43))),
                const SizedBox(height: 10),
                const Text('Separe os documentos e confirme os itens abaixo.', style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted)),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  children: [
                    Text('$_completedCount de 5 prontos', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF073E43))),
                    TextButton(onPressed: _toggleAll, child: Text(_ready ? 'Desmarcar todos' : 'Marcar todos')),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: _progress, minHeight: 4, color: const Color(0xFF073E43), backgroundColor: const Color(0xFFE1EAEA)),
                ),
                const SizedBox(height: 16),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFDCE6E6))),
                  child: Column(children: [
                    _checkRow(0),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _checkRow(1),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _checkRow(2),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _certificateSection(),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _checkRow(4),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('Seus documentos serão conferidos pela nossa equipe após o cadastro.', style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted)),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF073E43),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _ready ? widget.onReady : null,
                  child: const Text('Começar cadastro', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _showScreenshotChecklist, child: const Text('Checklist para salvar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
