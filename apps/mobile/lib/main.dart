import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';

void main() {
  runApp(const PortoPrimeApp());
}

class PortoPrimeApp extends StatelessWidget {
  const PortoPrimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Porto Prime',
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
