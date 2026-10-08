import 'package:flutter/material.dart';

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
    await AppState.instance.bootstrap();
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
              child: const Text(
                'Preparando seu espaço…',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        ),
      );
}
