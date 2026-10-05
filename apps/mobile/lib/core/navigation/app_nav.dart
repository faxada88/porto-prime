import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppNav {
  AppNav._();
  static final instance = AppNav._();
  final index = ValueNotifier<int>(0);
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  void go(int value) => index.value = value.clamp(0, 3);

  void home() {
    index.value = 0;
    final navigator = rootNavigatorKey.currentState;
    if (navigator != null) navigator.popUntil((route) => route.isFirst);
  }
}
