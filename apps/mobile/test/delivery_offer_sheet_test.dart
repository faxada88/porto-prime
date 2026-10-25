import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/courier/presentation/widgets/incoming_delivery_offer_sheet.dart';

Map<String,dynamic> offer()=>{
 'offerId':'offer','orderId':'order','expiresAt':DateTime.now().add(const Duration(minutes:2)).toIso8601String(),
 'courierEarnings':12.5,'routeDistanceKm':4.2,'routeDurationMinutes':12,
 'pickup':{'name':'Porto Prime','region':'Centro'},'dropoff':{'neighborhood':'Taperapuan','city':'Porto Seguro'},
};
void main(){
 for(final width in [320.0,390.0]){
  for(final scale in [1.0,2.0]){
   testWidgets('Offer sheet fits $width / $scale',(tester)async{
    tester.view.devicePixelRatio=1;tester.view.physicalSize=Size(width,800);
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),home:Scaffold(body:Align(alignment:Alignment.bottomCenter,child:IncomingDeliveryOfferSheet(order:offer(),onAccept:()async{},onReject:()async{})))));
    await tester.pump();expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
   });
  }
 }
 testWidgets('Offer metadata and pending rejection fit 320px with large text',(tester)async{
  tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(320,800);
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  final response=Completer<void>();var rejections=0;
  final data=offer()
   ..['orderId']='a18f8349-2211-4d1a-8d2a-221122ab11ef'
   ..['expiresAt']=DateTime.now().add(const Duration(hours:1)).toIso8601String();
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(
   data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(2)),child:child!),
   home:Scaffold(body:IncomingDeliveryOfferSheet(order:data,onAccept:()async{},
    onReject:(){rejections++;return response.future;}))));
  await tester.pump();
  expect(tester.takeException(),isNull);
  expect(find.text('#22AB11EF'),findsOneWidget);
  final closeBounds=tester.getRect(find.byTooltip('Recusar entrega'));
  expect(closeBounds.left,greaterThanOrEqualTo(0));
  expect(closeBounds.right,lessThanOrEqualTo(320));
  await tester.ensureVisible(find.text('Recusar'));
  await tester.tap(find.text('Recusar'));await tester.pump();
  expect(rejections,1);expect(find.text('Enviando…'),findsOneWidget);
  expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox.shrink());
  response.complete();await tester.pump();
 });
 testWidgets('Only one accept request, and closing event waits for response',(tester)async{
  final response=Completer<void>();var calls=0;
  final available=ValueNotifier(true);addTearDown(available.dispose);
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:Builder(builder:(context)=>Scaffold(body:TextButton(onPressed:()=>showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(_)=>IncomingDeliveryOfferSheet(order:offer(),updates:available,isAvailable:()=>available.value,onAccept:(){calls++;return response.future;},onReject:()async{})),child:const Text('Oferta'))))));
  await tester.tap(find.text('Oferta'));await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Aceitar entrega'));
  await tester.tap(find.text('Aceitar entrega'));await tester.pump();
  expect(calls,1);expect(find.text('Confirmando…'),findsOneWidget);
  available.value=false;await tester.pump();
  expect(find.byType(IncomingDeliveryOfferSheet),findsOneWidget);
  final button=tester.widget<FilledButton>(find.byType(FilledButton));expect(button.onPressed,isNull);
  response.complete();await tester.pump();await tester.pumpAndSettle();
  expect(find.byType(IncomingDeliveryOfferSheet),findsNothing);expect(calls,1);
 });
 testWidgets('Rejected HTTP response leaves retry available instead of freezing',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:Scaffold(body:IncomingDeliveryOfferSheet(order:offer(),onAccept:()async{throw Exception('Falha de conexão');},onReject:()async{}))));
  await tester.ensureVisible(find.text('Aceitar entrega'));await tester.tap(find.text('Aceitar entrega'));await tester.pump();
  expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,isNotNull);
  expect(find.text('Confirmando…'),findsNothing);
  await tester.pumpWidget(const SizedBox.shrink());
 });
}
