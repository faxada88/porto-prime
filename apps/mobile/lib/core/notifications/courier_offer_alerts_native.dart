import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:geolocator/geolocator.dart';

import '../navigation/app_nav.dart';
import 'delivery_offer_sound.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

const _channelId = 'porto_prime_courier_offers_2026';
const _notificationId = 8911;
Future<void>? _initializing;
bool _active = false;
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

/// The Admin/API must never see ONLINE until all operational permissions have
/// been confirmed on this device. Never request permissions on reconnect,
/// heartbeat or after the server has already accepted the online transition.
Future<bool> prepareOnline() =>
    _permissionFlow ??= _prepareOnline().whenComplete(() => _permissionFlow = null);

bool _locationAllowed(LocationPermission permission) =>
    permission == LocationPermission.whileInUse ||
    permission == LocationPermission.always;

Future<bool> _locationReady() async {
  if (!await Geolocator.isLocationServiceEnabled()) return false;
  if (!_locationAllowed(await Geolocator.checkPermission())) return false;
  return await Geolocator.getLocationAccuracy() ==
      LocationAccuracyStatus.precise;
}

Future<bool> _notificationsReady() async {
  await _initialize();
  if (Platform.isAndroid) {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() == true;
  }
  if (Platform.isIOS) return _iosPermissionGranted;
  return false;
}

Future<bool> _backgroundReady() async {
  if (!Platform.isAndroid) return true;
  if (!_active || !FlutterBackground.isBackgroundExecutionEnabled) return false;
  try {
    return await FlutterBackground.hasPermissions;
  } catch (_) {
    return false;
  }
}

/// Passive verification, without any system permission prompts. Also used
/// when recovering an online session so a stale server status is not trusted.
Future<bool> readyForOnline() async {
  if (!Platform.isAndroid && !Platform.isIOS) return false;
  try {
    if (!await _locationReady()) return false;
    if (!await _notificationsReady()) return false;
    return await _backgroundReady();
  } catch (_) {
    return false;
  }
}

Future<bool> _confirmStart(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Antes de ficar online'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Para receber entregas com segurança, o Porto Prime precisa das seguintes autorizações:'),
              SizedBox(height: 18),
              Row(children: [
                Icon(Icons.my_location_rounded, color: Color(0xFF09816D)),
                SizedBox(width: 10),
                Expanded(child: Text('GPS ligado e localização precisa')),
              ]),
              SizedBox(height: 12),
              Row(children: [
                Icon(Icons.notifications_active_rounded, color: Color(0xFF09816D)),
                SizedBox(width: 10),
                Expanded(child: Text('Notificações de novas entregas')),
              ]),
              SizedBox(height: 12),
              Row(children: [
                Icon(Icons.battery_saver_rounded, color: Color(0xFF09816D)),
                SizedBox(width: 10),
                Expanded(child: Text('Execução em segundo plano enquanto estiver online')),
              ]),
              SizedBox(height: 18),
              Text('Se recusar alguma autorização, você permanecerá OFFLINE. Som e avisos na tela bloqueada também dependem das configurações do Android.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Agora não'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Autorizar e continuar'),
            ),
          ],
        ),
      ) ==
      true;
}

Future<void> _showPermissionIssue(
  BuildContext context, {
  required String title,
  required String message,
  Future<bool> Function()? openSettings,
}) async {
  if (!context.mounted) return;
  final open = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text('$message\n\nO motoboy continuará OFFLINE até autorizar.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Continuar offline'),
        ),
        if (openSettings != null)
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Abrir configurações'),
          ),
      ],
    ),
  );
  if (open == true && openSettings != null) {
    try {
      await openSettings();
    } catch (_) {
      // On returning to the app the courier may tap ONLINE to recheck.
    }
  }
}

Future<bool> _prepareOnline() async {
  if (!Platform.isAndroid && !Platform.isIOS) return false;
  if (await readyForOnline()) return true;

  final context = AppNav.instance.rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return false;
  if (!await _confirmStart(context)) return false;

  try {
    // 1. Location is obligatory before the backend even receives ONLINE.
    if (!await Geolocator.isLocationServiceEnabled()) {
      await _showPermissionIssue(
        context,
        title: 'Ative o GPS',
        message: 'Ligue a localização do aparelho para receber corridas. Depois volte ao Porto Prime e toque em Ficar online.',
        openSettings: Geolocator.openLocationSettings,
      );
      return false;
    }

    var location = await Geolocator.checkPermission();
    if (location == LocationPermission.denied) {
      location = await Geolocator.requestPermission();
    }
    if (!_locationAllowed(location)) {
      await _showPermissionIssue(
        context,
        title: 'Localização obrigatória',
        message: 'Permita ao Porto Prime acessar sua localização durante o uso do aplicativo.',
        openSettings: Geolocator.openAppSettings,
      );
      return false;
    }
    if (await Geolocator.getLocationAccuracy() !=
        LocationAccuracyStatus.precise) {
      await _showPermissionIssue(
        context,
        title: 'Ative a localização precisa',
        message: 'O acesso aproximado não é suficiente para localizar retiradas e entregas. Nas permissões do aplicativo, ative Usar local exato.',
        openSettings: Geolocator.openAppSettings,
      );
      return false;
    }

    // 2. Request local notification permission BEFORE going online.
    await _initialize();
    if (!await _notificationsReady()) {
      bool granted = false;
      if (Platform.isAndroid) {
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        granted = await android?.requestNotificationsPermission() == true;
      } else if (Platform.isIOS) {
        final ios = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        granted = await ios?.requestPermissions(
              alert: true, sound: true, badge: true) == true;
        _iosPermissionGranted = granted;
      }
      if (!granted || !await _notificationsReady()) {
        await _showPermissionIssue(
          context,
          title: 'Notificações obrigatórias',
          message: 'Habilite as notificações do Porto Prime para receber ofertas imediatamente. Ative também o som e os avisos na tela bloqueada nas configurações do aparelho.',
          openSettings: Geolocator.openAppSettings,
        );
        return false;
      }
    }

    // 3. Android foreground service and battery optimization authorization
    // must be granted BEFORE the ONLINE API call. A refusal fails closed.
    if (Platform.isAndroid && !await _backgroundReady()) {
      if (!await _startShiftBeforeOnline()) {
        await _showPermissionIssue(
          context,
          title: 'Execução em segundo plano obrigatória',
          message: 'Autorize o funcionamento em segundo plano e a permissão de bateria solicitada pelo Android. Isso permite receber ofertas com a tela bloqueada. Depois volte e toque em Ficar online.',
          openSettings: Geolocator.openAppSettings,
        );
        return false;
      }
    }

    // Final check after all dialogs: the server is still OFFLINE here.
    if (!await readyForOnline()) {
      await offline();
      await _showPermissionIssue(
        context,
        title: 'Autorização incompleta',
        message: 'Confirme GPS ligado, localização precisa, notificações e execução em segundo plano antes de ficar online.',
        openSettings: Geolocator.openAppSettings,
      );
      return false;
    }
    return true;
  } catch (error) {
    await offline();
    if (kDebugMode) {
      debugPrint('Porto Prime: online permissions not ready: $error');
    }
    await _showPermissionIssue(
      context,
      title: 'Não foi possível validar as permissões',
      message: 'O aparelho não confirmou todas as autorizações necessárias. Confira as permissões do Porto Prime e tente novamente.',
      openSettings: Geolocator.openAppSettings,
    );
    return false;
  }
}

Future<bool> _startShiftBeforeOnline() async {
  if (!Platform.isAndroid) return true;
  final generation = ++_shiftGeneration;
  try {
    final initialized = await FlutterBackground.initialize(
      androidConfig: FlutterBackgroundAndroidConfig(
        notificationTitle: 'Porto Prime · Motoboy online',
        notificationText: 'Aguardando ofertas de entrega',
        notificationImportance: AndroidNotificationImportance.normal,
        enableWifiLock: false,
      ),
    );
    if (!initialized || generation != _shiftGeneration) return false;
    final started = await FlutterBackground.enableBackgroundExecution();
    if (!started) return false;
    if (generation != _shiftGeneration) {
      await FlutterBackground.disableBackgroundExecution();
      return false;
    }
    _active = true;
    return await _backgroundReady();
  } catch (error) {
    if (kDebugMode) debugPrint('Porto Prime: background permission denied: $error');
    return false;
  }
}

/// No permissions are requested here. All authorization work must be done
/// by prepareOnline() before PATCH /orders/courier/online is submitted.
Future<void> online() async {}

Future<void> offline() async {
  if (Platform.isIOS) {
    await dismissOffer();
    return;
  }
  if (!Platform.isAndroid) return;
  ++_shiftGeneration;
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

