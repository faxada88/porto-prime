import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background/flutter_background.dart';

import '../navigation/app_nav.dart';
import 'delivery_offer_sound.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

const _channelId = 'porto_prime_courier_offers_2026';
const _notificationId = 8911;
Future<void>? _initializing;
Future<void>? _activating;
bool _active = false;
String? _visibleOfferId;
Timer? _expiryTimer;

Future<void> _initialize() async {
  if (!Platform.isAndroid) return;
  if (_initializing != null) return _initializing!;
  _initializing = _initializeOnce();
  try {
    await _initializing!;
  } catch (_) {
    _initializing = null;
    rethrow;
  }
}

Future<void> _initializeOnce() async {
  await _notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: (response) {
      // The app already opens the latest live offer on the courier home page.
      AppNav.instance.home();
    },
  );
  final android = _notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
}

/// Start only when the motoboy explicitly chooses ONLINE. The ongoing
/// foreground service keeps the already authenticated Socket.IO isolate
/// receiving offers while Android's screen is locked.
Future<void> online() async {
  if (!Platform.isAndroid) return;
  if (_active) return;
  if (_activating != null) return _activating!;
  _activating = _startShift();
  try {
    await _activating!;
  } finally {
    _activating = null;
  }
}

Future<void> _startShift() async {
  try {
    await _initialize();
    final enabled = await FlutterBackground.initialize(
      androidConfig: FlutterBackgroundAndroidConfig(
        notificationTitle: 'Porto Prime · Motoboy online',
        notificationText: 'Aguardando ofertas de entrega',
        notificationImportance: AndroidNotificationImportance.normal,
        enableWifiLock: false,
      ),
    );
    if (!enabled) return;
    final started = await FlutterBackground.enableBackgroundExecution();
    _active = started;
  } catch (e) {
    if (kDebugMode) debugPrint('Porto Prime: foreground service not started: $e');
    // A denied system permission never changes the courier's online state.
    // In that case the in-app WebSocket alert still works while the app runs.
  }
}

Future<void> offline() async {
  if (!Platform.isAndroid) return;
  _active = false;
  await dismissOffer();
  try {
    if (FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
  } catch (_) {}
}

/// Called only for the currently assigned, unexpired offer for this courier.
/// New offers replace older notifications; duplicates from polling or socket
/// reconnect never ring again for the same offer ID.
Future<void> showOffer(Map<String, dynamic> offer) async {
  if (!Platform.isAndroid) return;
  final id = (offer['offerId'] ?? '').toString();
  final expiry = DateTime.tryParse(offer['expiresAt']?.toString() ?? '');
  if (id.isEmpty || expiry == null || !expiry.isAfter(DateTime.now())) return;
  if (_visibleOfferId == id) return;
  _visibleOfferId = id;
  _expiryTimer?.cancel();
  _expiryTimer = Timer(expiry.difference(DateTime.now()), () {
    unawaited(dismissOffer(id));
  });

  // Audio is a locally generated, original multi-note Porto Prime chime.
  // Its repetition ends immediately on expiration, acceptance, or rejection.
  startDeliveryOfferSound(expiry);

  try {
    await _initialize();
    if (_visibleOfferId != id) return;
    final number = int.tryParse(offer['displayNumber']?.toString() ?? '');
    final label = number == null ? 'Nova entrega disponível' :
      'Entrega #' + number.toString().padLeft(4, '0');
    final earnings = double.tryParse(
      (offer['courierEarnings'] ?? offer['deliveryFee'] ?? 0).toString()) ?? 0;
    final payment = 'R\$ ' + earnings.toStringAsFixed(2).replaceAll('.', ',');
    const android = AndroidNotificationDetails(
      _channelId,
      'Novas entregas Porto Prime',
      channelDescription: 'Ofertas urgentes de entregas para motoboys online',
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      ticker: 'Nova entrega Porto Prime',
      autoCancel: true,
      ongoing: false,
    );
    await _notifications.show(
      _notificationId,
      label,
      'Você recebeu uma oferta · ganho: $payment. Toque para avaliar.',
      const NotificationDetails(android: android),
      payload: id,
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Porto Prime: notification unavailable: $e');
  }
}

Future<void> dismissOffer([String? id]) async {
  if (id != null && _visibleOfferId != id) return;
  _visibleOfferId = null;
  _expiryTimer?.cancel();
  _expiryTimer = null;
  stopDeliveryOfferSound();
  if (!Platform.isAndroid) return;
  try {
    await _notifications.cancel(_notificationId);
  } catch (_) {}
}
