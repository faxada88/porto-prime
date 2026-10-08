import 'package:flutter/services.dart';

Future<void> playDeliveryOfferSound() async {
  try {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.mediumImpact();
  } catch (_) { /* Never block an incoming delivery on audio availability. */ }
}
