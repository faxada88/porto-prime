import 'package:flutter/foundation.dart';

class AppNav {
  AppNav._();
  static final instance = AppNav._();
  final index = ValueNotifier<int>(0);
  void go(int value) => index.value = value.clamp(0, 3);
}
