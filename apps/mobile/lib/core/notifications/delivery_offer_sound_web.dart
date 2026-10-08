@JS()
library;
import 'dart:js_interop';

@JS('portoPrimePlayDeliveryChime')
external void _play();

Future<void> playDeliveryOfferSound() async {
  try { _play(); } catch (_) { /* The delivery remains visible if audio is blocked. */ }
}
