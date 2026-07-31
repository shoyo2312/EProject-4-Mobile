import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Single shared WebSocket connection exposing per-channel broadcast
/// streams. Not wired to any feature yet — connection is created lazily
/// on first use and reconnects with exponential backoff on drop.
class WebSocketService {
  WebSocketService(this._url);

  final String _url;
  WebSocketChannel? _channel;
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, Stream<dynamic>> _streams = {};
  int _backoffSeconds = 1;

  Stream<dynamic> channel(String name) {
    _ensureConnected();
    return _streams.putIfAbsent(name, () {
      final controller = StreamController<dynamic>.broadcast();
      _controllers[name] = controller;
      return controller.stream;
    });
  }

  void _ensureConnected() {
    if (_channel != null) return;
    _channel = WebSocketChannel.connect(Uri.parse(_url));
    _channel!.stream.listen(
      _routeMessage,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
    );
  }

  void _routeMessage(dynamic message) {
    // Messages are expected as {"channel": "...", "payload": ...} once the
    // backend contract is finalized; broadcast raw for now.
    for (final controller in _controllers.values) {
      controller.add(message);
    }
  }

  void _scheduleReconnect() {
    _channel = null;
    Timer(Duration(seconds: _backoffSeconds), () {
      _backoffSeconds = (_backoffSeconds * 2).clamp(1, 30);
      _ensureConnected();
    });
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _channel?.sink.close();
  }
}
