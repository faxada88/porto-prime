import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/navigation/app_nav.dart';
import 'package:porto_prime/core/state/app_state.dart';
import 'package:porto_prime/core/theme/app_icons.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/cart/presentation/pages/cart_page.dart';
import 'package:porto_prime/features/orders/presentation/pages/orders_page.dart';

void main() {
 for(final scale in [1.0,2.0]) {
  testWidgets('Continue shopping returns Home without changing the cart at $scale',(tester)async{
   final state=AppState.instance,nav=AppNav.instance;
   final products=state.products,cart=Map<String,int>.from(state.cart);
   final known=state.storeStatusKnown,open=state.storeOpen,loading=state.loading,index=nav.index.value;
   state.products=[{'id':'item','name':'Produto do carrinho','price':19,'stock':5,'active':true,'category':{'name':'Gelos'}}];
   state.cart..clear()..['item']=2;
   state.storeStatusKnown=true;state.storeOpen=true;state.loading=false;nav.go(2);
   addTearDown((){
    state.products=products;state.cart..clear()..addAll(cart);
    state.storeStatusKnown=known;state.storeOpen=open;state.loading=loading;nav.go(index);
   });
   tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(320,1100);
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(
    data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),
    home:const Scaffold(body:CartPage())));
   await tester.ensureVisible(find.text('Continuar comprando'));
   await tester.tap(find.text('Continuar comprando'));await tester.pump();
   expect(nav.index.value,0);
   expect(state.cart,{'item':2});
   expect(tester.takeException(),isNull);
   await tester.pumpWidget(const SizedBox.shrink());
  });
 }
 testWidgets('Orders has one back arrow and no Home icon in the app bar',(tester)async{
  final app=AppState.instance,nav=AppNav.instance;
  final user=app.user,orders=app.orders,active=app.activeOrder,index=nav.index.value;
  app.user=null;app.orders=[];app.activeOrder=null;nav.go(1);
  addTearDown((){app.user=user;app.orders=orders;app.activeOrder=active;nav.go(index);});
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:const OrdersPage()));
  await tester.pumpAndSettle();
  expect(find.byType(BackButton),findsOneWidget);
  expect(find.descendant(of:find.byType(AppBar),matching:find.byIcon(AppIcons.home)),findsNothing);
  await tester.tap(find.byType(BackButton));await tester.pump();
  expect(nav.index.value,0);
  expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox.shrink());
 });
}
