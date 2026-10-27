import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/state/app_state.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/features/courier/presentation/widgets/courier_account_status.dart';

void main() {
  final state = AppState.instance;
  tearDown(() { state.user = null; state.courierProfile = {}; });
  for (final status in ['PENDING', 'SUSPENDED', 'BLOCKED']) {
    for (final width in [320.0, 390.0, 768.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$status account remains readable at $width / $scale', (tester) async {
          state.user = {'id': 'courier', 'role': 'COURIER', 'status': status};
          state.courierProfile = {'approvalStatus': 'PENDING', 'restrictionReason': 'Confira a validade do documento enviado.', 'requirements': [
            {'id': 'r', 'title': 'Documento atualizado', 'description': 'Envie uma imagem legível do documento e confirme as informações solicitadas.', 'status': 'OPEN'},
          ]};
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 850);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
            builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
            home: const CourierAccountStatus()));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.text('Minha conta'), findsOneWidget);
          expect(find.byTooltip('Sair da conta'), findsOneWidget);
          expect(find.text('Documento atualizado'), findsOneWidget);
          expect(find.text('Enviar para análise'), status == 'PENDING' ? findsOneWidget : findsNothing);
          expect(find.text('Ficar online'), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  testWidgets('Answered requirement replaces the form with a waiting confirmation', (tester) async {
    state.user = {'id': 'courier', 'role': 'COURIER', 'status': 'PENDING'};
    state.courierProfile = {'approvalStatus': 'PENDING', 'requirements': [
      {'id': 'r', 'title': 'Documento atualizado', 'status': 'ANSWERED'},
    ]};
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const CourierAccountStatus()));
    expect(find.text('Pronto! Agora é só aguardar.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Enviar para análise'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('approval removes the operational restriction without changing the account identity', () {
    state.user = {'id': 'courier', 'role': 'COURIER', 'status': 'PENDING'};
    state.courierProfile = {'approvalStatus': 'PENDING'};
    expect(state.courierRestricted, isTrue);
    state.user!['status'] = 'ACTIVE'; state.courierProfile['approvalStatus'] = 'APPROVED';
    expect(state.courierRestricted, isFalse);
    expect(state.user!['id'], 'courier');
  });
}
