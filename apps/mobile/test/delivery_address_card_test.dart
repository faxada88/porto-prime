import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/addresses/presentation/widgets/delivery_address_sheet.dart';

const address=<String,dynamic>{'id':'address','label':'Casa','street':'Rua dos Hibiscos','number':'201','neighborhood':'Taperapuan','city':'Porto Seguro','state':'BA','complement':'Próximo à entrada principal','isDefault':true};
void main(){
 for(final scale in [1.0,2.0]){
  testWidgets('Delivery address card fits narrow screen with text $scale',(tester)async{
   tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(320,800);
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),home:Scaffold(body:SingleChildScrollView(child:Padding(padding:const EdgeInsets.all(16),child:DeliveryAddressCard(address:address,onSelect:(){},onAction:(_){}))))));
   expect(find.text('EM USO'),findsOneWidget);expect(find.text('Rua dos Hibiscos, 201'),findsOneWidget);
   expect(tester.takeException(),isNull);
   await tester.pumpWidget(const SizedBox.shrink());
  });
 }
 testWidgets('Address selection and management actions delegate independently',(tester)async{
  var selected=0;final actions=<String>[];
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:Scaffold(body:DeliveryAddressCard(address:address,onSelect:()=>selected++,onAction:actions.add))));
  await tester.tap(find.text('Casa'));expect(selected,1);
  await tester.tap(find.byTooltip('Opções do endereço'));await tester.pumpAndSettle();
  await tester.tap(find.text('Editar endereço'));await tester.pumpAndSettle();
  expect(actions,['edit']);expect(selected,1);
  await tester.tap(find.byTooltip('Opções do endereço'));await tester.pumpAndSettle();
  await tester.tap(find.text('Remover endereço'));await tester.pumpAndSettle();
  expect(actions,['edit','remove']);expect(selected,1);
 });
}
