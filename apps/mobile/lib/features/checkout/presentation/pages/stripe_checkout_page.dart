import '../widgets/prime_payment_experience.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'stripe_web_element_stub.dart'
    if (dart.library.js_interop) 'stripe_web_element_web.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

class StripeCheckoutPage extends StatefulWidget {
  const StripeCheckoutPage({
    super.key,
    required this.clientSecret,
    required this.publishableKey,
    required this.orderId,
    this.summary,
    this.creditOnly=false,
  });

  final bool creditOnly;
  final String clientSecret;
  final String publishableKey;
  final String orderId;
  final Map<String,dynamic>? summary;

  @override
  State<StripeCheckoutPage> createState() => _StripeCheckoutPageState();
}

class _StripeCheckoutPageState extends State<StripeCheckoutPage> with WidgetsBindingObserver {
  bool _browserOpened=false;
  bool ready = false;
  bool paying = false;
  String? error;
  Timer? _webPaymentPoll;
  bool _finishingPayment = false;
  bool _checkingPayment = false;
  bool _paymentSubmitted = false;
  DateTime? _checkStarted;
  bool _leaving=false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configure();
  }

  Future<void> _configure() async {
    try {
      // Recover a successful previous attempt without asking the customer to pay again.
      Map<String, dynamic>? verification;
      try { verification = await AppState.instance.checkPaymentStatus(widget.orderId); } catch (_) {}
      final alreadyPaid = verification?['paid'] == true;
      if (!mounted) return;
      if (alreadyPaid) {
        await _finishPaidPayment();
        return;
      }

      if (verification?['status'] == 'processing') {
        _startPaymentCheck();
        return;
      }
      if(widget.creditOnly){setState(()=>ready=true);return;}
      if(kIsWeb){Stripe.publishableKey = widget.publishableKey;await Stripe.instance.applySettings();}

      // All enabled methods use the official Payment Element; native apps open
      // a signed page in the browser so Pix and boleto are available as well.
      if (mounted) setState(() => ready = true);
    } catch (e) {
      if (mounted) setState(() => error = _message(e));
    }
  }

  void _onWebPaymentState(String status) {
    if (!mounted) return;
    if (status == 'submitting') {
      setState(() { paying = true; error = null; });
    } else if (status == 'error') {
      setState(() => paying = false);
    } else if (status == 'succeeded' || status == 'processing') {
      _startPaymentCheck();
    }
  }

  void _startPaymentCheck() {
    if (!mounted || _finishingPayment) return;
    _webPaymentPoll?.cancel();
    _checkStarted = DateTime.now();
    setState(() { _paymentSubmitted = true; paying = true; error = null; });
    _webPaymentPoll = Timer.periodic(const Duration(seconds: 3), (_) => _checkWebPayment());
    _checkWebPayment();
  }

  Future<void> _checkWebPayment() async {
    if (!mounted || _checkingPayment || _finishingPayment) return;
    _checkingPayment = true;
    try {
      final paid = await AppState.instance.refreshPayment(widget.orderId);
      if (!mounted) return;
      if (paid) {
        _webPaymentPoll?.cancel();
        await _finishPaidPayment();
      } else if (DateTime.now().difference(_checkStarted ?? DateTime.now()).inSeconds >= 90) {
        _webPaymentPoll?.cancel();
        setState(() {
          paying = false;
          error = 'O pagamento ainda não foi confirmado. Se gerou Pix ou boleto, conclua o pagamento e verifique novamente. Não pague duas vezes.';
        });
      }
    } catch (_) {
      if (mounted) {
        _webPaymentPoll?.cancel();
        _finishingPayment = false;
        setState(() {
          paying = false;
          error = 'Não foi possível atualizar seu pedido agora. Verifique novamente; não é necessário pagar outra vez.';
        });
      }
    } finally {
      _checkingPayment = false;
    }
  }

  @override
  void dispose() {
    _webPaymentPoll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(state==AppLifecycleState.resumed&&_browserOpened&&!_finishingPayment)_startPaymentCheck();
  }

  String _message(Object e) {
    if (e is StripeException) {
      return e.error.localizedMessage ??
          'Não foi possível iniciar o pagamento.';
    }
    return PrimeMessages.friendly(e);
  }

  Future<void> _pay() async {
    if (paying || !ready) return;
    setState(() {
      paying = true;
      error = null;
    });

    try {
      if(widget.creditOnly){
        await AppState.instance.api.request('POST','/payments/confirm-credit',body:{'orderId':widget.orderId});
      }else if (kIsWeb) {
        // On web the official Stripe.js Payment Element owns confirmation.
        // The server verifies Stripe before the order is treated as paid.
      } else {
        final result=Map<String,dynamic>.from(await AppState.instance.api.request(
          'POST','/payments/secure-checkout',body:{'orderId':widget.orderId}));
        if(result['paid']==true){if(mounted)await _finishPaidPayment();return;}
        final url=Uri.tryParse((result['url']??'').toString());
        if(url==null||!['http','https'].contains(url.scheme)||url.path!='/api/payments/secure')throw Exception('Não foi possível abrir o pagamento seguro.');
        _browserOpened=true;
        final opened=await launchUrl(url,mode:LaunchMode.externalApplication);
        if(!opened){_browserOpened=false;throw Exception('Não foi possível abrir o navegador. Tente novamente.');}
      }

      if (mounted) _startPaymentCheck();
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
                    fontWeight: AppFontWeight.display,
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
                    fontWeight: AppFontWeight.strong,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.midnight, AppColors.ocean700],
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
                                fontWeight: AppFontWeight.display,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Agora a distribuidora confirma os itens e prepara a liberação para entrega.',
                              style: TextStyle(
                                color: Color(0xFFD4ECE7),
                                fontSize: AppFontSize.caption,
                                height: 1.4,
                                fontWeight: AppFontWeight.medium,
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
                        fontWeight: AppFontWeight.display,
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
                      fontWeight: AppFontWeight.display,
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

  Future<void> _leave({bool home=false}) async {
    if(_leaving||!mounted)return;
    _leaving=true;
    try {
      if(paying||_paymentSubmitted){
        final leave=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Sair do pagamento?'),content:const Text('A confirmação pode continuar mesmo após você sair. Consulte o pedido antes de tentar pagar novamente. Seu pedido fica disponível em Pedidos.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Continuar aqui')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Sair e consultar depois'))]));
        if(leave!=true||!mounted)return;
      }
      if(mounted)Navigator.of(context).pop(home?'home':'back');
    }finally{_leaving=false;}
  }
  @override
  Widget build(BuildContext context) => PopScope<String>(
    canPop:false,
    onPopInvokedWithResult:(didPop,result){if(!didPop)_leave();},
    child:PrimePaymentExperience(
      summary:widget.summary??<String,dynamic>{},creditOnly:widget.creditOnly,
      web:kIsWeb,ready:ready,paying:paying,submitted:_paymentSubmitted,
      testMode:widget.publishableKey.startsWith('pk_test_'),error:error,
      onBack:()=>_leave(),onHome:()=>_leave(home:true),onPay:_pay,
      onVerify:_startPaymentCheck,onRetry:_configure,
      onReopen:!kIsWeb&&!widget.creditOnly?_pay:null,
      paymentElement:ready&&kIsWeb&&!widget.creditOnly&&!_paymentSubmitted
        ?StripeWebElement(publishableKey:widget.publishableKey,clientSecret:widget.clientSecret,onPaymentState:_onWebPaymentState)
        :null,
    ),
  );
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
                  fontSize: AppFontSize.caption,
                  color: AppColors.muted,
                  fontWeight: AppFontWeight.display,
                  letterSpacing: .7,
                ),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.display,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

