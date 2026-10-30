import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_socket.dart';

/// Stands in for the library client: records what it was asked to do, and
/// lets a test play the server's side through the callbacks it was built with.
class FakeStompClient extends StompClient {
  FakeStompClient(StompConfig config) : super(config: config);

  bool active = false;
  final subscriptions = <String, StompFrameCallback>{};

  @override
  void activate() => active = true;

  @override
  void deactivate() => active = false;

  @override
  StompUnsubscribe subscribe({
    required String destination,
    required StompFrameCallback callback,
    Map<String, String>? headers,
  }) {
    subscriptions[destination] = callback;
    return ({Map<String, String>? unsubscribeHeaders}) =>
        subscriptions.remove(destination);
  }

  String get token => Uri.parse(config.url).queryParameters['token']!;

  void connect() => config.onConnect(StompFrame(command: 'CONNECTED'));

  void drop() => config.onWebSocketDone();

  void deliver(String destination, Map<String, dynamic> body) =>
      subscriptions[destination]!(
          StompFrame(command: 'MESSAGE', body: jsonEncode(body)));
}

Map<String, dynamic> messageJson(String id) => {
      'id': id,
      'conversationId': 'c1',
      'senderId': 2002,
      'content': 'hi',
      'sentAt': '2026-09-01T00:00:00Z',
    };

/// Lets the token fetch and any zero-length retry timer run.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('the socket URL drops the API prefix and switches scheme', () {
    // Off Android, the default Env.apiBaseUrl is http://localhost:8080/api/v1
    // — the socket is served by the gateway itself, outside the versioned
    // prefix.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final uri = ChatSocket.socketUri('abc.def.ghi');

    expect(uri.scheme, 'ws');
    expect(uri.host, 'localhost');
    expect(uri.port, 8080);
    expect(uri.path, '/ws');
    // A handshake cannot carry an Authorization header, so the token rides in
    // the query string — which is why the gateway leaves /ws/** open and
    // chat-service validates it itself.
    expect(uri.queryParameters['token'], 'abc.def.ghi');
  });

  test('on Android the default host is the emulator alias for the host', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final uri = ChatSocket.socketUri('abc.def.ghi');

    expect(uri.host, '10.0.2.2');
    expect(uri.port, 8080);
    expect(uri.path, '/ws');
  });

  group('the shared connection', () {
    late List<FakeStompClient> clients;
    late List<String?> tokens;
    late ChatSocket socket;

    setUp(() {
      clients = [];
      tokens = ['t1', 't2', 't3'];
      var asked = 0;
      socket = ChatSocket(
        () async => asked < tokens.length ? tokens[asked++] : null,
        clientFactory: (config) {
          final client = FakeStompClient(config);
          clients.add(client);
          return client;
        },
        initialBackoff: Duration.zero,
        maxBackoff: Duration.zero,
      );
      addTearDown(socket.dispose);
    });

    test('one connection carries the inbox and a thread', () async {
      final inbox = <ChatInboxEvent>[];
      final thread = <MessageModel>[];
      final a = socket.inbox().listen(inbox.add);
      final b = socket.messages('c1').listen(thread.add);
      await settle();

      expect(clients, hasLength(1));
      clients.single.connect();
      expect(clients.single.subscriptions.keys, [
        '/user/queue/chat',
        '/topic/conversations/c1',
      ]);

      clients.single.deliver('/user/queue/chat', {
        'type': 'MESSAGE',
        'conversationId': 'c1',
        'message': messageJson('m1'),
      });
      clients.single.deliver('/user/queue/chat', {
        'type': 'TYPING',
        'conversationId': 'c1',
      });
      // No conversation: nothing could place it, so it never reaches a
      // listener.
      clients.single.deliver('/user/queue/chat', {'type': 'MESSAGE'});
      clients.single.deliver('/topic/conversations/c1', messageJson('m1'));
      await settle();
      expect(inbox.map((e) => e.type),
          [ChatEventType.message, ChatEventType.other]);
      expect(inbox.first.message!.id, 'm1');
      expect(thread.single.id, 'm1');

      await a.cancel();
      expect(clients.single.active, isTrue);
      await b.cancel();
      // Nobody listening, nothing held open.
      expect(clients.single.active, isFalse);
    });

    test('a dropped socket reconnects with a fresh token and resubscribes',
        () async {
      final sub = socket.messages('c1').listen((_) {});
      addTearDown(sub.cancel);
      await settle();
      clients.single.connect();

      // What chat-service does when the access token expires.
      clients.single.drop();
      await settle();

      expect(clients, hasLength(2));
      expect(clients.first.active, isFalse);
      // The library's own retry would have reused t1 forever.
      expect(clients.last.token, 't2');
      clients.last.connect();
      expect(clients.last.subscriptions.keys, ['/topic/conversations/c1']);
    });

    test('no session means no connection, and no retry loop', () async {
      tokens = [null, 't9'];
      final first = socket.inbox().listen((_) {});
      await settle();

      // Signed out: nothing opened, and nothing scheduled to try again.
      expect(clients, isEmpty);

      // Signing in rebuilds the list, whose new listener connects.
      await first.cancel();
      final second = socket.inbox().listen((_) {});
      addTearDown(second.cancel);
      await settle();
      expect(clients.single.token, 't9');
    });

    test('a listener added while connected is subscribed straight away',
        () async {
      final a = socket.inbox().listen((_) {});
      addTearDown(a.cancel);
      await settle();
      clients.single.connect();

      final b = socket.messages('c7').listen((_) {});
      addTearDown(b.cancel);

      expect(clients, hasLength(1));
      expect(clients.single.subscriptions.keys,
          contains('/topic/conversations/c7'));
      await b.cancel();
      expect(clients.single.subscriptions.keys,
          isNot(contains('/topic/conversations/c7')));
    });
  });
}
