@JS()
library;
import 'dart:js_interop';

@JS('portoPrimePlayDeliveryChime')
external void _play();
@JS('portoPrimeStopDeliveryChime')
external void _stop();

Future<void> playDeliveryOfferSound() async {try{_play();}catch(_){}}
Future<void> stopDeliveryOfferSound() async {try{_stop();}catch(_){}}
