import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/chat/data/chat_socket.dart';

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
}
