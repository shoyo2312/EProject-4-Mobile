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
import 'package:tiktok_mobile/features/inbox/presentation/inbox_screen.dart';
import 'package:tiktok_mobile/features/notification/data/notification_model.dart';
import 'package:tiktok_mobile/features/notification/data/notification_repository.dart';
import 'package:tiktok_mobile/features/notification/presentation/notification_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class _SignedInAuthState extends AuthState {
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

class _SignedOutAuthState extends AuthState {
  @override
  FutureOr<UserModel?> build() => null;
}

class _EmptyStoryTray extends StoryTray {
  @override
  FutureOr<List<StoryGroup>> build() => const [];
}

NotificationModel notification(
  String id, {
  required String title,
  bool read = false,
}) => NotificationModel(
  id: id,
  type: NotificationKind.like,
  title: title,
  body: 'did something',
  read: read,
  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
);

ConversationModel conversation(String id, {String last = 'hi'}) =>
    ConversationModel(
      id: id,
      participantIds: const ['1001', '2002'],
      lastMessageContent: last,
      createdAt: DateTime(2026, 8, 1),
    );

void main() {
  late MockNotificationRepository notifications;
  late MockChatRepository chat;
  late MockUserRepository users;

  setUp(() {
    notifications = MockNotificationRepository();
    chat = MockChatRepository();
    users = MockUserRepository();
    when(() => notifications.unreadCount()).thenAnswer((_) async => 0);
    when(() => notifications.list()).thenAnswer((_) async => []);
    when(() => chat.inboxEvents()).thenAnswer((_) => const Stream.empty());
    when(() => chat.listConversations()).thenAnswer((_) async => []);
    when(() => chat.listRequests()).thenAnswer((_) async => []);
    when(
      () => users.getProfiles(any()),
    ).thenAnswer((_) async => <String, UserProfileModel>{});
  });

  Future<void> pumpInbox(WidgetTester tester, {bool signedIn = true}) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: InboxScreen()),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const Text('notifications page'),
        ),
        GoRoute(
          path: '/profile/:userId',
          builder: (_, state) =>
              Text('profile ${state.pathParameters['userId']}'),
        ),
        GoRoute(
          path: '/messages/:id',
          builder: (_, state) => Text('thread ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            signedIn ? _SignedInAuthState.new : _SignedOutAuthState.new,
          ),
          notificationRepositoryProvider.overrideWithValue(notifications),
          chatRepositoryProvider.overrideWithValue(chat),
          userRepositoryProvider.overrideWithValue(users),
          storyTrayProvider.overrideWith(_EmptyStoryTray.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists conversations under a single Activity entry', (
    tester,
  ) async {
    when(() => chat.listConversations()).thenAnswer(
      (_) async => [
        conversation('c1', last: 'see you tomorrow'),
        conversation('c2', last: 'lol'),
      ],
    );
    when(() => notifications.list()).thenAnswer(
      (_) async => [
        notification('n1', title: 'Benri liked your video'),
        notification('n2', title: 'Welcome!', read: true),
      ],
    );

    await pumpInbox(tester);

    expect(find.byKey(const Key('inbox_open_activity')), findsOneWidget);
    // Only the newest notification shows, as the entry's preview.
    expect(find.textContaining('Benri liked your video'), findsOneWidget);
    expect(find.textContaining('Welcome!'), findsNothing);
    expect(find.text('see you tomorrow'), findsOneWidget);
    expect(find.text('lol'), findsOneWidget);
  });

  testWidgets('the Activity entry counts unread notifications', (tester) async {
    when(() => notifications.list()).thenAnswer(
      (_) async => [
        notification('n1', title: 'a'),
        notification('n2', title: 'b'),
        notification('n3', title: 'c', read: true),
      ],
    );

    await pumpInbox(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('inbox_activity_unread')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no badge when everything is read', (tester) async {
    when(
      () => notifications.list(),
    ).thenAnswer((_) async => [notification('n1', title: 'a', read: true)]);

    await pumpInbox(tester);

    expect(find.byKey(const Key('inbox_activity_unread')), findsNothing);
  });

  testWidgets('tapping Activity opens the notification list', (tester) async {
    await pumpInbox(tester);
    await tester.tap(find.byKey(const Key('inbox_open_activity')));
    await tester.pumpAndSettle();

    expect(find.text('notifications page'), findsOneWidget);
  });

  testWidgets('tapping a conversation opens its thread', (tester) async {
    when(
      () => chat.listConversations(),
    ).thenAnswer((_) async => [conversation('c1')]);

    await pumpInbox(tester);
    await tester.tap(find.byKey(const Key('conversation_c1')));
    await tester.pumpAndSettle();

    expect(find.text('thread c1'), findsOneWidget);
  });

  testWidgets('no conversations yet still shows the Activity entry', (
    tester,
  ) async {
    await pumpInbox(tester);

    expect(find.byKey(const Key('inbox_open_activity')), findsOneWidget);
    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets('a guest is asked to sign in, not shown an error', (
    tester,
  ) async {
    await pumpInbox(tester, signedIn: false);

    expect(
      find.text('Sign in to see your messages and activity'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inbox_open_activity')), findsNothing);
    verifyNever(() => notifications.list());
    verifyNever(() => chat.listConversations());
  });

  group('long press on a conversation', () {
    setUp(() {
      when(
        () => chat.listConversations(),
      ).thenAnswer((_) async => [conversation('c1')]);
    });

    Future<void> longPress(WidgetTester tester) async {
      await pumpInbox(tester);
      await tester.longPress(find.byKey(const Key('conversation_c1')));
      await tester.pumpAndSettle();
    }

    testWidgets('offers mute, profile and block', (tester) async {
      await longPress(tester);

      expect(find.text('Mute notifications'), findsOneWidget);
      expect(find.text('View profile'), findsOneWidget);
      expect(find.text('Block'), findsOneWidget);
    });

    testWidgets("mute reuses the thread's mute lengths", (tester) async {
      when(() => chat.mute('c1', MuteLength.eightHours)).thenAnswer(
        (_) async => conversation('c1').copyWith(
          muteMode: MuteMode.timed,
          mutedUntil: DateTime.now().add(const Duration(hours: 8)),
        ),
      );

      await longPress(tester);
      await tester.tap(find.byKey(const Key('conversation_action_mute')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat_mute_eightHours')));
      await tester.pumpAndSettle();

      verify(() => chat.mute('c1', MuteLength.eightHours)).called(1);
      // The row now carries the muted icon.
      expect(find.byKey(const Key('conversation_muted_c1')), findsOneWidget);
    });

    testWidgets('a muted thread offers unmute instead', (tester) async {
      final muted = conversation('c1').copyWith(muteMode: MuteMode.indefinite);
      when(() => chat.listConversations()).thenAnswer((_) async => [muted]);
      when(() => chat.unmute('c1')).thenAnswer((_) async => conversation('c1'));

      await longPress(tester);
      expect(find.text('Unmute notifications'), findsOneWidget);
      await tester.tap(find.byKey(const Key('conversation_action_mute')));
      await tester.pumpAndSettle();

      verify(() => chat.unmute('c1')).called(1);
      expect(find.byKey(const Key('conversation_muted_c1')), findsNothing);
    });

    testWidgets('block asks first, then blocks the other person', (
      tester,
    ) async {
      when(() => users.block('2002')).thenAnswer((_) async {});

      await longPress(tester);
      await tester.tap(find.byKey(const Key('conversation_action_block')));
      await tester.pumpAndSettle();
      verifyNever(() => users.block(any()));

      await tester.tap(find.byKey(const Key('conversation_block_confirm')));
      await tester.pumpAndSettle();

      verify(() => users.block('2002')).called(1);
    });

    testWidgets('an already-blocked user is not reported as an error', (
      tester,
    ) async {
      when(() => users.block('2002')).thenThrow(
        const ServerException(409, 'Already blocked', code: 'ALREADY_BLOCKED'),
      );

      await longPress(tester);
      await tester.tap(find.byKey(const Key('conversation_action_block')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('conversation_block_confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Already blocked'), findsNothing);
      expect(find.textContaining('blocked'), findsOneWidget);
    });

    testWidgets('view profile opens the other person', (tester) async {
      await longPress(tester);
      await tester.tap(find.byKey(const Key('conversation_action_profile')));
      await tester.pumpAndSettle();

      expect(find.text('profile 2002'), findsOneWidget);
    });
  });

  group('pinning from the long press', () {
    ConversationModel at(String id, int day, {DateTime? pinnedAt}) =>
        conversation(
          id,
        ).copyWith(lastMessageAt: DateTime(2026, 9, day), pinnedAt: pinnedAt);

    double top(WidgetTester tester, String id) =>
        tester.getTopLeft(find.byKey(Key('conversation_$id'))).dy;

    Future<void> choosePinFor(WidgetTester tester, String id) async {
      await tester.longPress(find.byKey(Key('conversation_$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('conversation_action_pin')));
      await tester.pumpAndSettle();
    }

    testWidgets('pin to top moves the thread above the others', (tester) async {
      final c2 = at('c2', 1);
      when(
        () => chat.listConversations(),
      ).thenAnswer((_) async => [at('c1', 5), c2]);
      when(
        () => chat.pin('c2'),
      ).thenAnswer((_) async => c2.copyWith(pinnedAt: DateTime(2026, 9, 6)));

      await pumpInbox(tester);
      expect(top(tester, 'c1'), lessThan(top(tester, 'c2')));

      await choosePinFor(tester, 'c2');

      verify(() => chat.pin('c2')).called(1);
      expect(top(tester, 'c2'), lessThan(top(tester, 'c1')));
      expect(find.byKey(const Key('conversation_pinned_c2')), findsOneWidget);
    });

    testWidgets('a pinned thread offers unpin', (tester) async {
      final c2 = at('c2', 1, pinnedAt: DateTime(2026, 9, 6));
      when(
        () => chat.listConversations(),
      ).thenAnswer((_) async => [c2, at('c1', 5)]);
      when(
        () => chat.unpin('c2'),
      ).thenAnswer((_) async => c2.copyWith(pinnedAt: null));

      await pumpInbox(tester);
      await tester.longPress(find.byKey(const Key('conversation_c2')));
      await tester.pumpAndSettle();
      expect(find.text('Unpin'), findsOneWidget);
      await tester.tap(find.byKey(const Key('conversation_action_pin')));
      await tester.pumpAndSettle();

      verify(() => chat.unpin('c2')).called(1);
      expect(top(tester, 'c1'), lessThan(top(tester, 'c2')));
      expect(find.byKey(const Key('conversation_pinned_c2')), findsNothing);
    });

    testWidgets('a sixth pin is refused without asking the server', (
      tester,
    ) async {
      when(() => chat.listConversations()).thenAnswer(
        (_) async => [
          for (var i = 1; i <= 5; i++)
            at('p$i', 1, pinnedAt: DateTime(2026, 9, 10 - i)),
          at('c6', 2),
        ],
      );

      // Tall enough for all six rows to be on screen at once.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpInbox(tester);
      await choosePinFor(tester, 'c6');

      verifyNever(() => chat.pin(any()));
      expect(find.textContaining('pin up to 5 conversations'), findsOneWidget);
    });

    testWidgets('the server refusing a pin says why', (tester) async {
      when(
        () => chat.listConversations(),
      ).thenAnswer((_) async => [at('c1', 1)]);
      when(
        () => chat.pin('c1'),
      ).thenThrow(const ServerException(409, 'raw', code: 'PIN_LIMIT_REACHED'));

      await pumpInbox(tester);
      await choosePinFor(tester, 'c1');

      expect(find.textContaining('pin up to 5 conversations'), findsOneWidget);
      expect(find.text('raw'), findsNothing);
    });
  });
}
