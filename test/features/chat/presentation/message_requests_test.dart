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
import 'package:tiktok_mobile/features/chat/data/chat_repository.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_thread_screen.dart';
import 'package:tiktok_mobile/features/chat/presentation/message_requests_screen.dart';
import 'package:tiktok_mobile/features/chat/presentation/report_conversation_screen.dart';
import 'package:tiktok_mobile/features/inbox/presentation/inbox_screen.dart';
import 'package:tiktok_mobile/features/notification/data/notification_repository.dart';
import 'package:tiktok_mobile/features/notification/presentation/notification_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

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

class _EmptyStoryTray extends StoryTray {
  @override
  FutureOr<List<StoryGroup>> build() => const [];
}

final t0 = DateTime.utc(2026, 11, 6, 10);

MessageModel msg(String id, {String sender = '2002', String content = 'hey'}) =>
    MessageModel(
      id: id,
      conversationId: 'c1',
      senderId: sender,
      content: content,
      sentAt: t0,
    );

/// A request Lan (2002) sent the caller (1001), as the caller sees it.
ConversationModel incoming(
  String id, {
  bool hasUnread = true,
  MuteMode muteMode = MuteMode.none,
  DateTime? lastMessageAt,
}) =>
    ConversationModel(
      id: id,
      participantIds: const ['1001', '2002'],
      lastMessageContent: 'love your videos',
      lastMessageAt: lastMessageAt ?? t0,
      createdAt: t0,
      hasUnread: hasUnread,
      muteMode: muteMode,
      requestState: MessageRequestState.pending,
      initiatorId: '2002',
      sendPermission: SendPermission.awaitingAccept,
    );

/// c1 as the caller sees it with [permission].
ConversationModel thread(
  SendPermission permission, {
  MessageRequestState? state = MessageRequestState.pending,
  String initiator = '1001',
  DateTime? retryAvailableAt,
}) =>
    ConversationModel(
      id: 'c1',
      participantIds: const ['1001', '2002'],
      createdAt: t0,
      requestState: state,
      initiatorId: initiator,
      sendPermission: permission,
      retryAvailableAt: retryAvailableAt,
    );

final ordinary = thread(SendPermission.allowed, state: null);

void main() {
  late MockChatRepository repository;
  late MockUserRepository users;
  late StreamController<ChatInboxEvent> inbox;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    repository = MockChatRepository();
    users = MockUserRepository();
    inbox = StreamController<ChatInboxEvent>.broadcast();
    addTearDown(inbox.close);
    when(() => users.getProfiles(any())).thenAnswer((_) async => {
          '2002': const UserProfileModel(
              userId: '2002',
              displayName: 'Lan',
              followerCount: 0,
              followingCount: 0),
        });
    when(() => users.getMyProfile()).thenAnswer((_) async =>
        const UserProfileModel(
            userId: '1001',
            displayName: 'Me',
            followerCount: 0,
            followingCount: 0));
    when(() => repository.markRead(any(),
        messageId: any(named: 'messageId'))).thenAnswer((_) async {});
    when(() => repository.markDelivered(any(), any()))
        .thenAnswer((_) async {});
    when(() => repository.receipts(any()))
        .thenAnswer((_) async => const ReceiptView(conversationId: 'c1'));
    when(() => repository.liveMessages(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.inboxEvents()).thenAnswer((_) => inbox.stream);
    when(() => repository.connectionLost())
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.sendTyping(any(), any())).thenReturn(true);
    when(() => repository.listConversations()).thenAnswer((_) async => []);
    when(() => repository.listRequests()).thenAnswer((_) async => []);
    when(() => repository.getConversation('c1'))
        .thenAnswer((_) async => ordinary);
    when(() => repository.listMessages('c1', size: any(named: 'size')))
        .thenAnswer((_) async => MessagePage(items: [msg('m1')], hasMore: false));
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

  group('the conversation model', () {
    test('reads the request fields the server sends', () {
      final c = conversationFromServer({
        'id': 'c1',
        'participantIds': [1001, 2002],
        'createdAt': '2026-11-06T10:00:00Z',
        'lastMessageContent': 'hi',
        'requestState': 'PENDING',
        'initiatorId': 2002,
        'sendPermission': 'AWAITING_ACCEPT',
        'retryAvailableAt': null,
      });
      expect(c.requestState, MessageRequestState.pending);
      expect(c.initiatorId, '2002');
      expect(c.sendPermission, SendPermission.awaitingAccept);
      expect(c.isIncomingRequest('1001'), isTrue);
      expect(c.isIncomingRequest('2002'), isFalse);
    });

    test('a conversation without them, or with values this build does not '
        'know, is an ordinary one', () {
      final old = conversationFromServer({
        'id': 'c1',
        'participantIds': [1001, 2002],
        'createdAt': '2026-11-06T10:00:00Z',
      });
      expect(old.requestState, isNull);
      expect(old.sendPermission, SendPermission.allowed);

      final newer = conversationFromServer({
        'id': 'c1',
        'participantIds': [1001, 2002],
        'createdAt': '2026-11-06T10:00:00Z',
        'requestState': 'SOMETHING_NEW',
        'sendPermission': 'SOMETHING_NEW',
      });
      expect(newer.requestState, isNull);
      expect(newer.sendPermission, SendPermission.allowed);
    });

    test('the caller\'s own message spends a request or reopens one', () {
      final spent =
          thread(SendPermission.firstMessageOnly).afterOwnMessage(t0);
      expect(spent.sendPermission, SendPermission.requestSent);
      expect(spent.retryAvailableAt, t0.add(const Duration(days: 15)));

      final reopened = thread(
        SendPermission.reopenOnSend,
        state: MessageRequestState.declined,
        initiator: '2002',
      ).afterOwnMessage(t0);
      expect(reopened.sendPermission, SendPermission.allowed);
      expect(reopened.requestState, isNull);

      expect(ordinary.afterOwnMessage(t0), ordinary);
    });
  });

  group('the request box', () {
    test('counts requests, and the unread ones that are not muted', () async {
      when(() => repository.listRequests()).thenAnswer((_) async => [
            incoming('r1'),
            incoming('r2', hasUnread: false),
            incoming('r3', muteMode: MuteMode.indefinite),
          ]);
      when(() => repository.listConversations()).thenAnswer((_) async => [
            ordinary.copyWith(id: 'c9', hasUnread: true),
          ]);
      final c = container();
      c.listen(unreadConversationsProvider, (_, _) {});
      await c.read(messageRequestsProvider.future);
      await c.read(conversationsProvider.future);

      expect(c.read(requestCountsProvider), (pending: 3, unread: 1));
      // The Inbox badge: one unread thread and one unopened request.
      expect(c.read(unreadConversationsProvider), 2);
    });

    test('accepting moves the request to the inbox', () async {
      when(() => repository.listRequests())
          .thenAnswer((_) async => [incoming('c1')]);
      when(() => repository.acceptRequest('c1'))
          .thenAnswer((_) async => ordinary);
      final c = container();
      c.listen(conversationsProvider, (_, _) {});
      c.listen(messageRequestsProvider, (_, _) {});
      await c.read(conversationsProvider.future);
      await c.read(messageRequestsProvider.future);

      final accepted =
          await c.read(messageRequestsProvider.notifier).accept('c1');
      await c.read(conversationsProvider.future);

      expect(accepted.sendPermission, SendPermission.allowed);
      expect(c.read(messageRequestsProvider).value, isEmpty);
      verify(() => repository.listConversations()).called(2);
    });

    test('deleting takes it out of the box', () async {
      when(() => repository.listRequests())
          .thenAnswer((_) async => [incoming('c1')]);
      when(() => repository.declineRequest('c1')).thenAnswer((_) async =>
          thread(SendPermission.reopenOnSend,
              state: MessageRequestState.declined, initiator: '2002'));
      final c = container();
      c.listen(messageRequestsProvider, (_, _) {});
      await c.read(messageRequestsProvider.future);

      await c.read(messageRequestsProvider.notifier).decline('c1');

      expect(c.read(messageRequestsProvider).value, isEmpty);
      verify(() => repository.declineRequest('c1')).called(1);
    });

    test('a new message in a request is its preview, unread, on top',
        () async {
      when(() => repository.listRequests()).thenAnswer((_) async => [
            incoming('r2', lastMessageAt: t0),
            incoming('c1',
                hasUnread: false,
                lastMessageAt: t0.subtract(const Duration(days: 20))),
          ]);
      final c = container();
      c.listen(messageRequestsProvider, (_, _) {});
      await c.read(messageRequestsProvider.future);

      inbox.add(ChatInboxEvent(
        type: ChatEventType.message,
        conversationId: 'c1',
        message: msg('m5', content: 'asking again'),
      ));
      await pumpEventQueue();

      final rows = c.read(messageRequestsProvider).value!;
      expect(rows.map((r) => r.id), ['c1', 'r2']);
      expect(rows.first.lastMessageContent, 'asking again');
      expect(rows.first.hasUnread, isTrue);
      verify(() => repository.listRequests()).called(1);
    });

    test('a message in a thread neither list has fetches the box again; one '
        'in an inbox thread does not', () async {
      when(() => repository.listConversations()).thenAnswer((_) async => [
            ordinary.copyWith(id: 'c9'),
          ]);
      final c = container();
      c.listen(conversationsProvider, (_, _) {});
      c.listen(messageRequestsProvider, (_, _) {});
      await c.read(conversationsProvider.future);
      await c.read(messageRequestsProvider.future);

      inbox.add(ChatInboxEvent(
        type: ChatEventType.message,
        conversationId: 'c9',
        message: msg('m1').copyWith(conversationId: 'c9'),
      ));
      await pumpEventQueue();
      verify(() => repository.listRequests()).called(1);

      inbox.add(ChatInboxEvent(
        type: ChatEventType.message,
        conversationId: 'new',
        message: msg('m2').copyWith(conversationId: 'new'),
      ));
      await pumpEventQueue();
      await c.read(messageRequestsProvider.future);
      verify(() => repository.listRequests()).called(1);
    });
  });

  group('one conversation', () {
    test('a request is read from the box, not fetched', () async {
      when(() => repository.listRequests())
          .thenAnswer((_) async => [incoming('c1')]);
      final c = container();
      c.listen(conversationDetailProvider('c1'), (_, _) {});
      await c.read(conversationsProvider.future);
      await c.read(messageRequestsProvider.future);
      final detail = await c.read(conversationDetailProvider('c1').future);

      expect(detail?.sendPermission, SendPermission.awaitingAccept);
    });

    test('one in neither list (a request the caller deleted) is fetched',
        () async {
      when(() => repository.getConversation('c1')).thenAnswer((_) async =>
          thread(SendPermission.reopenOnSend,
              state: MessageRequestState.declined, initiator: '2002'));
      final c = container();
      c.listen(conversationDetailProvider('c1'), (_, _) {});
      await c.read(conversationsProvider.future);
      await c.read(messageRequestsProvider.future);
      final detail = await c.read(conversationDetailProvider('c1').future);

      expect(detail?.sendPermission, SendPermission.reopenOnSend);
    });

    test('sending the one request message closes the composer at once',
        () async {
      when(() => repository.listConversations()).thenAnswer(
          (_) async => [thread(SendPermission.firstMessageOnly)]);
      when(() => repository.sendMessage('c1', 'hi',
              clientRequestId: any(named: 'clientRequestId')))
          .thenAnswer((_) async => msg('m2', sender: '1001', content: 'hi'));
      final c = container();
      c.listen(conversationDetailProvider('c1'), (_, _) {});
      c.listen(threadProvider('c1'), (_, _) {});
      await c.read(conversationsProvider.future);
      await c.read(conversationDetailProvider('c1').future);
      await c.read(threadProvider('c1').future);

      await c.read(threadProvider('c1').notifier).send('hi');

      final detail = c.read(conversationDetailProvider('c1')).value!;
      expect(detail.sendPermission, SendPermission.requestSent);
      expect(detail.retryAvailableAt, t0.add(const Duration(days: 15)));
    });

    test('a send refused because the request changed asks the server again',
        () async {
      when(() => repository.listConversations()).thenAnswer(
          (_) async => [thread(SendPermission.firstMessageOnly)]);
      when(() => repository.sendMessage('c1', 'again',
              clientRequestId: any(named: 'clientRequestId')))
          .thenThrow(const ServerException(403, 'limit',
              code: 'MESSAGE_REQUEST_LIMIT_REACHED'));
      final c = container();
      c.listen(conversationDetailProvider('c1'), (_, _) {});
      c.listen(threadProvider('c1'), (_, _) {});
      await c.read(conversationsProvider.future);
      await c.read(threadProvider('c1').future);
      when(() => repository.listConversations()).thenAnswer((_) async => [
            thread(SendPermission.requestSent,
                retryAvailableAt: t0.add(const Duration(days: 15))),
          ]);

      await expectLater(
        c.read(threadProvider('c1').notifier).send('again'),
        throwsA(isA<ServerException>()),
      );
      await c.read(conversationsProvider.future);
      final detail = await c.read(conversationDetailProvider('c1').future);

      expect(detail?.sendPermission, SendPermission.requestSent);
      expect(requestErrorMessage(const ServerException(403, 'x',
              code: 'MESSAGE_REQUEST_LIMIT_REACHED')),
          'You can send more messages once this request is accepted');
    });
  });

  group('the chat screen', () {
    late GoRouter router;

    Future<void> pumpThread(WidgetTester tester) async {
      router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('request box'))),
        GoRoute(
            path: '/thread',
            builder: (_, _) => const ChatThreadScreen(conversationId: 'c1')),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: overrides(),
        child: MaterialApp.router(routerConfig: router),
      ));
      router.push('/thread');
      await tester.pumpAndSettle();
    }

    final composer = find.byKey(const Key('chat_composer_field'));

    testWidgets('a request received offers Delete / Accept, not a composer',
        (tester) async {
      when(() => repository.listRequests())
          .thenAnswer((_) async => [incoming('c1')]);
      var server = incoming('c1');
      when(() => repository.getConversation('c1'))
          .thenAnswer((_) async => server);
      when(() => repository.acceptRequest('c1')).thenAnswer((_) async {
        server = ordinary;
        return ordinary;
      });
      await pumpThread(tester);

      expect(find.byKey(const Key('request_prompt')), findsOneWidget);
      expect(find.text('Lan wants to send you a message'), findsOneWidget);
      expect(composer, findsNothing);

      await tester.tap(find.byKey(const Key('request_accept')));
      await tester.pumpAndSettle();

      verify(() => repository.acceptRequest('c1')).called(1);
      expect(find.byKey(const Key('request_prompt')), findsNothing);
      expect(composer, findsOneWidget);
    });

    testWidgets('Delete removes the request and goes back to the box',
        (tester) async {
      when(() => repository.listRequests())
          .thenAnswer((_) async => [incoming('c1')]);
      when(() => repository.getConversation('c1'))
          .thenAnswer((_) async => incoming('c1'));
      when(() => repository.declineRequest('c1')).thenAnswer((_) async =>
          thread(SendPermission.reopenOnSend,
              state: MessageRequestState.declined, initiator: '2002'));
      await pumpThread(tester);

      await tester.tap(find.byKey(const Key('request_delete')));
      await tester.pumpAndSettle();

      verify(() => repository.declineRequest('c1')).called(1);
      expect(find.text('request box'), findsOneWidget);
      expect(find.text('Request deleted'), findsOneWidget);
    });

    testWidgets('Report this user opens the chat report', (tester) async {
      when(() => repository.listRequests())
          .thenAnswer((_) async => [incoming('c1')]);
      when(() => repository.getConversation('c1'))
          .thenAnswer((_) async => incoming('c1'));
      await pumpThread(tester);

      await tester.tap(find.byKey(const Key('request_report')));
      await tester.pumpAndSettle();

      expect(find.byType(ReportConversationScreen), findsOneWidget);
    });

    testWidgets('the sender of a request waiting sees when they may ask again',
        (tester) async {
      final waiting = thread(SendPermission.requestSent,
          retryAvailableAt: DateTime(2026, 11, 21, 12));
      when(() => repository.listConversations())
          .thenAnswer((_) async => [waiting]);
      await pumpThread(tester);

      expect(find.text('Chat request sent'), findsOneWidget);
      expect(find.textContaining('Nov 21, 2026'), findsOneWidget);
      expect(composer, findsNothing);
    });

    testWidgets('a block pushed by the server closes the composer at once',
        (tester) async {
      when(() => repository.listConversations())
          .thenAnswer((_) async => [ordinary]);
      await pumpThread(tester);
      expect(composer, findsOneWidget);

      // The other side blocks: chat-service pushes the conversation again.
      when(() => repository.listConversations()).thenAnswer((_) async =>
          [ordinary.copyWith(blockedByViewer: false, messagingBlocked: true)]);
      inbox.add(const ChatInboxEvent(
          type: ChatEventType.conversation, conversationId: 'c1'));
      await tester.pumpAndSettle();

      expect(find.text('You can\'t message this account.'), findsOneWidget);
      expect(find.byKey(const Key('blocked_unblock')), findsNothing);
      expect(composer, findsNothing);
    });

    testWidgets('the caller\'s own block offers Unblock right there',
        (tester) async {
      var blocked = true;
      when(() => repository.listConversations()).thenAnswer((_) async => [
            ordinary.copyWith(
                blockedByViewer: blocked, messagingBlocked: blocked),
          ]);
      when(() => users.unblock('2002')).thenAnswer((_) async {
        blocked = false;
      });
      await pumpThread(tester);

      expect(find.textContaining('You blocked Lan'), findsOneWidget);
      expect(composer, findsNothing);

      await tester.tap(find.byKey(const Key('blocked_unblock')));
      await tester.pumpAndSettle();

      verify(() => users.unblock('2002')).called(1);
      expect(find.byKey(const Key('blocked_notice')), findsNothing);
      expect(composer, findsOneWidget);
    });

    testWidgets('the one request message is sent, then the notice takes over',
        (tester) async {
      when(() => repository.listConversations()).thenAnswer(
          (_) async => [thread(SendPermission.firstMessageOnly)]);
      when(() => repository.sendMessage('c1', 'hello there',
              clientRequestId: any(named: 'clientRequestId')))
          .thenAnswer((_) async =>
              msg('m2', sender: '1001', content: 'hello there'));
      await pumpThread(tester);

      expect(find.byKey(const Key('request_first_message_hint')),
          findsOneWidget);
      await tester.enterText(composer, 'hello there');
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pumpAndSettle();

      expect(find.text('Chat request sent'), findsOneWidget);
      expect(composer, findsNothing);
      expect(find.byKey(const Key('request_first_message_hint')),
          findsNothing);
    });

    testWidgets('writing into a request the caller deleted asks first',
        (tester) async {
      var server = thread(SendPermission.reopenOnSend,
          state: MessageRequestState.declined, initiator: '2002');
      when(() => repository.getConversation('c1'))
          .thenAnswer((_) async => server);
      when(() => repository.sendMessage('c1', 'ok, hi',
              clientRequestId: any(named: 'clientRequestId')))
          .thenAnswer((_) async {
        server = ordinary;
        return msg('m2', sender: '1001', content: 'ok, hi');
      });
      await pumpThread(tester);

      await tester.enterText(composer, 'ok, hi');
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pumpAndSettle();
      expect(find.text('Let Lan message you again?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reopen_cancel')));
      await tester.pumpAndSettle();
      verifyNever(() => repository.sendMessage(any(), any(),
          clientRequestId: any(named: 'clientRequestId')));
      expect(find.text('ok, hi'), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reopen_confirm')));
      await tester.pumpAndSettle();
      verify(() => repository.sendMessage('c1', 'ok, hi',
          clientRequestId: any(named: 'clientRequestId'))).called(1);

      // Open again: the next message goes straight through.
      await tester.enterText(composer, 'second');
      when(() => repository.sendMessage('c1', 'second',
              clientRequestId: any(named: 'clientRequestId')))
          .thenAnswer((_) async => msg('m3', sender: '1001', content: 'second'));
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pumpAndSettle();
      expect(find.text('Let Lan message you again?'), findsNothing);
    });
  });

  group('the Inbox', () {
    late MockNotificationRepository notifications;

    setUp(() {
      notifications = MockNotificationRepository();
      when(() => notifications.unreadCount()).thenAnswer((_) async => 0);
      when(() => notifications.list()).thenAnswer((_) async => []);
    });

    Future<void> pumpInbox(WidgetTester tester) async {
      final router = GoRouter(routes: [
        GoRoute(
            path: '/', builder: (_, _) => const Scaffold(body: InboxScreen())),
        GoRoute(
            path: '/messages/requests',
            builder: (_, _) => const MessageRequestsScreen()),
        GoRoute(
            path: '/messages/:id',
            builder: (_, state) => Text('thread ${state.pathParameters['id']}')),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...overrides(),
          notificationRepositoryProvider.overrideWithValue(notifications),
          storyTrayProvider.overrideWith(_EmptyStoryTray.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('has a Message requests entry while any wait', (tester) async {
      when(() => repository.listRequests()).thenAnswer((_) async => [
            incoming('r1'),
            incoming('r2', hasUnread: false),
          ]);
      await pumpInbox(tester);

      expect(find.text('Message requests'), findsOneWidget);
      expect(find.text('You have 2 requests'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('inbox_requests_unread')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('inbox_open_requests')));
      await tester.pumpAndSettle();

      expect(find.byType(MessageRequestsScreen), findsOneWidget);
      expect(find.byKey(const Key('conversation_unread_count_r1')),
          findsOneWidget);
      expect(find.byKey(const Key('conversation_unread_count_r2')),
          findsNothing);

      await tester.tap(find.byKey(const Key('conversation_r1')));
      await tester.pumpAndSettle();
      expect(find.text('thread r1'), findsOneWidget);
    });

    testWidgets('has no entry when nothing waits', (tester) async {
      await pumpInbox(tester);
      expect(find.byKey(const Key('inbox_open_requests')), findsNothing);
    });

    testWidgets('the box says so when it is empty', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: MessageRequestsScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('No message requests'), findsOneWidget);
    });
  });
}
