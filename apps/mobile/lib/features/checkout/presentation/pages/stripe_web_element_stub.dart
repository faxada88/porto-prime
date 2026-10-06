import 'package:flutter/widgets.dart';

class StripeWebElement extends StatelessWidget {
  const StripeWebElement({
    super.key,
    required this.publishableKey,
    required this.clientSecret,
  });

  final String publishableKey;
  final String clientSecret;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
