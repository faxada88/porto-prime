import 'package:flutter/material.dart';
import '../navigation/app_nav.dart';

/// A browser cannot verify Android notification/background permissions.
 /// Do not report the courier online from Flutter Web.
Future<bool> prepareOnline() async {
  final context = AppNav.instance.rootNavigatorKey.currentContext;
  if (context != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fique online pelo aplicativo'),
        content: const Text(
          'Para receber entregas, abra o Porto Prime no aplicativo Android. '
          'O navegador não consegue validar as permissões obrigatórias de '
          'GPS, notificações e execução em segundo plano.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
  return false;
}

Future<bool> readyForOnline() async => false;
Future<void> online() async {}
Future<void> offline() async {}
Future<void> showOffer(Map<String, dynamic> offer) async {}
Future<void> dismissOffer(String? id) async {}
