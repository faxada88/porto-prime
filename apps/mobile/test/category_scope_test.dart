import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/state/app_state.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/categories/presentation/pages/categories_page.dart';
void main(){
 final app=AppState.instance;
 late List<dynamic> products,categories;late String selected;
 setUp((){
  products=app.products;categories=app.catalogCategories;selected=app.catalogCategory;
  app.catalogCategories=[{'name':'Cervejas'},{'name':'Carnes'}];app.catalogCategory='Todos';
  app.products=[
   {'id':'beer','name':'Corona','price':10,'stock':10,'active':true,'category':{'name':'Cervejas'}},
   {'id':'meat','name':'Picanha','price':20,'stock':10,'active':true,'category':{'name':'Carnes'}},
  ];
 });
 tearDown((){app.products=products;app.catalogCategories=categories;app.catalogCategory=selected;});
 testWidgets('Category has only its own products and no category switcher',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:const Scaffold(body:CategoriesPage(categoryName:'Cervejas'))));
  expect(find.byType(ChoiceChip),findsNothing);
  expect(find.text('Corona'),findsOneWidget);expect(find.text('Picanha'),findsNothing);
  app.selectCatalogCategory('Carnes');await tester.pump();
  expect(find.text('Corona'),findsOneWidget);expect(find.text('Picanha'),findsNothing);
  await tester.enterText(find.byType(TextField),'Picanha');await tester.pump();
  expect(find.text('Nada por aqui'),findsOneWidget);
  final clear=find.text('Limpar busca');
  await Scrollable.ensureVisible(tester.element(clear.first),alignment:.5);await tester.pumpAndSettle();
  await tester.tap(clear.first);await tester.pumpAndSettle();
  expect(find.text('Corona'),findsOneWidget);expect(find.text('Picanha'),findsNothing);
  expect(tester.takeException(),isNull);
 });
}
