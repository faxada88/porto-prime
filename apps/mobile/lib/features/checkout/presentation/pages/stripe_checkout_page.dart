import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'stripe_web_element_stub.dart'
    if (dart.library.js_interop) 'stripe_web_element_web.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';

class StripeCheckoutPage extends StatefulWidget {
  const StripeCheckoutPage({
    super.key,
    required this.clientSecret,
    required this.publishableKey,
    required this.orderId,
  });

  final String clientSecret;
  final String publishableKey;
  final String orderId;

  @override
  State<StripeCheckoutPage> createState() => _StripeCheckoutPageState();
}

class _StripeCheckoutPageState extends State<StripeCheckoutPage> {
  bool ready = false;
  bool paying = false;
  String? error;
  Timer? _webPaymentPoll;
  bool _finishingPayment = false;

  @override
  void initState() {
    super.initState();
    _configure();
    if (kIsWeb) {
      _webPaymentPoll = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _checkWebPayment(),
      );
    }
  }

  Future<void> _configure() async {
    try {
      Stripe.publishableKey = widget.publishableKey;
      await Stripe.instance.applySettings();

      if (!kIsWeb) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: widget.clientSecret,
            merchantDisplayName: 'Porto Prime',
            style: ThemeMode.light,
            appearance: const PaymentSheetAppearance(),
          ),
        );
      }

      if (mounted) setState(() => ready = true);
    } catch (e) {
      if (mounted) setState(() => error = _message(e));
    }
  }

  Future<void> _checkWebPayment() async {
    if (!mounted || paying) return;
    try {
      final paid = await AppState.instance.refreshPayment(widget.orderId);
      if (paid && mounted) {
        _webPaymentPoll?.cancel();
        await _finishPaidPayment();
      }
    } catch (_) {
      // Keep the Stripe form usable while the webhook is still settling.
    }
  }

  @override
  void dispose() {
    _webPaymentPoll?.cancel();
    super.dispose();
  }

  String _message(Object e) {
    if (e is StripeException) {
      return e.error.localizedMessage ??
          'Não foi possível iniciar o pagamento.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _pay() async {
    if (paying || !ready) return;
    setState(() {
      paying = true;
      error = null;
    });

    try {
      if (kIsWeb) {
        // On web the official Stripe.js Payment Element owns confirmation.
        // Flutter polls the webhook-backed order state below.
      } else {
        await Stripe.instance.presentPaymentSheet();
      }

      final paid = await AppState.instance.refreshPayment(widget.orderId);
      if (!mounted) return;

      if (paid) {
        await _finishPaidPayment();
      } else {
        setState(() {
          paying = false;
          error = 'Pagamento enviado ao Stripe. A confirmação está sendo processada.';
        });
      }
    } on StripeException catch (e) {
      if (!mounted) return;
      final canceled = e.error.code == FailureCode.Canceled;
      setState(() {
        paying = false;
        error = canceled
            ? null
            : (e.error.localizedMessage ?? 'Pagamento não concluído.');
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          paying = false;
          error = _message(e);
        });
      }
    }
  }

  Future<void> _finishPaidPayment() async {
    if (_finishingPayment || !mounted) return;
    _finishingPayment = true;
    _webPaymentPoll?.cancel();
    await Future.wait([
      AppState.instance.loadOrders(),
      AppState.instance.loadActiveOrder(),
    ]);
    if (!mounted) return;

    dynamic order;
    for (final item in AppState.instance.orders) {
      if (item['id'].toString() == widget.orderId) {
        order = item;
        break;
      }
    }
    final total = double.tryParse((order?['total'] ?? 0).toString()) ?? 0;
    final shortId = widget.orderId.length > 8
        ? widget.orderId.substring(0, 8).toUpperCase()
        : widget.orderId.toUpperCase();

    final track = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TweenAnimationBuilder<double>(
        tween: Tween(begin: .82, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE3DF),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                const SizedBox(height: 25),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.oceanDeep.withValues(alpha: .16),
                            blurRadius: 34,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.oceanDeep,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.check_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Pagamento aprovado!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.9,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Recebemos a confirmação do Stripe. Seu pedido já entrou no fluxo da Porto Prime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF102D28), Color(0xFF08786D)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        AppIcons.storefront_rounded,
                        color: Color(0xFF8CFFE4),
                        size: 25,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedido recebido',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Agora a distribuidora confirma os itens e prepara a liberação para entrega.',
                              style: TextStyle(
                                color: Color(0xFFD4ECE7),
                                fontSize: 9.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PaidInfo(
                        icon: AppIcons.credit_card_rounded,
                        label: 'VALOR PAGO',
                        value:
                            'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _PaidInfo(
                        icon: AppIcons.receipt_long_rounded,
                        label: 'PEDIDO',
                        value: '#$shortId',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.oceanDeep,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(AppIcons.route_rounded),
                    label: const Text(
                      'Acompanhar meu pedido',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: const Text(
                    'Voltar para a loja',
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
      ),
    );

    if (mounted) Navigator.pop(context, track == true ? 'track' : 'shop');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: paying ? null : () => Navigator.pop(context, false),
          icon: const Icon(AppIcons.close_rounded),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagamento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              'Processado com segurança pelo Stripe',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(
              AppIcons.lock_rounded,
              color: AppColors.oceanDeep,
              size: 20,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: const Color(0xFFE5EAE7)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            AppIcons.verified_user_rounded,
                            color: AppColors.oceanDeep,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Checkout seguro',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Escolha a forma de pagamento e preencha os dados no formulário oficial do Stripe.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (kIsWeb)
                        StripeWebElement(
                          publishableKey: widget.publishableKey,
                          clientSecret: widget.clientSecret,
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                AppIcons.credit_card_rounded,
                                color: AppColors.oceanDeep,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Toque abaixo para abrir o PaymentSheet oficial do Stripe.',
                                  style: TextStyle(
                                    fontSize: 11,
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
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (!kIsWeb) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.oceanDeep,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: !ready || paying ? null : _pay,
                      icon: paying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(AppIcons.lock_rounded, size: 18),
                      label: Text(
                        paying ? 'Processando...' : 'Abrir Stripe',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
                if (!ready && error == null) ...[
                  const SizedBox(height: 14),
                  const Center(child: CircularProgressIndicator()),
                ],
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.shield_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Dados sensíveis tratados diretamente pelo Stripe',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaidInfo extends StatelessWidget {
  const _PaidInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: const Color(0xFFE7ECE8)),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.oceanDeep, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 7.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
