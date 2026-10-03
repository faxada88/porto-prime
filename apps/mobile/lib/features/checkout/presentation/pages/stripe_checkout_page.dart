import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'stripe_web_element_stub.dart' if (dart.library.js_interop) 'stripe_web_element_web.dart';
import '../../../../core/state/app_state.dart';
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

  @override
  void initState() {
    super.initState();
    _configure();
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

  String _message(Object e) {
    if (e is StripeException) {
      return e.error.localizedMessage ?? 'Não foi possível iniciar o pagamento.';
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
        Navigator.pop(context, true);
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
        error = canceled ? null : (e.error.localizedMessage ?? 'Pagamento não concluído.');
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
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pagamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text('Processado com segurança pelo Stripe', style: TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(Icons.lock_rounded, color: AppColors.oceanDeep, size: 20),
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
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFE5EAE7)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0D000000), blurRadius: 24, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: AppColors.oceanDeep, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Checkout seguro',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Escolha a forma de pagamento e preencha os dados no formulário oficial do Stripe.',
                        style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.45),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.credit_card_rounded, color: AppColors.oceanDeep),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Toque abaixo para abrir o PaymentSheet oficial do Stripe.',
                                  style: TextStyle(fontSize: 11, height: 1.4, fontWeight: FontWeight.w700),
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
                    decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(16)),
                    child: Text(error!, style: const TextStyle(fontSize: 10, height: 1.4, fontWeight: FontWeight.w700)),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.oceanDeep,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: kIsWeb || !ready || paying ? null : _pay,
                    icon: paying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.lock_rounded, size: 18),
                    label: Text(
                      paying ? 'Processando...' : (kIsWeb ? 'Pagamento protegido pelo Stripe' : 'Abrir Stripe'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                if (!ready && error == null) ...[
                  const SizedBox(height: 14),
                  const Center(child: CircularProgressIndicator()),
                ],
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: AppColors.muted),
                    SizedBox(width: 5),
                    Text(
                      'Dados sensíveis tratados diretamente pelo Stripe',
                      style: TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w600),
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
