import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
bool _attemptedThisShift = false;
int _shiftGeneration = 0;
String? _visibleOfferId;
Timer? _expiryTimer;

Future<void> _initialize() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
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
      iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
    ),
    onDidReceiveNotificationResponse: (response) {
      // The app already opens the latest live offer on the courier home page.
      AppNav.instance.home();
    },
  );

}

bool _iosPermissionGranted = false;
Future<bool>? _permissionFlow;
Future<bool> prepareOnline() => _permissionFlow ??= _prepareOnline().whenComplete(() => _permissionFlow = null);
Future<bool> _prepareOnline() async {
  if (!Platform.isAndroid && !Platform.isIOS) return true;
  if (Platform.isIOS && _iosPermissionGranted) return true;
  await _initialize();
  final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (await android?.areNotificationsEnabled() == true) return true;
  final context = AppNav.instance.rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return false;
  final proceed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
    title: const Text('Não perca uma entrega'),
    content: const Text('Autorize as notificações para receber novas entregas. Nas configurações do aparelho, mantenha o som e os avisos na tela bloqueada ativados. O modo silencioso e Não Perturbe podem silenciar os alertas.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Agora não')),
      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Autorizar notificações'))],
  ));
  if (proceed != true) return false;
  final granted = Platform.isAndroid ? await android?.requestNotificationsPermission() == true : await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, sound: true, badge: true) == true;
  if (!granted && context.mounted) {
    await showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: const Text('Ative as notificações'),
      content: const Text('Abra Configurações > Aplicativos > Porto Prime > Notificações e permita os avisos. Ative também som e tela bloqueada. Depois volte e toque em Ficar online.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))],
    ));
  }
  if (Platform.isIOS) _iosPermissionGranted = granted;
  return granted;
}

/// Start only when the motoboy explicitly chooses ONLINE. The ongoing
/// foreground service keeps the already authenticated Socket.IO isolate
/// receiving offers while Android's screen is locked.
Future<void> online() async {
  if (!Platform.isAndroid) return;
  if (_active || _attemptedThisShift) return;
  if (_activating != null) return _activating!;
  _attemptedThisShift = true;
  final generation = ++_shiftGeneration;
  _activating = _startShift(generation);
  try {
    await _activating!;
  } finally {
    _activating = null;
  }
}

Future<void> _startShift(int generation) async {
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
    if (generation == _shiftGeneration) {
      _active = started;
    } else if (started) {
      await FlutterBackground.disableBackgroundExecution();
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Porto Prime: foreground service not started: $e');
    // A denied system permission never changes the courier's online state.
    // In that case the in-app WebSocket alert still works while the app runs.
  }
}

Future<void> offline() async {
  if (Platform.isIOS) { await dismissOffer(); return; }
  if (!Platform.isAndroid) return;
  ++_shiftGeneration;
  _attemptedThisShift = false;
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
  if (!Platform.isAndroid && !Platform.isIOS) return;
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
      category: AndroidNotificationCategory.message,
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
      const NotificationDetails(android: android, iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true)),
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
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    await _notifications.cancel(_notificationId);
  } catch (_) {}
}

