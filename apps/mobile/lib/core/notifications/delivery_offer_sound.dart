import 'dart:async';
import 'delivery_offer_sound_native.dart'
    if (dart.library.js_interop) 'delivery_offer_sound_web.dart' as platform;

Timer? _repeat;
DateTime? _expiry;
int _generation=0;
bool _playing=false;

/// Only the currently displayed, unexpired offer may ring.
void startDeliveryOfferSound(DateTime expiresAt) {
  stopDeliveryOfferSound();
  if(!expiresAt.isAfter(DateTime.now()))return;
  _expiry=expiresAt;
  final generation=_generation;
  void ring(){
    if(generation!=_generation)return;
    if(_expiry==null||!_expiry!.isAfter(DateTime.now())){stopDeliveryOfferSound();return;}
    if(_playing)return;
    _playing=true;
    platform.playDeliveryOfferSound().catchError((_) {}).whenComplete(()=>_playing=false);
  }
  ring();
  _repeat=Timer.periodic(const Duration(seconds:4),(_)=>ring());
}

void stopDeliveryOfferSound() {
  _generation++;
  _repeat?.cancel();_repeat=null;_expiry=null;
  platform.stopDeliveryOfferSound().catchError((_) {});
}
