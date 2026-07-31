import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/websocket_service.dart';

void main() {
  test('channel() returns the same broadcast stream for repeated calls with the same name', () {
    final service = WebSocketService('ws://localhost:8080/ws');

    final first = service.channel('feed_updates');
    final second = service.channel('feed_updates');

    expect(identical(first, second), isTrue);

    service.dispose();
  });

  test('channel() returns distinct streams for distinct channel names', () {
    final service = WebSocketService('ws://localhost:8080/ws');

    final feed = service.channel('feed_updates');
    final chat = service.channel('chat:123');

    expect(identical(feed, chat), isFalse);

    service.dispose();
  });
}
