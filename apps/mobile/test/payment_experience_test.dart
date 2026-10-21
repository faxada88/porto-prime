import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/checkout/presentation/widgets/prime_payment_experience.dart';
const summary=<String,dynamic>{'subtotal':100.0,'deliveryFee':5.5,'storeCreditUsed':20.0,'total':85.5,
 'address':{'label':'Minha casa','street':'Avenida dos Navegantes','number':'123'},'distanceKm':2.1,'durationMinutes':8,
 'items':[{'quantity':2,'productName':'Produto de teste com descrição longa','total':100.0}]};
Widget review({bool web=false,bool credit=false,bool submitted=false,String? error,VoidCallback? pay,VoidCallback? back,VoidCallback? reopen,String selected='card',ValueChanged<String>? select})=>PrimePaymentExperience(
 summary:credit?{...summary,'storeCreditUsed':105.5,'total':0.0}:summary,creditOnly:credit,web:web,ready:true,paying:false,submitted:submitted,testMode:true,error:error,
 selectedMethod:selected,onSelectMethod:select,
 onReopen:reopen,onBack:back??(){},onHome:(){},onPay:pay??(){},onVerify:(){},onRetry:(){},
 paymentElement:web?const Text('FORMULARIO OFICIAL STRIPE'):null);
void main(){
 for(final width in [320.0,390.0,768.0]){
  for(final scale in [1.0,2.0]){
   testWidgets('Clean payment review fits width=$width text=$scale',(tester)async{
    tester.view.devicePixelRatio=1;tester.view.physicalSize=Size(width,800);
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),home:review()));
    await tester.pumpAndSettle();
    expect(find.text('Pagar com cartão ou carteira'),findsOneWidget);
    expect(find.text('Boleto'),findsNothing);
    expect(find.text('R\$ 85,50'),findsOneWidget);
    expect(find.byType(TextField),findsNothing);
    expect(tester.takeException(),isNull);
   });
  }
 }
 testWidgets('Single action delegates directly and preserves back navigation',(tester)async{
  var calls=0,back=0;
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review(pay:()=>calls++,back:()=>back++)));
  await tester.tap(find.text('Pagar com cartão ou carteira'));expect(calls,1);
  await tester.tap(find.byTooltip('Voltar à entrega e revisão'));expect(back,1);
 });
 testWidgets('Pix selection is on page and action is explicit',(tester)async{
  String selected='card';
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:StatefulBuilder(builder:(context,setState)=>review(selected:selected,select:(value)=>setState(()=>selected=value)))));
  final pixOption=find.byKey(const ValueKey('payment-method-pix'));
  await tester.scrollUntilVisible(pixOption,150,scrollable:find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(pixOption),alignment:0.5);
  await tester.pumpAndSettle();
  expect(pixOption.hitTestable(),findsOneWidget);
  await tester.tap(pixOption);await tester.pumpAndSettle();
  expect(selected,'pix');expect(find.text('Gerar Pix'),findsOneWidget);
  expect(find.byType(BottomSheet),findsNothing);
  expect(find.text('Boleto'),findsNothing);
 });
 testWidgets('Web keeps official element and adds no competing pay action',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review(web:true)));
  await tester.scrollUntilVisible(find.text('FORMULARIO OFICIAL STRIPE'),250,scrollable:find.byType(Scrollable).first);
  expect(find.text('FORMULARIO OFICIAL STRIPE'),findsOneWidget);
  expect(find.text('Pagar com cartão ou carteira'),findsNothing);
 });
 testWidgets('Submitted payment offers verification rather than another pay action',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review(submitted:true,error:'Verifique novamente.')));
  expect(find.text('Pagar com cartão ou carteira'),findsNothing);
  await tester.scrollUntilVisible(find.text('Verificar meu pedido'),250,scrollable:find.byType(Scrollable).first);
  expect(find.text('Verificar meu pedido'),findsOneWidget);
 });
 testWidgets('Credit-only flow keeps dedicated confirmation',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review(credit:true)));
  expect(find.text('Confirmar com saldo Porto Prime'),findsOneWidget);
  expect(find.byType(PaymentMethodPicker),findsNothing);
 });
}
