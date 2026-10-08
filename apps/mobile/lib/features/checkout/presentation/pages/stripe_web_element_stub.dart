import 'package:flutter/widgets.dart';

class StripeWebElement extends StatelessWidget {
  const StripeWebElement({
    super.key,
    required this.publishableKey,
    required this.clientSecret,
    required this.onPaymentState,
  });

  final String publishableKey;
  final String clientSecret;
  final ValueChanged<String> onPaymentState;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
