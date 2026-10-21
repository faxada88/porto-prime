import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/checkout/presentation/widgets/native_payment_modals.dart';

void main(){
 for(final width in [320.0,390.0]){
  for(final scale in [1.0,2.0]){
   testWidgets('Native choices fit $width / $scale and delegate Pix',(tester)async{
    tester.view.devicePixelRatio=1;tester.view.physicalSize=Size(width,900);
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    String? choice;
    await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),home:Scaffold(body:NativePaymentChoices(methods:const {'pix','card','link','boleto'},onSelect:(value)=>choice=value))));
    await tester.tap(find.text('Pix'));
    expect(choice,'pix');
    expect(find.text('Cartão'),findsOneWidget);expect(find.text('Boleto'),findsNothing);
    expect(tester.takeException(),isNull);
   });
  }
 }
 testWidgets('Disabled methods are not invented',(tester)async{
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:NativePaymentChoices(methods:const {'card'},onSelect:(_){}))));
  expect(find.text('Pix'),findsNothing);expect(find.text('Boleto'),findsNothing);
 });
 testWidgets('Pix remains in the modal and copies the Stripe code',(tester)async{
  String? copied;var checks=0;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,(call)async{
   if(call.method=='Clipboard.setData')copied=(call.arguments as Map)['text'] as String?;
   return null;
  });
  addTearDown(()=>tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,null));
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:Scaffold(body:NativePixModal(
   load:()async=>{'paid':false,'status':'requires_action','pix':{'data':'PIX-CODE-TEST','imageUrl':null,'expiresAt':null}},
   verify:()async{checks++;return false;},
  ))));
  await tester.pump();
  await tester.tap(find.text('Copiar código Pix'));await tester.pump();
  expect(copied,'PIX-CODE-TEST');expect(find.text('Código Pix copiado'),findsOneWidget);
  await tester.ensureVisible(find.text('Já paguei · verificar'));await tester.tap(find.text('Já paguei · verificar'));await tester.pump();
  expect(checks,1);expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox.shrink());
 });
}
