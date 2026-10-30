import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';

/// Hands back an access token good enough for a handshake, or null when there
/// is no session — `ApiClient.validAccessToken` in the app.
typedef AccessTokenSource = Future<String?> Function();

typedef StompClientFactory = StompClient Function(StompConfig config);

/// Live chat, over the STOMP endpoint chat-service exposes at `/ws`.
///
/// One connection for the whole app, shared by every open stream and opened
/// only while somebody listens: the conversation list on the user's own
/// `/user/queue/chat`, an open thread on `/topic/conversations/{id}`.
///
/// The token travels as a query parameter, not a header: a WebSocket handshake
/// cannot carry an Authorization header, which is why the gateway leaves
/// `/ws/**` unauthenticated and chat-service checks the token itself. That is
/// also why reconnecting is done here rather than by the library: its retry
/// reuses the URL — and so the token — it was built with, and once the access
/// token expires (chat-service closes the socket when it does) every retry is
/// refused with the same dead token. Each attempt here asks [AccessTokenSource]
/// again, which refreshes when needed.
class ChatSocket {
  ChatSocket(
    this._accessToken, {
    StompClientFactory? clientFactory,
    this.initialBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
    this.stableAfter = const Duration(seconds: 10),
  }) : _newClient = clientFactory ?? ((config) => StompClient(config: config)),
       _backoff = initialBackoff;

  final AccessTokenSource _accessToken;
  final StompClientFactory _newClient;

  /// First wait before a retry; doubles per failure up to [maxBackoff].
  final Duration initialBackoff;
  final Duration maxBackoff;

  /// A connection that stayed up this long resets the backoff. Resetting on
  /// connect alone would turn a socket the server keeps refusing right after
  /// CONNECT into a reconnect every [initialBackoff], forever.
  final Duration stableAfter;

  static const inboxDestination = '/user/queue/chat';

  static String threadDestination(String conversationId) =>
      '/topic/conversations/$conversationId';

  /// `http://host:8080/api/v1` → `ws://host:8080/ws`. The socket is served by
  /// the gateway itself, outside the versioned API prefix.
  static Uri socketUri(String token) {
    final api = Uri.parse(Env.apiBaseUrl);
    return api.replace(
      scheme: api.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws',
      queryParameters: {'token': token},
    );
  }

  final Map<String, _Destination> _destinations = {};
  StompClient? _client;
  bool _connected = false;
  Timer? _retry;
  Duration _backoff;
  DateTime? _connectedAt;

  /// Bumped whenever the current connection is abandoned, so a callback from
  /// a client that has already been replaced cannot act on the new one.
  int _generation = 0;
  bool _connecting = false;

  /// Every message posted to [conversationId] while listened to, the caller's
  /// own sends included — chat-service broadcasts after persisting, whichever
  /// way the message arrived.
  Stream<MessageModel> messages(String conversationId) =>
      _watch(threadDestination(conversationId), messageFromServer);

  /// What happens in the signed-in user's threads that they did not do
  /// themselves: a message from the other side — the first one from somebody
  /// new included — or a thread that changed or went away.
  Stream<ChatInboxEvent> inbox() =>
      _watch(inboxDestination, ChatInboxEvent.fromServer);

  Stream<T> _watch<T extends Object>(
    String destination,
    T? Function(Map<String, dynamic>) parse,
  ) {
    late final StreamController<Object> controller;
    controller = StreamController<Object>(
      onListen: () => _add(destination, parse, controller),
      onCancel: () => _remove(destination, controller),
    );
    return controller.stream.cast<T>();
  }

  void _add(
    String destination,
    Object? Function(Map<String, dynamic>) parse,
    StreamController<Object> listener,
  ) {
    final existing = _destinations[destination];
    if (existing != null) {
      existing.listeners.add(listener);
      return;
    }
    final entry = _destinations[destination] = _Destination(destination, parse)
      ..listeners.add(listener);
    if (_connected) {
      _subscribe(entry);
    } else {
      _connect();
    }
  }

  void _remove(String destination, StreamController<Object> listener) {
    final entry = _destinations[destination];
    if (entry == null) return;
    entry.listeners.remove(listener);
    if (entry.listeners.isNotEmpty) return;
    _destinations.remove(destination);
    if (_connected) entry.unsubscribe?.call();
    if (_destinations.isEmpty) _disconnect();
  }

  Future<void> _connect() async {
    if (_client != null || _connecting || _destinations.isEmpty) return;
    _retry?.cancel();
    _connecting = true;
    final generation = _generation;

    String? token;
    try {
      token = await _accessToken();
    } catch (_) {
      token = null;
    }
    // A disconnect while the token was fetched has already cleared the flag,
    // and may have started a newer attempt that owns it now.
    if (generation != _generation) return;
    _connecting = false;
    if (_destinations.isEmpty) return;
    if (token == null) {
      // No session — signed out, or a refresh the server refused, which the
      // REST side treats as signed out too. Nothing to retry with: signing in
      // rebuilds the conversation list, whose new listener connects again.
      return;
    }

    final client = _newClient(
      StompConfig(
        url: socketUri(token).toString(),
        // Off: see the class comment. [_dropped] reconnects with a new token.
        reconnectDelay: Duration.zero,
        onConnect: (_) => _onConnected(generation),
        onWebSocketError: (error) => _dropped(generation, error),
        onWebSocketDone: () => _dropped(generation, null),
      ),
    );
    _client = client;
    client.activate();
  }

  void _onConnected(int generation) {
    if (generation != _generation) return;
    _connected = true;
    _connectedAt = DateTime.now();
    for (final entry in _destinations.values) {
      _subscribe(entry);
    }
  }

  void _subscribe(_Destination entry) {
    final client = _client;
    if (client == null) return;
    entry.unsubscribe = client.subscribe(
      destination: entry.destination,
      callback: (frame) {
        final body = frame.body;
        if (body == null) return;
        final Object? value;
        try {
          value = entry.parse(jsonDecode(body) as Map<String, dynamic>);
        } catch (e) {
          // One unreadable frame is not worth the connection.
          if (kDebugMode) debugPrint('[chat] unreadable frame: $e');
          return;
        }
        if (value == null) return;
        for (final listener in List.of(entry.listeners)) {
          listener.add(value);
        }
      },
    );
  }

  /// The socket closed or never opened. Called once per failure in practice,
  /// but an error is usually followed by done — the generation bump makes the
  /// second call a no-op.
  void _dropped(int generation, Object? error) {
    if (generation != _generation) return;
    if (kDebugMode && error != null) debugPrint('[chat] socket error: $error');
    _generation++;
    final connectedAt = _connectedAt;
    if (connectedAt != null &&
        DateTime.now().difference(connectedAt) >= stableAfter) {
      _backoff = initialBackoff;
    }
    _teardown();
    if (_destinations.isNotEmpty) _scheduleRetry();
  }

  void _scheduleRetry() {
    _retry?.cancel();
    final wait = _backoff;
    _retry = Timer(wait, _connect);
    _backoff = Duration(
      milliseconds: min(wait.inMilliseconds * 2, maxBackoff.inMilliseconds),
    );
  }

  void _disconnect() {
    _generation++;
    _retry?.cancel();
    _retry = null;
    _connecting = false;
    _backoff = initialBackoff;
    _teardown();
  }

  void _teardown() {
    final client = _client;
    _client = null;
    _connected = false;
    _connectedAt = null;
    for (final entry in _destinations.values) {
      entry.unsubscribe = null;
    }
    client?.deactivate();
  }

  /// Closes the connection and ends every stream handed out.
  void dispose() {
    final listeners = [
      for (final entry in _destinations.values) ...entry.listeners,
    ];
    _destinations.clear();
    _disconnect();
    for (final listener in listeners) {
      listener.close();
    }
  }
}

class _Destination {
  _Destination(this.destination, this.parse);

  final String destination;

  /// Null skips the frame: one this app has no use for.
  final Object? Function(Map<String, dynamic>) parse;
  final Set<StreamController<Object>> listeners = {};
  StompUnsubscribe? unsubscribe;
}
