import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppNav {
  AppNav._();
  static final instance = AppNav._();
  final index = ValueNotifier<int>(0);
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final observer = PrimeNavigationObserver();

  void go(int value) => index.value = value.clamp(0, 3);

  void home() {
    index.value = 0;
    final navigator = rootNavigatorKey.currentState;
    if (navigator != null) navigator.popUntil((route) => route.isFirst);
  }
}

class PrimeNavigationObserver extends NavigatorObserver {
  Route<dynamic>? top;
  String? get currentName=>top?.settings.name;
  @override
  void didPush(Route<dynamic> route,Route<dynamic>? previousRoute){top=route;}
  @override
  void didPop(Route<dynamic> route,Route<dynamic>? previousRoute){top=previousRoute;}
  @override
  void didRemove(Route<dynamic> route,Route<dynamic>? previousRoute){if(identical(top,route))top=previousRoute;}
  @override
  void didReplace({Route<dynamic>? newRoute,Route<dynamic>? oldRoute}){if(identical(top,oldRoute))top=newRoute;}
}
