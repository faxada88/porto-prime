import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_bottom_navigation.dart';

void main(){
 for(final scale in [1.0,2.0]){
  testWidgets('Light navigation fits narrow screens and delegates every destination at $scale',(tester)async{
   tester.view.physicalSize=const Size(320,640);
   tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);
   addTearDown(tester.view.resetDevicePixelRatio);
   final calls=<int>[];
   await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:MediaQuery(
    data:MediaQueryData(size:const Size(320,640),textScaler:TextScaler.linear(scale)),
    child:Scaffold(bottomNavigationBar:PrimeBottomNavigation(index:0,cartCount:3,showOrders:true,onSelect:calls.add)))));
   for(final label in ['Início','Pedidos','Carrinho','Ofertas','Conta']){
    await tester.tap(find.text(label));
   }
   expect(calls,[0,1,2,4,3]);
   expect(find.text('3'),findsOneWidget);
   expect(tester.takeException(),isNull);
  });
 }
 testWidgets('Guests never see Orders and the other menu destinations retain their indices', (tester) async {
  final calls=<int>[];
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:Scaffold(
   bottomNavigationBar:PrimeBottomNavigation(index:0,cartCount:3,orderCount:8,
    showOrders:false,onSelect:calls.add))));
  expect(find.text('Pedidos'),findsNothing);
  expect(find.text('8'),findsNothing);
  for(final label in ['Início','Carrinho','Ofertas','Conta']) {
   await tester.tap(find.text(label));
  }
  expect(calls,[0,2,4,3]);
  expect(tester.takeException(),isNull);
 });

}
