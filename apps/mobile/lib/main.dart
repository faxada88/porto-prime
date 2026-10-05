import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'core/state/app_state.dart';
import 'core/navigation/app_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppState.instance.loadProducts();
  runApp(const PortoPrimeApp());
}

class PortoPrimeApp extends StatelessWidget {
  const PortoPrimeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Porto Prime',
    theme: AppTheme.light,
    themeAnimationDuration: const Duration(milliseconds: 220),
    themeAnimationCurve: Curves.easeOutCubic,
    navigatorKey: AppNav.instance.rootNavigatorKey,
    home: const AppShell(),
  );
}
