import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/customer_account_workspace.dart';
void main(){
 for(final scale in [1.0,2.0]){
  testWidgets('Customer account stays readable and delegates actions at $scale',(tester)async{
   tester.view.physicalSize=const Size(320,640);tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   final calls=<String>[];
   await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:Scaffold(body:MediaQuery(
    data:MediaQueryData(size:const Size(320,640),textScaler:TextScaler.linear(scale)),
    child:CustomerAccountWorkspace(name:'Cliente com nome completo muito longo',email:'cliente@exemplo.com',
     onOrders:()=>calls.add('orders'),onAddresses:()=>calls.add('addresses'),onWallet:()=>calls.add('wallet'),
     onSupport:()=>calls.add('support'),onCommercial:()=>calls.add('commercial'),onLogout:()=>calls.add('logout'))))));
   for(final label in ['Meus pedidos','Endereços','Cartão Porto Prime','Ajuda e suporte','Parcerias e patrocínios','Sair da conta']){
    final target=find.text(label);
    await tester.scrollUntilVisible(target,150,scrollable:find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(target),alignment:.5);
    await tester.pumpAndSettle();await tester.tap(target);await tester.pump();
   }
   expect(calls,['orders','addresses','wallet','support','commercial','logout']);
   expect(find.text('Entrega do seu jeito'),findsNothing);
   expect(tester.takeException(),isNull);
  });
 }
}
