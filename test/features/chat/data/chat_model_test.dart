import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';

void main() {
  Map<String, dynamic> message(Map<String, dynamic> extra) => {
        'id': 'm1',
        'conversationId': 'c1',
        'senderId': 2002,
        'content': null,
        'sentAt': '2026-09-01T00:00:00Z',
        ...extra,
      };

  Map<String, dynamic> conversation(Map<String, dynamic> extra) => {
        'id': 'c1',
        'participantIds': [1001, 2002],
        'createdAt': '2026-08-01T00:00:00Z',
        ...extra,
      };

  group('messageFromServer', () {
    test('text is kept as sent', () {
      final m = messageFromServer(message({'content': 'hi', 'type': 'TEXT'}));
      expect(m.content, 'hi');
    });

    // The web client sends these; content is null on all of them, and a
    // null would otherwise fail the parse and drop the frame.
    test('a sticker reads as a sticker', () {
      expect(messageFromServer(message({'type': 'STICKER'})).content,
          'Sticker');
    });

    test('a video with no note reads as a shared video', () {
      expect(messageFromServer(message({'type': 'VIDEO'})).content,
          'Shared a video');
    });

    test('a recalled message shows nothing of what it said', () {
      final m = messageFromServer(message({
        'type': 'TEXT',
        'content': 'gone',
        'recalledAt': '2026-09-01T00:01:00Z',
      }));
      expect(m.content, 'Message unsent');
    });

    test('an older server with no type still parses', () {
      expect(messageFromServer(message({'content': 'hi'})).content, 'hi');
    });
  });

  group('conversationFromServer', () {
    test('a sticker preview reads as a sticker', () {
      final c = conversationFromServer(conversation({
        'lastMessageContent': null,
        'lastMessageType': 'STICKER',
      }));
      expect(c.lastMessageContent, 'Sticker');
    });

    test('a recalled preview is hidden', () {
      final c = conversationFromServer(conversation({
        'lastMessageContent': 'gone',
        'lastMessageRecalled': true,
      }));
      expect(c.lastMessageContent, 'Message unsent');
    });

    test('a thread with no messages keeps no preview', () {
      expect(conversationFromServer(conversation({})).lastMessageContent,
          isNull);
    });
  });

  group('ChatInboxEvent.fromServer', () {
    test('a message event carries the message', () {
      final e = ChatInboxEvent.fromServer({
        'type': 'MESSAGE',
        'conversationId': 'c1',
        'message': message({'content': 'hi'}),
      })!;
      expect(e.type, ChatEventType.message);
      expect(e.message!.content, 'hi');
    });

    test('kinds this app does not act on are other', () {
      for (final type in ['TYPING', 'RECEIPT', 'MESSAGE_UPDATED', 'NEW']) {
        expect(
          ChatInboxEvent.fromServer({'type': type, 'conversationId': 'c1'})!
              .type,
          ChatEventType.other,
        );
      }
    });

    test('a frame with no conversation is dropped', () {
      expect(ChatInboxEvent.fromServer({'type': 'MESSAGE'}), isNull);
    });
  });
}
