import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_mentions.dart';
import 'package:tiktok_mobile/features/feed/presentation/share_to_chat.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';

UserProfileModel friend(String id, String name, {String? username}) =>
    UserProfileModel(
      userId: id,
      username: username,
      displayName: name,
      followerCount: 0,
      followingCount: 0,
    );

void main() {
  group('mentions', () {
    test('a token starts at an @ at the start or after a space', () {
      expect(mentionTokenAt('@li', 3), (start: 0, query: 'li'));
      expect(mentionTokenAt('hi @', 4), (start: 3, query: ''));
      expect(mentionTokenAt('mail a@b', 8), isNull);
      // A space ends the tag.
      expect(mentionTokenAt('@lan hi', 7), isNull);
    });

    test('picking replaces the token with the handle and a space', () {
      final applied = applyMention('hi @la and', 3, 6, 'lan.nguyen');
      expect(applied.text, 'hi @lan.nguyen and');
      expect(applied.cursor, 'hi @lan.nguyen '.length);
    });

    test('handles are read the way the server reads them', () {
      expect(mentionedHandles('@Lan hi @bo. and @lan, x@y'), ['lan', 'bo']);
      final runs = splitMentions('hi @lan!');
      expect(runs.map((r) => r.handle), [null, 'lan', null]);
      expect(runs[1].text, '@lan');
    });

    test('suggestions match a handle before a name', () {
      final friends = [
        friend('1', 'Bao Lan', username: 'bao'),
        friend('2', 'Lan', username: 'lan99'),
        friend('3', 'Minh', username: 'minh'),
      ];
      expect(matchMentions(friends, 'lan').map((f) => f.userId), ['2', '1']);
      expect(matchMentions(friends, '').length, 3);
      // An account with no handle is tagged by its name without spaces.
      expect(mentionHandle(friend('4', 'Hoa Mai')), 'HoaMai');
    });
  });

  group('share recipients', () {
    ConversationModel chat(
      String id,
      String other, {
      DateTime? at,
      DateTime? pinnedAt,
      bool blocked = false,
      SendPermission permission = SendPermission.allowed,
    }) => ConversationModel(
      id: id,
      participantIds: ['me', other],
      createdAt: DateTime(2026, 1, 1),
      lastMessageAt: at,
      pinnedAt: pinnedAt,
      messagingBlocked: blocked,
      sendPermission: permission,
    );

    test('most recent message first, pins ignored, closed chats left out', () {
      final rows = [
        chat(
          'old-pinned',
          'a',
          at: DateTime(2026, 2, 1),
          pinnedAt: DateTime(2026, 3, 1),
        ),
        chat('new', 'b', at: DateTime(2026, 5, 1)),
        chat('blocked', 'c', at: DateTime(2026, 6, 1), blocked: true),
        chat(
          'waiting',
          'd',
          at: DateTime(2026, 6, 2),
          permission: SendPermission.requestSent,
        ),
        chat('mid', 'e', at: DateTime(2026, 4, 1)),
      ];
      expect(shareableConversations(rows, 'me').map((c) => c.id), [
        'new',
        'mid',
        'old-pinned',
      ]);
    });
  });
}
