import '../../../../core/localization/prime_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    // Keep launch visible as a Flutter widget while storage, translations and
    // the backend initialize. Never block the user on a failed API call.
    try {
      await ApiClient.instance.initialize().timeout(
        const Duration(seconds: 10),
      );
    } catch (error) {
      debugPrint('Porto Prime: session initialization failed: $error');
    }

    try {
      await AppLanguage.instance.initialize().timeout(
        const Duration(seconds: 10),
      );
    } catch (error) {
      debugPrint('Porto Prime: language initialization failed: $error');
    }

    try {
      await AppState.instance.bootstrap().timeout(
        const Duration(seconds: 25),
      );
    } catch (error) {
      debugPrint('Porto Prime: bootstrap unavailable: $error');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AppShell(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, _, _, child) => child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: Semantics(
              liveRegion: true,
              child: const PrimeText(
                'Preparando seu espaço…',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        ),
      );
}

