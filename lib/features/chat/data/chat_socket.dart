import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';

/// Live messages, over the STOMP endpoint chat-service exposes at `/ws`.
///
/// The token travels as a query parameter, not a header: a WebSocket handshake
/// cannot carry an Authorization header, which is why the gateway leaves
/// `/ws/**` unauthenticated and chat-service checks the token itself. A
/// refused handshake closes the socket — the thread still works over REST, it
/// just stops updating on its own.
///
/// Subclassed by the offline mock, so anything real lives behind a method that
/// can be overridden.
class ChatSocket {
  ChatSocket(this._tokenStorage);

  final TokenStorage _tokenStorage;

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

  /// Every message posted to [conversationId] while the stream is listened to,
  /// the caller's own sends included — chat-service broadcasts to the topic
  /// after persisting, whichever way the message arrived.
  ///
  /// The socket is opened on the first listener and closed with the last, so a
  /// thread nobody is looking at holds nothing open.
  Stream<MessageModel> messages(String conversationId) {
    late StreamController<MessageModel> controller;
    StompClient? client;

    Future<void> connect() async {
      final token = await _tokenStorage.readAccessToken();
      if (token == null) {
        // Nothing to authenticate with. Not an error the thread should show:
        // a signed-out viewer cannot have opened it in the first place.
        await controller.close();
        return;
      }
      client = StompClient(
        config: StompConfig(
          url: socketUri(token).toString(),
          onConnect: (frame) {
            client?.subscribe(
              destination: '/topic/conversations/$conversationId',
              callback: (message) {
                final body = message.body;
                if (body == null) return;
                controller.add(
                  MessageModel.fromJson(
                    jsonDecode(body) as Map<String, dynamic>,
                  ),
                );
              },
            );
          },
          // Left to the library: it reconnects on its own, and a chat that
          // silently stops updating is worse than one that reconnects late.
          reconnectDelay: const Duration(seconds: 3),
        ),
      );
      client!.activate();
    }

    controller = StreamController<MessageModel>.broadcast(
      onListen: connect,
      onCancel: () => client?.deactivate(),
    );
    return controller.stream;
  }
}
