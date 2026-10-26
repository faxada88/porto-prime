import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:country_picker/country_picker.dart';
import 'core/localization/prime_localization.dart';
import 'package:flutter/material.dart';

import 'core/navigation/app_nav.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.initialize();
  await AppLanguage.instance.initialize();
  runApp(const PortoPrimeApp());
}

class PortoPrimeApp extends StatelessWidget {
  const PortoPrimeApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppLanguage.instance,
    builder: (context, _) => MaterialApp(
    locale: AppLanguage.instance.locale,
    supportedLocales: AppLanguage.supported,
    localizationsDelegates: [CountryLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    debugShowCheckedModeBanner: false,
    builder: (context, child) => SafeArea(top: false, bottom: false, child: child ?? const SizedBox.shrink()),
    title: 'Porto Prime',
    theme: AppTheme.light,
    navigatorKey: AppNav.instance.rootNavigatorKey,
    navigatorObservers:[AppNav.instance.observer],
    home: const SplashPage(),
  ));
}

