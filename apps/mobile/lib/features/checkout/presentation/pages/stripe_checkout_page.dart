import '../widgets/checkout_progress.dart';
import 'dart:async';

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

class _StripeCheckoutPageState extends State<StripeCheckoutPage> {
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
          error = 'O Stripe ainda está processando o pagamento. Você pode verificar novamente sem pagar outra vez.';
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
    super.dispose();
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
        await Stripe.instance.presentPaymentSheet();
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
  Widget build(BuildContext context) {
    final summary=widget.summary??<String,dynamic>{};
    final address=summary['address'] is Map?Map<String,dynamic>.from(summary['address'] as Map):<String,dynamic>{};
    final credit=double.tryParse('${summary['storeCreditUsed']}')??0;
    final distance=summary['distanceKm']??summary['routeDistanceKm'];
    final duration=summary['durationMinutes']??summary['routeDurationMinutes'];
    return PopScope<String>(canPop:false,onPopInvokedWithResult:(didPop,result){if(!didPop)_leave();},child:Scaffold(
      backgroundColor:AppColors.canvas,
      appBar:AppBar(backgroundColor:Colors.white,surfaceTintColor:Colors.white,leading:IconButton(tooltip:'Voltar à entrega e revisão',onPressed:()=>_leave(),icon:const Icon(AppIcons.arrowLeft)),title:const Text('Pagamento seguro',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800)),actions:[IconButton(tooltip:'Voltar ao início',onPressed:()=>_leave(home:true),icon:const Icon(AppIcons.home))]),
      body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:620),child:ListView(padding:const EdgeInsets.fromLTRB(22,14,22,30),children:[
        const CheckoutProgress(step:2),const SizedBox(height:26),
        Container(padding:const EdgeInsets.all(23),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.ocean900,AppColors.ocean700]),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[Icon(AppIcons.lock,color:AppColors.ocean300,size:18),SizedBox(width:9),Text('ÚLTIMO PASSO',style:TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.7))]),const SizedBox(height:14),
          Text(summary['total']==null?'Finalize sua compra':checkoutMoney(widget.creditOnly?summary['storeCreditUsed']:summary['total']),style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.w800,letterSpacing:-1)),const SizedBox(height:6),
          Text(widget.creditOnly?'Produtos e entrega pagos com seu saldo.':'Tudo pronto. Escolha como pagar.',style:TextStyle(color:Colors.white70,fontSize:14,height:1.5)),
        ])),const SizedBox(height:16),
        if(address.isNotEmpty)Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.stroke)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(AppIcons.mapPin,color:AppColors.ocean700,size:21),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${address['label']??'Endereço de entrega'}',style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:5),Text('${address['street']}, ${address['number']}',style:const TextStyle(fontSize:13,height:1.5)),if(distance!=null&&duration!=null)Text('$distance km por rota · aproximadamente $duration min',style:const TextStyle(fontSize:11,color:AppColors.muted,height:1.5))])),TextButton(onPressed:()=>_leave(),child:const Text('Revisar'))])),
        if(summary['total']!=null)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:ExpansionTile(tilePadding:const EdgeInsets.symmetric(horizontal:4),childrenPadding:const EdgeInsets.fromLTRB(4,0,4,16),title:const Text('Resumo da compra',style:TextStyle(fontSize:14,fontWeight:FontWeight.w800)),subtitle:const Text('Produtos, entrega e saldo utilizado',style:TextStyle(fontSize:11,color:AppColors.muted)),children:[
          ...((summary['items'] as List?)??[]).map((raw){final item=Map<String,dynamic>.from(raw as Map);return CheckoutPriceLine(label:'${item['quantity']}× ${item['productName']}',value:checkoutMoney(item['total']));}),
          const Divider(),CheckoutPriceLine(label:'Produtos',value:checkoutMoney(summary['subtotal'])),CheckoutPriceLine(label:'Entrega',value:checkoutMoney(summary['deliveryFee'])),if(credit>0)CheckoutPriceLine(label:'Saldo Porto Prime',value:'−${checkoutMoney(credit)}'),CheckoutPriceLine(label:'Total a pagar',value:checkoutMoney(summary['total']),strong:true),
        ])),
        const SizedBox(height:8),Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke),boxShadow:AppShadows.soft),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[Icon(AppIcons.creditCard,color:AppColors.ocean700,size:22),SizedBox(width:10),Expanded(child:Text('Como você quer pagar?',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800,letterSpacing:-.4)))]),const SizedBox(height:8),Text(widget.creditOnly?'Seu cartão Porto Prime paga esta compra.':'Preencha os dados abaixo. A confirmação é feita com segurança pelo Stripe.',style:TextStyle(color:AppColors.muted,fontSize:12,height:1.6)),const SizedBox(height:22),
          if(_paymentSubmitted)Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:AppColors.ocean50,borderRadius:BorderRadius.circular(18)),child:Column(children:[const Icon(AppIcons.shield,color:AppColors.ocean700,size:30),const SizedBox(height:12),const Text('Confirmando seu pedido',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),const SizedBox(height:8),const Text('Estamos verificando o pagamento. Você não precisa pagar novamente.',textAlign:TextAlign.center,style:TextStyle(color:AppColors.muted,height:1.5)),if(paying)const Padding(padding:EdgeInsets.only(top:18),child:LinearProgressIndicator())]))
          else if(!ready&&error==null)const PrimeSkeleton(height:250,radius:18)
          else if(ready&&widget.creditOnly)const Text('O saldo Porto Prime cobre os produtos e a entrega. Confirme abaixo para concluir, sem cobrança no Stripe.',style:TextStyle(color:AppColors.muted,height:1.6))
          else if(ready&&kIsWeb)StripeWebElement(publishableKey:widget.publishableKey,clientSecret:widget.clientSecret,onPaymentState:_onWebPaymentState)
          else if(ready)const Text('Toque em Pagar para escolher sua forma de pagamento no formulário seguro.',style:TextStyle(color:AppColors.muted,height:1.5)),
          if((!kIsWeb||widget.creditOnly)&&ready&&!_paymentSubmitted)Padding(padding:const EdgeInsets.only(top:20),child:SizedBox(width:double.infinity,height:56,child:FilledButton.icon(onPressed:paying?null:_pay,icon:paying?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(AppIcons.lock,size:17),label:Text(paying?'Processando…':widget.creditOnly?'Confirmar compra com saldo':'Pagar')))),
        ])),
        if(error!=null)Padding(padding:const EdgeInsets.only(top:14),child:PrimeErrorBanner(message:error!)),
        if(_paymentSubmitted&&!paying&&error!=null)Padding(padding:const EdgeInsets.only(top:12),child:FilledButton.icon(onPressed:_startPaymentCheck,icon:const Icon(AppIcons.refresh,size:17),label:const Text('Verificar meu pedido'))),
        if(!ready&&!_paymentSubmitted&&error!=null)TextButton.icon(onPressed:_configure,icon:const Icon(AppIcons.refresh,size:17),label:const Text('Carregar pagamento novamente')),
        const SizedBox(height:18),Row(children:[const Icon(AppIcons.shield,size:16,color:AppColors.ocean700),const SizedBox(width:9),Expanded(child:Text(widget.creditOnly?'Pagamento com seu saldo Porto Prime.':'Dados de pagamento protegidos pelo Stripe.',style:TextStyle(fontSize:11,color:AppColors.muted,height:1.5)))]),const SizedBox(height:12),TextButton(onPressed:()=>_leave(),child:const Text('Voltar à entrega e revisão')),
      ])))),
    ));
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
