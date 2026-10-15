import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/support/presentation/pages/public_support_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for(final width in [320.0,390.0,768.0]) {
    for(final scale in [1.0,2.0]) {
      testWidgets('Public contact fits width=$width text=$scale', (tester) async {
        tester.view.devicePixelRatio=1;
        tester.view.physicalSize=Size(width,900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(theme:AppTheme.light,
          builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),
          home:PublicSupportPage(initialTopic:'PARTNERSHIP',client:MockClient((request) async=>http.Response('{}',200)))));
        await tester.pumpAndSettle();
        expect(find.text('Empresa, marca ou atividade (opcional)'),findsOneWidget);
        expect(tester.takeException(),isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets('Guest sends without session and receives private protocol', (tester) async {
    final requests=<http.Request>[];
    final client=MockClient((request) async {
      requests.add(request);
      expect(request.headers.keys.map((k)=>k.toLowerCase()),isNot(contains('authorization')));
      expect(request.url.query,isEmpty);
      final body=jsonDecode(request.body) as Map;
      expect(body['accessKey'],isNotEmpty);
      return http.Response(jsonEncode({'id':'contact-1','protocol':'PP-123456789ABC','status':'OPEN',
        'updatedAt':'2026-10-15T12:00:00.000Z','messages':[{'id':'m1','senderRole':'GUEST','text':'Preciso recuperar meu acesso.','createdAt':'2026-10-15T12:00:00.000Z'}]}),201);
    });
    await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:PublicSupportPage(initialTopic:'ACCESS',client:client)));
    await tester.pumpAndSettle();
    final fields=find.byType(TextFormField);
    await tester.enterText(fields.at(0),'Maria Silva');
    await tester.enterText(fields.at(1),'maria@example.com');
    await tester.enterText(fields.at(3),'Preciso recuperar meu acesso.');
    await tester.ensureVisible(find.text('Enviar para a Porto Prime'));
    await tester.tap(find.text('Enviar para a Porto Prime'));
    await tester.pumpAndSettle();
    expect(requests.length,1);
    expect(find.textContaining('PP-123456789ABC'),findsWidgets);
    expect(find.text('Copiar protocolo e código'),findsOneWidget);
    expect(find.text('Preciso recuperar meu acesso.'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
