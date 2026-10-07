import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  final http.Client _http = http.Client();

  String? token;
  String? refreshToken;
  String? sessionId;
  String? deviceId;
  Future<bool>? _refreshing;
  void Function(String? token)? onAccessTokenChanged;

  String get baseUrl {
    const configured = String.fromEnvironment('API_URL');
    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/$'), '');
    }

    final current = Uri.base;
    var host = current.host.replaceFirst(
      RegExp(r'-[0-9]{4,5}(?=\.)'),
      '-3000',
    );

    return Uri(
      scheme: current.scheme == 'http' ? 'http' : 'https',
      host: host,
      port: host == current.host &&
              (host == 'localhost' || host == '127.0.0.1')
          ? 3000
          : null,
      path: '/api',
    ).toString().replaceAll(RegExp(r'/$'), '');
  }

  String get realtimeUrl =>
      baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - 4)
          : baseUrl;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('pp_access_token');
    refreshToken = prefs.getString('pp_refresh_token');
    sessionId = prefs.getString('pp_session_id');
    deviceId = prefs.getString('pp_device_id');

    if (deviceId == null || deviceId!.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(20, (_) => random.nextInt(256));
      deviceId =
          'pp-${DateTime.now().microsecondsSinceEpoch}-${base64UrlEncode(bytes).replaceAll('=', '')}';
      await prefs.setString('pp_device_id', deviceId!);
    }
  }

  Map<String, String> headers({String? overrideToken}) => {
        'Content-Type': 'application/json',
        'X-Device-Id': deviceId ?? '',
        'X-Device-Name': 'Porto Prime App',
        if ((overrideToken ?? token) != null)
          'Authorization': 'Bearer ${overrideToken ?? token}',
      };

  Future<void> setSession(Map<String, dynamic> data) async {
    token = (data['accessToken'] ?? data['token'])?.toString();
    refreshToken = data['refreshToken']?.toString();
    sessionId = data['sessionId']?.toString();

    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('pp_access_token', token!);
    }
    if (refreshToken != null) {
      await prefs.setString('pp_refresh_token', refreshToken!);
    }
    if (sessionId != null) {
      await prefs.setString('pp_session_id', sessionId!);
    }
    onAccessTokenChanged?.call(token);
  }

  Future<void> clearSession() async {
    token = null;
    refreshToken = null;
    sessionId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pp_access_token');
    await prefs.remove('pp_refresh_token');
    await prefs.remove('pp_session_id');
    onAccessTokenChanged?.call(null);
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Object? body,
    String? overrideToken,
  }) async {
    final encoded = body == null ? null : jsonEncode(body);
    final h = headers(overrideToken: overrideToken);

    switch (method) {
      case 'GET':
        return _http
            .get(uri, headers: h)
            .timeout(const Duration(seconds: 12));
      case 'POST':
        return _http
            .post(uri, headers: h, body: encoded)
            .timeout(const Duration(seconds: 15));
      case 'PATCH':
        return _http
            .patch(uri, headers: h, body: encoded)
            .timeout(const Duration(seconds: 15));
      case 'DELETE':
        return _http
            .delete(uri, headers: h, body: encoded)
            .timeout(const Duration(seconds: 15));
      default:
        throw Exception('Método inválido');
    }
  }

  dynamic _decode(http.Response response) {
    try {
      return response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  String _errorMessage(http.Response response, dynamic data) {
    final message = data is Map ? data['message'] : null;
    if (message is List) return message.join(', ');
    if (message != null) return message.toString();
    return 'Erro ${response.statusCode}';
  }

  Future<bool> _refreshAccessToken() {
    if (_refreshing != null) return _refreshing!;

    final completer = Completer<bool>();
    _refreshing = completer.future;

    () async {
      try {
        final refresh = refreshToken;
        if (refresh == null || refresh.isEmpty) {
          completer.complete(false);
          return;
        }

        final response = await _send(
          'POST',
          Uri.parse('$baseUrl/auth/refresh'),
          body: {'refreshToken': refresh},
          overrideToken: null,
        );
        final data = _decode(response);

        if (response.statusCode < 200 || response.statusCode >= 300) {
          await clearSession();
          completer.complete(false);
          return;
        }

        await setSession(Map<String, dynamic>.from(data as Map));
        completer.complete(true);
      } catch (_) {
        completer.complete(false);
      } finally {
        _refreshing = null;
      }
    }();

    return completer.future;
  }

  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    bool retryOnUnauthorized = true,
  }) async {
    final uri = Uri.parse(baseUrl + path);
    var response = await _send(method, uri, body: body);
    var data = _decode(response);

    if (response.statusCode == 401 &&
        retryOnUnauthorized &&
        path != '/auth/login' &&
        path != '/auth/refresh') {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        response = await _send(method, uri, body: body);
        data = _decode(response);
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, data));
    }

    return data;
  }
}
