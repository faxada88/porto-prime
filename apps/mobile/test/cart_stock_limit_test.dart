import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/state/app_state.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_product_card.dart';
void main(){
 final state=AppState.instance;
 late List<dynamic> previousProducts;
 late Map<String,int> previousCart;
 late bool known,open;
 final product=<String,dynamic>{'id':'stock-test','name':'Corona','price':'10','stock':10,'active':true,'category':{'name':'Cervejas'}};
 setUp((){
  previousProducts=state.products;previousCart=Map.from(state.cart);known=state.storeStatusKnown;open=state.storeOpen;
  state.products=[Map<String,dynamic>.from(product)];state.cart.clear();state.storeStatusKnown=true;state.storeOpen=true;
 });
 tearDown((){state.products=previousProducts;state.cart..clear()..addAll(previousCart);state.storeStatusKnown=known;state.storeOpen=open;});
 test('Repeated additions and quantity jumps cannot exceed available stock',(){
  for(var i=0;i<15;i++){state.addProduct('stock-test');}
  expect(state.cart['stock-test'],10);expect(state.canIncreaseQuantity('stock-test'),isFalse);
  state.changeQty('stock-test',1);expect(state.cart['stock-test'],10);
  state.changeQty('stock-test',-1);expect(state.canIncreaseQuantity('stock-test'),isTrue);
  state.changeQty('stock-test',5);expect(state.cart['stock-test'],9);
  state.changeQty('stock-test',1);expect(state.cart['stock-test'],10);
 });
 test('Stock updates block increases but allow reducing the cart',(){
  state.cart['stock-test']=10;state.products.first['stock']=7;
  expect(state.cartExceedsStock,isTrue);state.changeQty('stock-test',1);expect(state.cart['stock-test'],10);
  state.changeQty('stock-test',-3);expect(state.cartExceedsStock,isFalse);
  expect(state.canIncreaseQuantity('stock-test'),isFalse);
 });
 test('Missing, empty and paused products cannot be added',(){
  state.addProduct('missing');expect(state.cart,isEmpty);
  state.products.first['stock']=0;state.addProduct('stock-test');expect(state.cart,isEmpty);
  state.products.first['stock']=10;state.products.first['active']=false;state.addProduct('stock-test');expect(state.cart,isEmpty);
 });
 testWidgets('Product plus control is disabled at the stock limit',(tester)async{
  state.cart['stock-test']=10;
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:Scaffold(body:Center(child:SizedBox(width:180,height:350,
   child:AnimatedBuilder(animation:state,builder:(_,__)=>PrimeProductCard(product:state.products.first,referenceStyle:true)))))));
  final plus=find.byWidgetPredicate((w)=>w is Semantics&&w.properties.label=='Limite de estoque atingido');
  expect(plus,findsOneWidget);
  final ink=find.descendant(of:plus,matching:find.byType(InkWell));
  expect(tester.widget<InkWell>(ink).onTap,isNull);
  expect(tester.takeException(),isNull);
 });
}
