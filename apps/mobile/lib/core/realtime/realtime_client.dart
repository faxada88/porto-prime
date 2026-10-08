import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/api_client.dart';

class RealtimeClient {
  RealtimeClient._();
  static final instance = RealtimeClient._();

  io.Socket? _socket;
  io.Socket? _catalogSocket;
  void connectCatalog() {
    if (_catalogSocket != null) return;
    final socket=io.io('${ApiClient.instance.realtimeUrl}/catalog',
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect()
        .enableReconnection().setReconnectionDelay(1200).build());
    for(final event in ['catalog.updated','store.updated','delivery.pricing.updated']) {
      socket.on(event,(payload)=>onEvent?.call(event,payload));
    }
    socket.onConnect((_)=>onEvent?.call('catalog.updated',null));
    _catalogSocket=socket;
    socket.connect();
  }

  void Function(String event, dynamic payload)? onEvent;

  bool get connected => _socket?.connected == true;

  void connect(String token) {
    if (token.isEmpty) return;

    final current = _socket;
    if (current != null) {
      current.auth = {'token': token};
      if (current.connected) return;
      current.connect();
      return;
    }

    final socket = io.io(
      ApiClient.instance.realtimeUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1200)
          .setAuth({'token': token})
          .build(),
    );

    const events = [
      'session.ready',
      'session.revoked',
      'order.created',
      'order.updated',
      'delivery.offer',
      'delivery.offer.closed',
      'delivery.accepted',
      'dispatch.offer',
      'dispatch.offer.closed',
      'courier.presence',
      'wallet.updated',
      'courier.profile.updated',
      'catalog.updated',
      'store.updated',
      'delivery.pricing.updated',
      'addresses.updated',
    ];

    for (final event in events) {
      socket.on(event, (payload) => onEvent?.call(event, payload));
    }

    socket.onReconnectAttempt((_) {
      final fresh = ApiClient.instance.token;
      if (fresh != null) socket.auth = {'token': fresh};
    });

    _socket = socket;
    socket.connect();
  }

  void reconnect(String token) {
    final socket = _socket;
    if (socket == null) {
      connect(token);
      return;
    }

    socket.auth = {'token': token};
    if (!socket.connected) socket.connect();
  }

  void disconnect() {
    final socket = _socket;
    if (socket != null) {
      socket.dispose();
    }
    _socket = null;
  }
}
