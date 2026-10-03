@JS()
library stripe_web_element;

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

@JS('portoPrimeStripeMount')
external void _mountStripe(String containerId, String publishableKey, String clientSecret);

class StripeWebElement extends StatefulWidget {
  const StripeWebElement({
    super.key,
    required this.publishableKey,
    required this.clientSecret,
  });

  final String publishableKey;
  final String clientSecret;

  @override
  State<StripeWebElement> createState() => _StripeWebElementState();
}

class _StripeWebElementState extends State<StripeWebElement> {
  late final String _viewType;
  late final String _containerId;

  @override
  void initState() {
    super.initState();
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    _viewType = 'porto-prime-stripe-$suffix';
    _containerId = 'porto-prime-stripe-container-$suffix';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.minHeight = '420px'
        ..style.boxSizing = 'border-box';

      Future<void>.delayed(Duration.zero, () {
        _mountStripe(_containerId, widget.publishableKey, widget.clientSecret);
      });

      return element;
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 520,
        child: HtmlElementView(viewType: _viewType),
      );
}
