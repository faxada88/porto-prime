import 'package:flutter/material.dart';

import 'core/navigation/app_nav.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.initialize();
  runApp(const PortoPrimeApp());
}

class PortoPrimeApp extends StatelessWidget {
  const PortoPrimeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Porto Prime',
    theme: AppTheme.light,
    navigatorKey: AppNav.instance.rootNavigatorKey,
    home: const SplashPage(),
  );
}
