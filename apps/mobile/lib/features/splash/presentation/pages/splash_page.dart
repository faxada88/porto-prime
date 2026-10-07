import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;
  @override
  void initState() {
    super.initState();
    c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _go();
  }

  Future<void> _go() async {
    await Future.wait([
      AppState.instance.bootstrap(),
      Future.delayed(const Duration(milliseconds: 1900)),
    ]);
    if (mounted)
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const AppShell(),
          transitionDuration: const Duration(milliseconds: 650),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF007F72), Color(0xFF10A37F), Color(0xFF5CC8A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: c,
            builder: (_, _) => Transform.scale(
              scale: .82 + .18 * Curves.easeOutBack.transform(c.value),
              child: Opacity(
                opacity: c.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .12),
                            blurRadius: 35,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text(
                            'P',
                            style: TextStyle(
                              fontSize: 58,
                              fontWeight: AppFontWeight.display,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Positioned(
                            right: 23,
                            top: 25,
                            child: FadeTransition(
                              opacity: Tween<double>(begin: .15, end: 1)
                                  .animate(
                                    CurvedAnimation(
                                      parent: c,
                                      curve: const Interval(.45, 1),
                                    ),
                                  ),
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: const BoxDecoration(
                                  color: AppColors.sun,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'PORTO PRIME',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: AppFontWeight.display,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'O verão de Porto Seguro na sua porta.',
                      style: TextStyle(
                        color: Color(0xFFE9FFF8),
                        fontSize: 14,
                        fontWeight: AppFontWeight.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
