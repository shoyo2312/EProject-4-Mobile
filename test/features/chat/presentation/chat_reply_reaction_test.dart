import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_repository.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class _SignedIn extends AuthState {
  @override
  FutureOr<UserModel?> build() => UserModel(
    id: '1001',
    username: 'me',
    email: 'me@test.com',
    role: UserRole.user,
    status: UserStatus.active,
    emailVerified: true,
    createdAt: DateTime(2026, 3, 4),
  );
}

MessageModel message(
  String id, {
  String sender = '2002',
  List<MessageReaction> reactions = const [],
  int revision = 0,
}) => MessageModel(
  id: id,
  conversationId: 'c1',
  senderId: sender,
  content: 'message $id',
  sentAt: DateTime(2026, 9, 1),
  reactions: reactions,
  revision: revision,
);

void main() {
  late MockChatRepository repository;
  late MockUserRepository userRepository;
  late StreamController<ChatInboxEvent> inbox;

  setUp(() {
    repository = MockChatRepository();
    userRepository = MockUserRepository();
    inbox = StreamController<ChatInboxEvent>.broadcast();
    addTearDown(inbox.close);
    when(
      () => userRepository.getProfiles(any()),
    ).thenAnswer((_) async => <String, UserProfileModel>{});
    when(
      () => repository.markRead(any(), messageId: any(named: 'messageId')),
    ).thenAnswer((_) async {});
    when(() => repository.markDelivered(any(), any())).thenAnswer((_) async {});
    when(
      () => repository.liveMessages(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(() => repository.inboxEvents()).thenAnswer((_) => inbox.stream);
    when(
      () => repository.connectionLost(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => repository.listRequests()).thenAnswer((_) async => []);
    when(() => repository.listConversations()).thenAnswer((_) async => []);
  });

  ProviderContainer containerFor() {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_SignedIn.new),
        chatRepositoryProvider.overrideWithValue(repository),
        userRepositoryProvider.overrideWithValue(userRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<ProviderContainer> openThread(List<MessageModel> items) async {
    when(
      () => repository.listMessages('c1', size: any(named: 'size')),
    ).thenAnswer((_) async => MessagePage(items: items, hasMore: false));
    final container = containerFor();
    container.listen(threadProvider('c1'), (_, _) {});
    await container.read(threadProvider('c1').future);
    return container;
  }

  List<MessageModel> rows(ProviderContainer c) =>
      c.read(threadProvider('c1')).value!;

  group('the model', () {
    test('reads a reply quote, reactions and a video card', () {
      final m = messageFromServer({
        'id': 'm2',
        'conversationId': 'c1',
        'senderId': 1001,
        'content': 'look',
        'sentAt': '2026-09-01T10:00:00Z',
        'type': 'VIDEO',
        'replyToMessageId': 'm1',
        'replyTo': {
          'messageId': 'm1',
          'state': 'OK',
          'senderId': 2002,
          'type': 'TEXT',
          'content': 'hi   there',
        },
        'reactions': [
          {'userId': 2002, 'emoji': '😂'},
        ],
        'video': {
          'videoId': 'v1',
          'state': 'AVAILABLE',
          'thumbnailUrl': 'https://x/t.jpg',
        },
        'revision': 3,
      });
      expect(m.replyTo!.messageId, 'm1');
      expect(m.replyTo!.senderId, '2002');
      expect(m.replyTo!.text, 'hi there');
      expect(m.reactions.single.userId, '2002');
      expect(m.reactionOf('2002'), '😂');
      expect(m.video!.available, isTrue);
    });

    test('a recalled original reads as unsent and cannot be opened', () {
      final quote = ReplyQuote.fromJson({
        'messageId': 'm1',
        'state': 'RECALLED',
        'senderId': 2002,
      })!;
      expect(quote.visible, isFalse);
      expect(quote.text, 'Message unsent');
    });

    test('reactions group by emoji in the order offered', () {
      final groups = groupReactions(const [
        MessageReaction(userId: '1', emoji: '👍'),
        MessageReaction(userId: '2', emoji: '❤️'),
        MessageReaction(userId: '3', emoji: '👍'),
      ], '3');
      expect(groups.map((g) => g.emoji), ['❤️', '👍']);
      expect(groups.last.count, 2);
      expect(groups.last.mine, isTrue);
    });

    test('an update brings the reactions; a recall clears them', () {
      final m = message('m1', revision: 1);
      final reacted = m.applying(
        const MessageUpdate(
          messageId: 'm1',
          conversationId: 'c1',
          revision: 2,
          reactions: [MessageReaction(userId: '2002', emoji: '😮')],
        ),
      );
      expect(reacted.reactionOf('2002'), '😮');
      final recalled = reacted.applying(
        MessageUpdate(
          messageId: 'm1',
          conversationId: 'c1',
          revision: 3,
          recalledAt: DateTime(2026, 9, 2),
          reactions: const [],
        ),
      );
      expect(recalled.reactions, isEmpty);
      expect(recalled.recalled, isTrue);
    });
  });

  group('replies', () {
    test(
      'a reply goes up with the original\'s id and shows its quote',
      () async {
        final sent = Completer<MessageModel>();
        when(
          () => repository.sendMessage(
            'c1',
            'yes',
            clientRequestId: any(named: 'clientRequestId'),
            replyToMessageId: 'm1',
          ),
        ).thenAnswer((_) => sent.future);
        final c = await openThread([message('m1')]);

        final sending = c
            .read(threadProvider('c1').notifier)
            .send('yes', replyTo: rows(c).single);
        await Future<void>.delayed(Duration.zero);
        // Drawn at once, quote and all.
        expect(rows(c).first.pending, isTrue);
        expect(rows(c).first.replyTo!.messageId, 'm1');

        sent.complete(message('m2', sender: '1001'));
        await sending;
        expect(rows(c).map((m) => m.id), ['m2', 'm1']);
      },
    );

    test('a reply from the other side arrives on the user queue', () async {
      final c = await openThread([message('m1')]);
      final reply = message('m2').copyWith(replyTo: message('m1').asQuote());
      inbox.add(
        ChatInboxEvent(
          type: ChatEventType.message,
          conversationId: 'c1',
          message: reply,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(rows(c).map((m) => m.id), ['m2', 'm1']);
      expect(rows(c).first.replyTo!.messageId, 'm1');
    });

    test('locate fetches older pages until the original is there', () async {
      when(
        () => repository.listMessages('c1', size: any(named: 'size')),
      ).thenAnswer(
        (_) async =>
            MessagePage(items: [message('m3')], hasMore: true, nextCursor: 'a'),
      );
      when(
        () => repository.listMessages(
          'c1',
          cursor: 'a',
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async =>
            MessagePage(items: [message('m2')], hasMore: true, nextCursor: 'b'),
      );
      when(
        () => repository.listMessages(
          'c1',
          cursor: 'b',
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async => MessagePage(items: [message('m1')], hasMore: false),
      );
      final c = containerFor();
      c.listen(threadProvider('c1'), (_, _) {});
      await c.read(threadProvider('c1').future);

      final notifier = c.read(threadProvider('c1').notifier);
      expect(await notifier.locate('m1'), isTrue);
      expect(rows(c).map((m) => m.id), ['m3', 'm2', 'm1']);
      expect(await notifier.locate('gone'), isFalse);
    });
  });

  group('reactions', () {
    test('reacting shows at once and keeps the server\'s answer', () async {
      final answer = Completer<MessageUpdate>();
      when(
        () => repository.react('c1', 'm1', '😂'),
      ).thenAnswer((_) => answer.future);
      final c = await openThread([message('m1')]);

      final reacting = c.read(threadProvider('c1').notifier).react('m1', '😂');
      await Future<void>.delayed(Duration.zero);
      expect(rows(c).single.reactionOf('1001'), '😂');

      answer.complete(
        const MessageUpdate(
          messageId: 'm1',
          conversationId: 'c1',
          revision: 1,
          reactions: [
            MessageReaction(userId: '1001', emoji: '😂'),
            MessageReaction(userId: '2002', emoji: '👍'),
          ],
        ),
      );
      await reacting;
      expect(rows(c).single.reactions, hasLength(2));
      expect(rows(c).single.revision, 1);
    });

    test('the same emoji again takes the reaction back', () async {
      when(() => repository.unreact('c1', 'm1')).thenAnswer(
        (_) async => const MessageUpdate(
          messageId: 'm1',
          conversationId: 'c1',
          revision: 2,
          reactions: [],
        ),
      );
      final c = await openThread([
        message(
          'm1',
          revision: 1,
          reactions: const [MessageReaction(userId: '1001', emoji: '😂')],
        ),
      ]);

      await c.read(threadProvider('c1').notifier).react('m1', '😂');
      expect(rows(c).single.reactions, isEmpty);
      verifyNever(() => repository.react(any(), any(), any()));
    });

    test('a refused reaction is put back as it was', () async {
      when(() => repository.react('c1', 'm1', '😮')).thenThrow(
        const ServerException(403, 'no', code: 'REACTION_NOT_ALLOWED'),
      );
      final c = await openThread([
        message(
          'm1',
          reactions: const [MessageReaction(userId: '1001', emoji: '👍')],
        ),
      ]);

      await expectLater(
        c.read(threadProvider('c1').notifier).react('m1', '😮'),
        throwsA(isA<ServerException>()),
      );
      expect(rows(c).single.reactionOf('1001'), '👍');
    });

    test('the other side\'s reaction arrives as an update', () async {
      final c = await openThread([message('m1', sender: '1001')]);
      inbox.add(
        const ChatInboxEvent(
          type: ChatEventType.messageUpdated,
          conversationId: 'c1',
          update: MessageUpdate(
            messageId: 'm1',
            conversationId: 'c1',
            revision: 1,
            reactions: [MessageReaction(userId: '2002', emoji: '❤️')],
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(rows(c).single.reactionOf('2002'), '❤️');
    });
  });
}
