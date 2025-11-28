import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_constants.dart';
import 'storage_service.dart';

class WebSocketService {
  WebSocketService._internal();

  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  final StorageService _storage = StorageService();
  final StreamController<Map<String, dynamic>> _smsController =
      StreamController<Map<String, dynamic>>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  String? _token;
  final Set<String> _subscriptions = {};

  Stream<Map<String, dynamic>> get smsStream => _smsController.stream;

  Future<void> ensureConnected() async {
    if (_channel != null || _isConnecting) {
      return;
    }

    _isConnecting = true;
    _token = await _storage.getToken();

    if (_token == null) {
      _isConnecting = false;
      return;
    }

    final uri = _buildWebSocketUri(_token!);

    try {
      _channel = WebSocketChannel.connect(uri);
      _channelSubscription = _channel!.stream.listen(
        _handleMessage,
        onDone: () => _scheduleReconnect(),
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );

      _sendPendingSubscriptions();
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void subscribeToDevice(String deviceId) {
    if (deviceId.isEmpty) return;
    _subscriptions.add(deviceId);
    _sendAction('subscribe', deviceId);
  }

  void unsubscribeFromDevice(String deviceId) {
    if (deviceId.isEmpty) return;
    _subscriptions.remove(deviceId);
    _sendAction('unsubscribe', deviceId);
  }

  void dispose() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _smsController.close();
  }

  Uri _buildWebSocketUri(String token) {
    final base = Uri.parse(ApiConstants.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';

    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws/admin',
      queryParameters: {'token': token},
    );
  }

  void _handleMessage(dynamic event) {
    try {
      final raw = event is String ? event : utf8.decode(event as List<int>);
      final Map<String, dynamic> data = jsonDecode(raw);
      final type = data['type'];
      if (type == 'connected') {
        _sendPendingSubscriptions();
        return;
      }

      if (type == 'sms' || type == 'sms_update') {
        _smsController.add(data);
      }
    } catch (_) {
      // Ignore malformed messages.
    }
  }

  void _sendPendingSubscriptions() {
    for (final deviceId in _subscriptions) {
      _sendAction('subscribe', deviceId);
    }
  }

  void _sendAction(String action, String deviceId) {
    if (_channel == null) {
      ensureConnected();
      return;
    }

    final payload = jsonEncode({
      'action': action,
      'device_id': deviceId,
    });

    try {
      _channel!.sink.add(payload);
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      ensureConnected();
    });
  }
}

