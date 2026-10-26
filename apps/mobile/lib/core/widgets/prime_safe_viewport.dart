import 'package:flutter/material.dart';

/// Consume physical cutouts once, before routes and their own SafeAreas.
/// Keep keyboard insets and the user's text scaling available to descendants.
class PrimeSafeViewport extends StatelessWidget {
  const PrimeSafeViewport({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(color: const Color(0xFFF6F9FA),
    child: SafeArea(child: child));
}
