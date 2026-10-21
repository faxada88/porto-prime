import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/profile/presentation/pages/registration_page.dart';
import 'package:porto_prime/features/courier/presentation/pages/courier_photo_card.dart';
void main(){
 testWidgets('Courier photo is hidden until identity validation and CPF validation comes first',(tester)async{
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:const Scaffold(body:RegistrationPage(role:'COURIER'))));
  expect(find.byType(CourierPhotoCard),findsNothing);
  expect(find.text('Nome na Receita Federal'),findsNothing);
  expect(find.text('Informe CPF e data de nascimento para consultar a Receita Federal.'),findsNothing);
  expect(find.byWidgetPredicate((w)=>w is TextField&&w.decoration?.labelText=='Nome completo'),findsOneWidget);
  final next=find.text('Continuar');
  await Scrollable.ensureVisible(tester.element(next),alignment:.5);await tester.pumpAndSettle();
  await tester.tap(next);await tester.pumpAndSettle();
  expect(find.text('Valide seus dados'),findsOneWidget);
  expect(find.text('Adicione sua foto'),findsNothing);
  expect(find.byType(CourierPhotoCard),findsNothing);
  await tester.pumpWidget(const SizedBox.shrink());
 });
}
