import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/checkout/presentation/widgets/prime_payment_experience.dart';
const summary=<String,dynamic>{'subtotal':100.0,'deliveryFee':5.5,'storeCreditUsed':20.0,'total':85.5,
 'address':{'label':'Minha casa','street':'Avenida dos Navegantes','number':'123'},'distanceKm':2.1,'durationMinutes':8,
 'items':[{'quantity':2,'productName':'Produto de teste com descrição longa','total':100.0}]};
Widget review({bool web=false,bool credit=false,bool submitted=false,String? error,VoidCallback? pay,VoidCallback? back,VoidCallback? reopen})=>PrimePaymentExperience(
 summary:credit?{...summary,'storeCreditUsed':105.5,'total':0.0}:summary,creditOnly:credit,web:web,ready:true,paying:false,submitted:submitted,testMode:true,error:error,
 onReopen:reopen,onBack:back??(){},onHome:(){},onPay:pay??(){},onVerify:(){},onRetry:(){},
 paymentElement:web?const Text('FORMULARIO OFICIAL STRIPE'):null);
void main(){
 testWidgets('Payment methods guide includes Pix and eligible wallets without card fields',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review()));
  await tester.scrollUntilVisible(find.text('Pix · simples e rápido'),250,scrollable:find.byType(Scrollable).first);
  expect(find.text('Apple Pay'),findsOneWidget);
  expect(find.text('Google Pay'),findsOneWidget);
  expect(find.text('Boleto'),findsOneWidget);
  expect(find.text('Link'),findsOneWidget);
  expect(find.byType(TextField),findsNothing);
  expect(tester.takeException(),isNull);
 });
 testWidgets('Pending checkout reopens payment options through its callback',(tester)async{
  var opened=0;
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review(submitted:true,reopen:()=>opened++)));
  await tester.scrollUntilVisible(find.text('Abrir formas de pagamento'),250,scrollable:find.byType(Scrollable).first);
  await tester.tap(find.text('Abrir formas de pagamento'));
  expect(opened,1);
 });

 for(final width in [320.0,390.0,768.0]){
  for(final scale in [1.0,2.0]){
   testWidgets('Payment review fits width=$width text=$scale',(tester)async{
    tester.view.devicePixelRatio=1;tester.view.physicalSize=Size(width,800);
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),home:review()));
    await tester.pumpAndSettle();
    expect(find.text('Pagar R\$ 85,50'),findsOneWidget);
    expect(find.byType(TextField),findsNothing);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
   });
  }
 }
 testWidgets('Single native CTA delegates without requesting a payment',(tester)async{
  var calls=0,back=0;
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review(pay:()=>calls++,back:()=>back++)));
  await tester.tap(find.text('Pagar R\$ 85,50'));expect(calls,1);
  await tester.tap(find.byTooltip('Voltar à entrega e revisão'));expect(back,1);
  expect(tester.takeException(),isNull);
 });
 testWidgets('Web keeps official element and adds no competing pay CTA',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review(web:true)));
  await tester.scrollUntilVisible(find.text('FORMULARIO OFICIAL STRIPE'),250,scrollable:find.byType(Scrollable).first);
  expect(find.text('FORMULARIO OFICIAL STRIPE'),findsOneWidget);
  expect(find.text('Pagar R\$ 85,50'),findsNothing);
 });
 testWidgets('Submitted payment never offers a second charge',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review(submitted:true,error:'Verifique novamente.')));
  expect(find.text('Pagar R\$ 85,50'),findsNothing);
  await tester.scrollUntilVisible(find.text('Verificar meu pedido'),250,scrollable:find.byType(Scrollable).first);
  expect(find.text('Verificar meu pedido'),findsOneWidget);
 });
 testWidgets('Credit-only flow keeps its dedicated confirmation',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:review(credit:true)));
  expect(find.text('Confirmar com saldo Porto Prime'),findsOneWidget);
  expect(find.text('Pagar R\$ 85,50'),findsNothing);
 });
}
