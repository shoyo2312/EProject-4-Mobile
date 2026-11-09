import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_report_reasons.dart';
import 'package:tiktok_mobile/features/chat/data/chat_repository.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_thread_screen.dart';
import 'package:tiktok_mobile/features/chat/presentation/typing_sender.dart';
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

final t0 = DateTime.utc(2026, 11, 6, 10);

MessageModel msg(
  String id, {
  String sender = '2002',
  int minute = 0,
  String content = 'hello',
}) =>
    MessageModel(
      id: id,
      conversationId: 'c1',
      senderId: sender,
      content: content,
      sentAt: t0.add(Duration(minutes: minute)),
    );

ReceiptMark mark(MessageModel m, {DateTime? at}) =>
    ReceiptMark(messageId: m.id, sentAt: m.sentAt, at: at ?? m.sentAt);

ConversationModel conversation({
  String id = 'c1',
  bool hasUnread = false,
  MuteMode muteMode = MuteMode.none,
  DateTime? mutedUntil,
}) =>
    ConversationModel(
      id: id,
      participantIds: const ['1001', '2002'],
      lastMessageContent: 'hi',
      createdAt: DateTime(2026, 8, 1),
      hasUnread: hasUnread,
      muteMode: muteMode,
      mutedUntil: mutedUntil,
    );

void main() {
  late MockChatRepository repository;
  late MockUserRepository users;
  late StreamController<ChatInboxEvent> inbox;
  late StreamController<MessageModel> topic;

  setUpAll(() {
    registerFallbackValue(MuteLength.oneHour);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    repository = MockChatRepository();
    users = MockUserRepository();
    inbox = StreamController<ChatInboxEvent>.broadcast();
    topic = StreamController<MessageModel>.broadcast();
    addTearDown(inbox.close);
    addTearDown(topic.close);
    when(() => users.getProfiles(any())).thenAnswer((_) async => {
          '2002': const UserProfileModel(
              userId: '2002',
              displayName: 'Lan',
              avatarUrl: 'http://localhost:9000/avatars/lan.jpg',
              followerCount: 0,
              followingCount: 0),
        });
    when(() => users.getMyProfile()).thenAnswer((_) async =>
        const UserProfileModel(
            userId: '1001',
            displayName: 'Me',
            avatarUrl: 'http://localhost:9000/avatars/me.jpg',
            followerCount: 0,
            followingCount: 0));
    when(() => repository.markRead(any(),
        messageId: any(named: 'messageId'))).thenAnswer((_) async {});
    when(() => repository.markDelivered(any(), any()))
        .thenAnswer((_) async {});
    when(() => repository.receipts(any()))
        .thenAnswer((_) async => const ReceiptView(conversationId: 'c1'));
    when(() => repository.liveMessages(any())).thenAnswer((_) => topic.stream);
    when(() => repository.inboxEvents()).thenAnswer((_) => inbox.stream);
    when(() => repository.connectionLost())
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.sendTyping(any(), any())).thenReturn(true);
    when(() => repository.listConversations())
        .thenAnswer((_) async => [conversation()]);
    when(() => repository.listRequests()).thenAnswer((_) async => []);
    when(() => repository.listMessages('c1', size: any(named: 'size')))
        .thenAnswer((_) async => const MessagePage(items: [], hasMore: false));
  });

  List<Override> overrides() => [
        authStateProvider.overrideWith(_SignedIn.new),
        chatRepositoryProvider.overrideWithValue(repository),
        userRepositoryProvider.overrideWithValue(users),
      ];

  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides());
    addTearDown(c.dispose);
    return c;
  }

  Future<ProviderContainer> openThread(List<MessageModel> items) async {
    when(() => repository.listMessages('c1', size: any(named: 'size')))
        .thenAnswer((_) async => MessagePage(items: items, hasMore: false));
    final c = container();
    c.listen(threadProvider('c1'), (_, _) {});
    await c.read(threadProvider('c1').future);
    return c;
  }

  List<String> ids(ProviderContainer c) =>
      c.read(threadProvider('c1')).value!.map((m) => m.id).toList();

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('receipts', () {
    test('a mark covers messages by position, ties broken by id', () {
      final a = msg('a', minute: 1);
      final b = msg('b', minute: 1);
      final later = msg('z', minute: 2);
      final at = mark(b);
      expect(at.covers(a), isTrue);
      expect(at.covers(b), isTrue);
      expect(at.covers(later), isFalse);
      expect(mark(a).covers(b), isFalse);
    });

    test('a mark read back from the store covers the message it names', () {
      // Sent: the server clock's microseconds. The mark: the same message as
      // the store holds it, to the millisecond.
      final sent = msg('m1', sender: '1001').copyWith(
        sentAt: DateTime.parse('2026-11-09T03:12:45.1234567Z'),
      );
      final stored = ReceiptMark.fromJson({
        'messageId': 'm1',
        'sentAt': '2026-11-09T03:12:45.123Z',
        'at': '2026-11-09T03:12:50Z',
      })!;
      expect(stored.covers(sent), isTrue);
      expect(
        ReceiptView(conversationId: 'c1', delivered: stored).statusOf(sent),
        MessageStatus.delivered,
      );
      expect(
        ReceiptView(conversationId: 'c1', delivered: stored, read: stored)
            .statusOf(sent),
        MessageStatus.seen,
      );
      // The next millisecond is still after it.
      final next = msg('m2', sender: '1001').copyWith(
        sentAt: DateTime.parse('2026-11-09T03:12:45.124001Z'),
      );
      expect(stored.covers(next), isFalse);
    });

    test('ids in the same millisecond compare as numbers', () {
      final short = msg('999');
      final long = msg('1000');
      expect(mark(long).covers(short), isTrue);
      expect(mark(short).covers(long), isFalse);
      expect(ReceiptMark.later(mark(short), mark(long))!.messageId, '1000');
    });

    test('my message reads Sent, then Delivered, then Seen', () {
      final m = msg('m1', sender: '1001', minute: 1);
      final reply = msg('m2', minute: 2);
      const none = ReceiptView(conversationId: 'c1');
      expect(none.statusOf(m), MessageStatus.sent);
      expect(none.statusOf(m.copyWith(pending: true)), MessageStatus.sending);
      expect(ReceiptView(conversationId: 'c1', delivered: mark(reply)).statusOf(m),
          MessageStatus.delivered);
      expect(
          ReceiptView(
                  conversationId: 'c1', delivered: mark(reply), read: mark(reply))
              .statusOf(m),
          MessageStatus.seen);
    });

    test('merging never moves a mark backwards', () {
      final early = mark(msg('a', minute: 1));
      final late = mark(msg('b', minute: 5));
      final merged = ReceiptView(conversationId: 'c1', read: late)
          .merge(ReceiptView(conversationId: 'c1', read: early, delivered: early));
      expect(merged.read!.messageId, 'b');
      expect(merged.delivered!.messageId, 'a');
    });

    test('RECEIPT, MESSAGE_UPDATED and MESSAGE_HIDDEN frames are read', () {
      final receipt = ChatInboxEvent.fromServer({
        'type': 'RECEIPT',
        'conversationId': 'c1',
        'receipt': {
          'conversationId': 'c1',
          'userId': 2002,
          'delivered': {
            'messageId': 'm1',
            'sentAt': '2026-11-06T10:00:00Z',
            'at': '2026-11-06T10:01:00Z',
          },
          'read': null,
        },
      })!;
      expect(receipt.type, ChatEventType.receipt);
      expect(receipt.receipt!.userId, '2002');
      expect(receipt.receipt!.delivered!.messageId, 'm1');
      expect(receipt.receipt!.read, isNull);

      final updated = ChatInboxEvent.fromServer({
        'type': 'MESSAGE_UPDATED',
        'conversationId': 'c1',
        'update': {
          'messageId': 'm1',
          'conversationId': 'c1',
          'revision': 3,
          'recalledAt': '2026-11-06T10:02:00Z',
          'reactions': [],
        },
      })!;
      expect(updated.type, ChatEventType.messageUpdated);
      expect(updated.update!.revision, 3);
      expect(updated.update!.recalledAt, isNotNull);

      final hidden = ChatInboxEvent.fromServer({
        'type': 'MESSAGE_HIDDEN',
        'conversationId': 'c1',
        'messageId': 'm1',
      })!;
      expect(hidden.type, ChatEventType.messageHidden);
      expect(hidden.messageId, 'm1');
    });

    test('a message from the other side is acknowledged as delivered',
        () async {
      final c = container();
      c.listen(conversationsProvider, (_, _) {});
      await c.read(conversationsProvider.future);

      inbox.add(ChatInboxEvent(
          type: ChatEventType.message, conversationId: 'c1', message: msg('m5')));
      inbox.add(ChatInboxEvent(
          type: ChatEventType.message,
          conversationId: 'c1',
          message: msg('m6', sender: '1001')));
      await settle();

      verify(() => repository.markDelivered('c1', ['m5'])).called(1);
      verifyNever(() => repository.markDelivered('c1', ['m6']));
    });

    test('a message that lands while the app is away is read on return',
        () async {
      final c = await openThread([]);
      final thread = c.read(threadProvider('c1').notifier);
      clearInteractions(repository);

      thread.setForeground(false);
      topic.add(msg('m7'));
      await settle();
      verifyNever(() => repository.markRead('c1',
          messageId: any(named: 'messageId')));

      thread.setForeground(true);
      verify(() => repository.markRead('c1', messageId: 'm7')).called(1);
    });

    test('the other side\'s marks are fetched, then moved by frames',
        () async {
      final first = msg('m1', minute: 1);
      final second = msg('m2', minute: 2);
      when(() => repository.receipts('c1')).thenAnswer((_) async =>
          ReceiptView(conversationId: 'c1', delivered: mark(second), read: mark(first)));
      final c = container();
      c.listen(peerReceiptProvider('c1'), (_, _) {});
      await c.read(peerReceiptProvider('c1').future);

      inbox.add(ChatInboxEvent(
        type: ChatEventType.receipt,
        conversationId: 'c1',
        receipt: ReceiptView(
            conversationId: 'c1', delivered: mark(first), read: mark(second)),
      ));
      await settle();

      final now = c.read(peerReceiptProvider('c1')).value!;
      expect(now.read!.messageId, 'm2');
      // A stale delivered mark in the frame did not undo the fetched one.
      expect(now.delivered!.messageId, 'm2');
    });
  });

  group('sending', () {
    test('a message shows as sending, then becomes the server\'s copy',
        () async {
      final reply = Completer<MessageModel>();
      when(() => repository.sendMessage('c1', 'yo',
              clientRequestId: any(named: 'clientRequestId')))
          .thenAnswer((_) => reply.future);
      final c = await openThread([msg('m1')]);

      final sending = c.read(threadProvider('c1').notifier).send('yo');
      final drawn = c.read(threadProvider('c1')).value!.first;
      expect(drawn.pending, isTrue);
      expect(drawn.content, 'yo');

      reply.complete(msg('m2', sender: '1001', content: 'yo'));
      await sending;
      expect(ids(c), ['m2', 'm1']);
      expect(c.read(threadProvider('c1')).value!.first.pending, isFalse);
    });

    test('the socket echo arriving first takes the sending row\'s place',
        () async {
      final reply = Completer<MessageModel>();
      when(() => repository.sendMessage('c1', 'yo',
              clientRequestId: any(named: 'clientRequestId')))
          .thenAnswer((_) => reply.future);
      final c = await openThread([]);

      final sending = c.read(threadProvider('c1').notifier).send('yo');
      final server = msg('m2', sender: '1001', content: 'yo');
      topic.add(server);
      await settle();
      expect(ids(c), ['m2']);

      reply.complete(server);
      await sending;
      expect(ids(c), ['m2']);
    });

    test('a failed send takes its row away again', () async {
      when(() => repository.sendMessage('c1', 'yo',
              clientRequestId: any(named: 'clientRequestId')))
          .thenThrow(const NetworkException());
      final c = await openThread([msg('m1')]);

      await expectLater(c.read(threadProvider('c1').notifier).send('yo'),
          throwsA(isA<NetworkException>()));
      expect(ids(c), ['m1']);
    });
  });

  group('unsending and deleting', () {
    test('a recall replaces the message with the unsent notice', () async {
      final m = MessageModel(
        id: 'm1',
        conversationId: 'c1',
        senderId: '1001',
        content: 'Sticker',
        sentAt: t0,
        type: MessageType.sticker,
        sticker: const StickerModel(stickerId: 's', name: 's', url: 'u'),
        revision: 1,
      );
      when(() => repository.recall('c1', 'm1')).thenAnswer((_) async =>
          MessageUpdate(
              messageId: 'm1', conversationId: 'c1', revision: 2, recalledAt: t0));
      final c = await openThread([m]);

      await c.read(threadProvider('c1').notifier).recall('m1');

      final now = c.read(threadProvider('c1')).value!.single;
      expect(now.recalled, isTrue);
      expect(now.sticker, isNull);
      expect(now.content, 'Message unsent');
    });

    test('an older update never overwrites a newer message', () {
      final m = msg('m1').copyWith(revision: 5);
      final stale = MessageUpdate(
          messageId: 'm1', conversationId: 'c1', revision: 4, recalledAt: t0);
      expect(m.applying(stale).recalled, isFalse);
    });

    test('refused once seen: the error surfaces and the marks are refetched',
        () async {
      when(() => repository.recall('c1', 'm1')).thenThrow(const ServerException(
          409, 'seen',
          code: 'MESSAGE_ALREADY_SEEN'));
      final c = await openThread([msg('m1', sender: '1001')]);
      c.listen(peerReceiptProvider('c1'), (_, _) {});
      await c.read(peerReceiptProvider('c1').future);

      await expectLater(c.read(threadProvider('c1').notifier).recall('m1'),
          throwsA(isA<ServerException>()));
      await c.read(peerReceiptProvider('c1').future);

      verify(() => repository.receipts('c1')).called(2);
      expect(c.read(threadProvider('c1')).value!.single.recalled, isFalse);
    });

    test('the other side\'s recall and my delete elsewhere arrive live',
        () async {
      final c = await openThread([msg('m2', minute: 1), msg('m1')]);

      inbox.add(ChatInboxEvent(
        type: ChatEventType.messageUpdated,
        conversationId: 'c1',
        update: MessageUpdate(
            messageId: 'm2', conversationId: 'c1', revision: 1, recalledAt: t0),
      ));
      inbox.add(const ChatInboxEvent(
          type: ChatEventType.messageHidden,
          conversationId: 'c1',
          messageId: 'm1'));
      // A frame for another thread changes nothing here.
      inbox.add(const ChatInboxEvent(
          type: ChatEventType.messageHidden,
          conversationId: 'c2',
          messageId: 'm2'));
      await settle();

      final rows = c.read(threadProvider('c1')).value!;
      expect(rows.map((m) => m.id), ['m2']);
      expect(rows.single.recalled, isTrue);
    });

    test('delete for me takes the message out of the thread', () async {
      when(() => repository.hide('c1', 'm1')).thenAnswer((_) async {});
      final c = await openThread([msg('m2', minute: 1), msg('m1')]);

      await c.read(threadProvider('c1').notifier).hide('m1');

      expect(ids(c), ['m2']);
    });
  });

  group('muting', () {
    test('a timed mute holds until its end; indefinite until turned off', () {
      final now = DateTime(2026, 11, 6, 12);
      expect(
          conversation(
                  muteMode: MuteMode.timed,
                  mutedUntil: now.add(const Duration(hours: 1)))
              .mutedAt(now),
          isTrue);
      expect(
          conversation(
                  muteMode: MuteMode.timed,
                  mutedUntil: now.subtract(const Duration(minutes: 1)))
              .mutedAt(now),
          isFalse);
      expect(conversation(muteMode: MuteMode.indefinite).mutedAt(now), isTrue);
      expect(conversation().mutedAt(now), isFalse);
    });

    test('the server\'s mute fields are read', () {
      final c = conversationFromServer({
        'id': 'c1',
        'participantIds': [1001, 2002],
        'createdAt': '2026-11-01T00:00:00Z',
        'muteMode': 'TIMED',
        'mutedUntil': '2026-11-06T13:00:00Z',
      });
      expect(c.muteMode, MuteMode.timed);
      expect(c.mutedUntil, DateTime.utc(2026, 11, 6, 13));
    });

    test('a muted thread stays unread but leaves the badge', () async {
      when(() => repository.listConversations()).thenAnswer((_) async => [
            conversation(id: 'c1', hasUnread: true),
            conversation(
                id: 'c2', hasUnread: true, muteMode: MuteMode.indefinite),
          ]);
      final c = container();
      c.listen(unreadConversationsProvider, (_, _) {});
      await c.read(conversationsProvider.future);

      expect(c.read(unreadConversationsProvider), 1);
    });

    test('muting replaces the row with the server\'s, and new messages '
        'still update it', () async {
      when(() => repository.listConversations())
          .thenAnswer((_) async => [conversation()]);
      when(() => repository.mute('c1', MuteLength.eightHours)).thenAnswer(
          (_) async => conversation(muteMode: MuteMode.indefinite));
      final c = container();
      c.listen(unreadConversationsProvider, (_, _) {});
      await c.read(conversationsProvider.future);

      await c
          .read(conversationsProvider.notifier)
          .mute('c1', MuteLength.eightHours);
      inbox.add(ChatInboxEvent(
          type: ChatEventType.message,
          conversationId: 'c1',
          message: msg('m9', content: 'still here')));
      await settle();

      final row = c.read(conversationsProvider).value!.single;
      expect(row.muted, isTrue);
      expect(row.hasUnread, isTrue);
      expect(row.lastMessageContent, 'still here');
      expect(c.read(unreadConversationsProvider), 0);
    });
  });

  group('the thread screen', () {
    Future<void> pumpThread(WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: ChatThreadScreen(conversationId: 'c1')),
      ));
      await tester.pumpAndSettle();
    }

    void thread(List<MessageModel> items, {ReceiptView? receipt}) {
      when(() => repository.listMessages('c1', size: any(named: 'size')))
          .thenAnswer((_) async => MessagePage(items: items, hasMore: false));
      if (receipt != null) {
        when(() => repository.receipts('c1')).thenAnswer((_) async => receipt);
      }
    }

    Future<void> pumpRouted(WidgetTester tester) async {
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, _) => const ChatThreadScreen(conversationId: 'c1')),
        GoRoute(
            path: '/profile',
            builder: (_, _) => const Scaffold(body: Text('my profile'))),
        GoRoute(
            path: '/profile/:userId',
            builder: (_, state) =>
                Scaffold(body: Text('profile ${state.pathParameters['userId']}'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: overrides(),
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('the header shows who it is and opens their profile',
        (tester) async {
      thread([msg('m1')]);
      await pumpRouted(tester);

      final header = find.byKey(const Key('chat_header_profile'));
      expect(find.descendant(of: header, matching: find.text('Lan')),
          findsOneWidget);
      await tester.tap(header);
      await tester.pumpAndSettle();

      expect(find.text('profile 2002'), findsOneWidget);
    });

    testWidgets('an avatar sits on the last message of each run',
        (tester) async {
      thread([
        msg('m4', sender: '1001', minute: 4, content: 'ok'),
        msg('m3', minute: 3, content: 'and this'),
        msg('m2', minute: 2, content: 'look'),
        msg('m1', sender: '1001', minute: 1, content: 'hey'),
      ]);
      await pumpRouted(tester);

      expect(find.byKey(const Key('chat_avatar_m4')), findsOneWidget);
      expect(find.byKey(const Key('chat_avatar_m3')), findsOneWidget);
      expect(find.byKey(const Key('chat_avatar_m2')), findsNothing);
      expect(find.byKey(const Key('chat_avatar_m1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat_avatar_m3')));
      await tester.pumpAndSettle();
      expect(find.text('profile 2002'), findsOneWidget);
    });

    testWidgets('the time sits beside the bubble, not inside it',
        (tester) async {
      thread([
        msg('m2', sender: '1001', minute: 2, content: 'mine'),
        msg('m1', minute: 1, content: 'theirs'),
      ]);
      await pumpRouted(tester);

      for (final id in ['m1', 'm2']) {
        final time = find.byKey(Key('chat_time_$id'));
        final bubble = find.byKey(Key('chat_message_$id'));
        expect(time, findsOneWidget);
        expect(
          find.descendant(of: bubble, matching: time),
          findsNothing,
        );
      }
      // Toward the middle: left of my bubble, right of theirs.
      expect(
        tester.getTopRight(find.byKey(const Key('chat_time_m2'))).dx,
        lessThanOrEqualTo(
          tester.getTopLeft(find.byKey(const Key('chat_message_m2'))).dx,
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('chat_time_m1'))).dx,
        greaterThanOrEqualTo(
          tester.getTopRight(find.byKey(const Key('chat_message_m1'))).dx,
        ),
      );
    });

    testWidgets('my own avatar opens my profile', (tester) async {
      thread([msg('m1', sender: '1001', content: 'hey')]);
      await pumpRouted(tester);

      await tester.tap(find.byKey(const Key('chat_avatar_m1')));
      await tester.pumpAndSettle();
      expect(find.text('my profile'), findsOneWidget);
    });

    testWidgets('my newest message says when it was seen', (tester) async {
      final mine = msg('m2', sender: '1001', minute: 1, content: 'mine');
      thread(
        [mine, msg('m1')],
        receipt: ReceiptView(
          conversationId: 'c1',
          delivered: mark(mine),
          read: ReceiptMark(
              messageId: 'm2',
              sentAt: mine.sentAt,
              at: DateTime.now().subtract(const Duration(minutes: 5))),
        ),
      );
      await pumpThread(tester);

      expect(find.byKey(const Key('chat_message_status')), findsOneWidget);
      expect(find.text('Seen 5m ago'), findsOneWidget);
    });

    testWidgets('a message just sent goes Sent, Delivered, Seen as frames come',
        (tester) async {
      // As the send answers: to the microsecond.
      final mine = msg('m1', sender: '1001', content: 'hi').copyWith(
        sentAt: DateTime.parse('2026-11-09T03:12:45.123456Z'),
      );
      thread([mine], receipt: const ReceiptView(conversationId: 'c1'));
      await pumpThread(tester);
      expect(find.text('Sent'), findsOneWidget);

      // The marks as the server sends them: read back from the store.
      Map<String, dynamic> stored() => {
            'messageId': 'm1',
            'sentAt': '2026-11-09T03:12:45.123Z',
            'at': DateTime.now().toUtc().toIso8601String(),
          };
      inbox.add(ChatInboxEvent.fromServer({
        'type': 'RECEIPT',
        'conversationId': 'c1',
        'receipt': {
          'conversationId': 'c1',
          'userId': 2002,
          'delivered': stored(),
        },
      })!);
      await tester.pumpAndSettle();
      expect(find.text('Delivered'), findsOneWidget);

      inbox.add(ChatInboxEvent.fromServer({
        'type': 'RECEIPT',
        'conversationId': 'c1',
        'receipt': {
          'conversationId': 'c1',
          'userId': 2002,
          'delivered': stored(),
          'read': stored(),
        },
      })!);
      await tester.pumpAndSettle();
      expect(find.text('Seen just now'), findsOneWidget);
    });

    testWidgets('an unseen message of mine can be unsent', (tester) async {
      thread([msg('m1', sender: '1001', content: 'oops')],
          receipt: const ReceiptView(conversationId: 'c1'));
      when(() => repository.recall('c1', 'm1')).thenAnswer((_) async =>
          MessageUpdate(
              messageId: 'm1', conversationId: 'c1', revision: 1, recalledAt: t0));
      await pumpThread(tester);
      expect(find.text('Sent'), findsOneWidget);

      await tester.longPress(find.byKey(const Key('chat_message_m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat_action_recall')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat_action_confirm')));
      await tester.pumpAndSettle();

      verify(() => repository.recall('c1', 'm1')).called(1);
      expect(find.text('Message unsent'), findsOneWidget);
    });

    testWidgets('a seen message cannot be unsent, only deleted for me',
        (tester) async {
      final mine = msg('m1', sender: '1001', content: 'seen it');
      thread([mine],
          receipt: ReceiptView(
              conversationId: 'c1', delivered: mark(mine), read: mark(mine)));
      when(() => repository.hide('c1', 'm1')).thenAnswer((_) async {});
      await pumpThread(tester);

      await tester.longPress(find.byKey(const Key('chat_message_m1')));
      await tester.pumpAndSettle();
      final recall = tester.widget<ListTile>(
          find.byKey(const Key('chat_action_recall')));
      expect(recall.enabled, isFalse);
      expect(find.text('Already seen, so it can\'t be unsent'), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat_action_hide')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat_action_confirm')));
      await tester.pumpAndSettle();

      verifyNever(() => repository.recall(any(), any()));
      verify(() => repository.hide('c1', 'm1')).called(1);
      expect(find.text('seen it'), findsNothing);
    });

    testWidgets('the other person\'s message offers delete only',
        (tester) async {
      thread([msg('m1')]);
      await pumpThread(tester);

      await tester.longPress(find.byKey(const Key('chat_message_m1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat_action_recall')), findsNothing);
      expect(find.byKey(const Key('chat_action_hide')), findsOneWidget);
    });

    testWidgets('mute for 8 hours from the menu', (tester) async {
      thread([msg('m1')]);
      when(() => repository.mute('c1', MuteLength.eightHours)).thenAnswer(
          (_) async => conversation(
              muteMode: MuteMode.timed,
              mutedUntil: DateTime.now().add(const Duration(hours: 8))));
      await pumpThread(tester);

      await tester.tap(find.byKey(const Key('chat_more_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat_menu_mute')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat_mute_eightHours')));
      await tester.pumpAndSettle();

      verify(() => repository.mute('c1', MuteLength.eightHours)).called(1);
      expect(find.text('Notifications muted'), findsOneWidget);

      // Opening the menu again offers to turn them back on.
      await tester.tap(find.byKey(const Key('chat_more_button')));
      await tester.pumpAndSettle();
      expect(find.text('Unmute notifications'), findsOneWidget);
    });

    testWidgets('report: reason, messages, submit, then block',
        (tester) async {
      thread([
        msg('m3', minute: 3, content: 'scam link'),
        msg('m2', sender: '1001', minute: 2, content: 'what?'),
        msg('m1', minute: 1, content: 'hi'),
      ]);
      when(() => repository.reportConversation(
            conversationId: any(named: 'conversationId'),
            reason: any(named: 'reason'),
            messageIds: any(named: 'messageIds'),
            requestId: any(named: 'requestId'),
          )).thenAnswer((_) async {});
      when(() => users.block('2002')).thenAnswer((_) async {});
      await pumpThread(tester);

      await tester.tap(find.byKey(const Key('chat_more_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat_menu_report')));
      await tester.pumpAndSettle();

      const reason = 'Frauds and scams';
      expect(chatReportReasons, contains(reason));
      await tester.tap(find.byKey(const Key('report_reason_$reason')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report_next')));
      await tester.pumpAndSettle();

      // The other person's latest messages come ticked; untick one, tick mine.
      expect(find.text('2/$reportMaxMessages selected'), findsOneWidget);
      await tester.tap(find.byKey(const Key('report_pick_m1')));
      await tester.tap(find.byKey(const Key('report_pick_m2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report_submit')));
      await tester.pumpAndSettle();

      final sent = verify(() => repository.reportConversation(
            conversationId: 'c1',
            reason: reason,
            messageIds: captureAny(named: 'messageIds'),
            requestId: any(named: 'requestId'),
          )).captured.single as List<String>;
      expect(sent, unorderedEquals(['m3', 'm2']));
      expect(find.text('Thanks for reporting'), findsOneWidget);

      await tester.tap(find.byKey(const Key('report_block')));
      await tester.pumpAndSettle();
      verify(() => users.block('2002')).called(1);
      expect(find.text('Blocked'), findsOneWidget);
    });
  });

  group('typing', () {
    ChatInboxEvent typing(bool on, {String user = '2002', String id = 'c1'}) =>
        ChatInboxEvent(
          type: ChatEventType.typing,
          conversationId: id,
          typingUserId: user,
          typing: on,
        );

    final dots = find.byKey(const Key('chat_typing_indicator'));

    // Not pumpAndSettle while the dots are up: they never settle.
    Future<void> pumpThread(WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: ChatThreadScreen(conversationId: 'c1')),
      ));
      await tester.pumpAndSettle();
    }

    // A frame to swap the child, one for the fade's first tick, one to end it.
    Future<void> fade(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('their typing shows the dots; their stop hides them',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpThread(tester);
      expect(dots, findsNothing);

      inbox.add(typing(true));
      await fade(tester);
      expect(dots, findsOneWidget);
      expect(find.bySemanticsLabel('Lan is typing'), findsOneWidget);

      inbox.add(typing(false));
      await fade(tester);
      expect(dots, findsNothing);
      semantics.dispose();
    });

    testWidgets('a message from them takes the dots away', (tester) async {
      await pumpThread(tester);
      inbox.add(typing(true));
      await fade(tester);

      inbox.add(ChatInboxEvent(
        type: ChatEventType.message,
        conversationId: 'c1',
        message: msg('m9'),
      ));
      await fade(tester);
      expect(dots, findsNothing);
    });

    testWidgets('dots with no word after them go away by themselves',
        (tester) async {
      await pumpThread(tester);
      inbox.add(typing(true));
      await fade(tester);

      await tester.pump(typingPeerTtl - const Duration(seconds: 1));
      expect(dots, findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await fade(tester);
      expect(dots, findsNothing);
    });

    testWidgets('my own typing and another thread show nothing',
        (tester) async {
      await pumpThread(tester);
      inbox.add(typing(true, user: '1001'));
      inbox.add(typing(true, id: 'c2'));
      await fade(tester);
      expect(dots, findsNothing);
    });

    testWidgets('typing in the box tells them; emptying it stops',
        (tester) async {
      await pumpThread(tester);
      final box = find.byKey(const Key('chat_composer_field'));

      await tester.enterText(box, 'h');
      await tester.enterText(box, 'he');
      verify(() => repository.sendTyping('c1', true)).called(1);

      await tester.enterText(box, '');
      verify(() => repository.sendTyping('c1', false)).called(1);
    });

    testWidgets('going to the background stops', (tester) async {
      await pumpThread(tester);
      await tester.enterText(find.byKey(const Key('chat_composer_field')), 'hi');
      verify(() => repository.sendTyping('c1', true)).called(1);

      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      verify(() => repository.sendTyping('c1', false)).called(1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    testWidgets('a request not yet answered announces nothing',
        (tester) async {
      when(() => repository.listConversations()).thenAnswer((_) async => [
            conversation()
                .copyWith(sendPermission: SendPermission.firstMessageOnly),
          ]);
      await pumpThread(tester);
      await tester.enterText(find.byKey(const Key('chat_composer_field')), 'hi');
      verifyNever(() => repository.sendTyping(any(), true));
    });
  });
}
