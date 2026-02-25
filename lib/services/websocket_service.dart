// lib/services/websocket_service.dart
// ═══════════════════════════════════════════════════════════════
// WEBSOCKET SERVICE — Real-time message sync
// Singleton pattern matching sync_service.dart
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/constants.dart';
import '../utils/logger.dart';
import 'api/api_client.dart';

// ═══════════════════════════════════════════════════════════════
// CONNECTION STATE
// ═══════════════════════════════════════════════════════════════

enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

// ═══════════════════════════════════════════════════════════════
// WEBSOCKET SERVICE — SINGLETON
// ═══════════════════════════════════════════════════════════════

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  WebSocketService._();

  // Connection
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // State
  WsConnectionState _state = WsConnectionState.disconnected;
  final _stateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get stateStream => _stateController.stream;

  // Event listeners
  final Map<String, List<Function(Map<String, dynamic>)>> _listeners = {};

  // Timers
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  // Config
  static const int _maxReconnectAttempts = 10;
  static const Duration _pingInterval = Duration(seconds: 30);
  static const Duration _reconnectBaseDelay = Duration(seconds: 2);

  // ─────────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────────

  bool get isConnected => _state == WsConnectionState.connected;
  bool get isConnecting =>
      _state == WsConnectionState.connecting ||
      _state == WsConnectionState.reconnecting;
  WsConnectionState get state => _state;

  // ─────────────────────────────────────────────────────────────
  // CONNECT
  // ─────────────────────────────────────────────────────────────

  Future<void> connect({String? token}) async {
    if (isConnected || isConnecting) {
      AppLogger.warn('[WS] Already connected or connecting');
      return;
    }

    _setState(WsConnectionState.connecting);

    try {
      final authToken = token ?? ApiClient.instance.cachedToken;
      final wsUrl = Uri.parse(AppConstants.wsUrl).replace(
        queryParameters: authToken != null ? {'token': authToken} : null,
      );

      AppLogger.info('[WS] Connecting to ${wsUrl.host}...');

      _channel = WebSocketChannel.connect(wsUrl);
      await _channel!.ready;

      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;

      AppLogger.success('[WS] ✅ Connected');

      // Start listening
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Start ping timer
      _startPingTimer();
    } catch (e) {
      AppLogger.error('[WS] Connection failed', e);
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DISCONNECT
  // ─────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _cancelTimers();
    await _subscription?.cancel();
    await _channel?.sink.close();

    _channel = null;
    _subscription = null;
    _reconnectAttempts = 0;

    _setState(WsConnectionState.disconnected);
    AppLogger.info('[WS] Disconnected');
  }

  // ─────────────────────────────────────────────────────────────
  // EVENT LISTENERS
  // ─────────────────────────────────────────────────────────────

  void on(String eventType, Function(Map<String, dynamic>) callback) {
    _listeners.putIfAbsent(eventType, () => []);
    _listeners[eventType]!.add(callback);
  }

  void off(String eventType, Function(Map<String, dynamic>) callback) {
    _listeners[eventType]?.remove(callback);
  }

  void offAll(String eventType) {
    _listeners.remove(eventType);
  }

  // ─────────────────────────────────────────────────────────────
  // SEND MESSAGE
  // ─────────────────────────────────────────────────────────────

  void send(String eventType, Map<String, dynamic> data) {
    if (!isConnected || _channel == null) {
      AppLogger.warn('[WS] Cannot send — not connected');
      return;
    }

    try {
      final message = jsonEncode({
        'type': eventType,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _channel!.sink.add(message);
    } catch (e) {
      AppLogger.error('[WS] Send failed', e);
    }
  }

  void sendPing() {
    send(AppConstants.wsPing, {'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  // ─────────────────────────────────────────────────────────────
  // MESSAGE HANDLERS
  // ─────────────────────────────────────────────────────────────

  void _onMessage(dynamic rawData) {
    try {
      final json = jsonDecode(rawData as String) as Map<String, dynamic>;
      final eventType = json['type'] as String? ?? 'unknown';
      final data = json['data'] as Map<String, dynamic>? ?? {};

      AppLogger.ws('Event: $eventType');

      if (eventType == AppConstants.wsPong) {
        return;
      }

      final listeners = _listeners[eventType];
      if (listeners != null) {
        for (final callback in listeners) {
          try {
            callback(data);
          } catch (e) {
            AppLogger.error('[WS] Listener error', e);
          }
        }
      }
    } catch (e) {
      AppLogger.warn('[WS] Parse error: $e');
    }
  }

  void _onError(dynamic error) {
    AppLogger.error('[WS] Error', error);
  }

  void _onDone() {
    AppLogger.warn('[WS] Connection closed');
    _setState(WsConnectionState.disconnected);
    _scheduleReconnect();
  }

  // ─────────────────────────────────────────────────────────────
  // STATE MANAGEMENT
  // ─────────────────────────────────────────────────────────────

  void _setState(WsConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TIMERS
  // ─────────────────────────────────────────────────────────────

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (isConnected) {
        sendPing();
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.error('[WS] Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();

    final delay = _reconnectBaseDelay * (1 << _reconnectAttempts);
    final cappedDelay =
        delay > const Duration(seconds: 60) ? const Duration(seconds: 60) : delay;

    AppLogger.info(
        '[WS] Reconnecting in ${cappedDelay.inSeconds}s (attempt ${_reconnectAttempts + 1})');

    _setState(WsConnectionState.reconnecting);
    _reconnectAttempts++;

    _reconnectTimer = Timer(cappedDelay, () {
      connect();
    });
  }

  void _cancelTimers() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer = null;
  }

  // ─────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────

  void dispose() {
    _cancelTimers();
    _subscription?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _listeners.clear();
    _instance = null;
    AppLogger.info('[WS] Service disposed');
  }
}