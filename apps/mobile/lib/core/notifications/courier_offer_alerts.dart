import 'courier_offer_alerts_native.dart'
    if (dart.library.js_interop) 'courier_offer_alerts_web.dart' as platform;

/// Android on-duty notification bridge. Web keeps the existing offer sheet.
class CourierOfferAlerts {
  CourierOfferAlerts._();

  static Future<void> online() => platform.online();
  static Future<void> offline() => platform.offline();

  static Future<void> show(Map<String, dynamic> offer) =>
      platform.showOffer(offer);

  static Future<void> dismiss([String? id]) =>
      platform.dismissOffer(id);
}
