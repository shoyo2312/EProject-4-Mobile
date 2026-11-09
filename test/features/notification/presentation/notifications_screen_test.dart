import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/notification/data/notification_model.dart';
import 'package:tiktok_mobile/features/notification/data/notification_repository.dart';
import 'package:tiktok_mobile/features/notification/presentation/notification_provider.dart';
import 'package:tiktok_mobile/features/notification/presentation/notifications_screen.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

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

NotificationModel row(
  String id, {
  required NotificationKind type,
  required String title,
  bool read = false,
}) => NotificationModel(
  id: id,
  type: type,
  title: title,
  body: 'did something',
  read: read,
  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
);

void main() {
  late MockNotificationRepository repository;

  setUp(() {
    repository = MockNotificationRepository();
    when(() => repository.unreadCount()).thenAnswer((_) async => 0);
  });

  Future<void> pumpScreen(WidgetTester tester, {bool signedIn = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            signedIn ? _SignedInAuthState.new : _SignedOutAuthState.new,
          ),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the rows the service returned', (tester) async {
    when(() => repository.list()).thenAnswer(
      (_) async => [
        row('n1', type: NotificationKind.like, title: 'Benri Studio'),
        row('n2', type: NotificationKind.system, title: 'Welcome to TikTok!'),
      ],
    );

    await pumpScreen(tester);

    expect(find.text('Benri Studio'), findsOneWidget);
    expect(find.text('Welcome to TikTok!'), findsOneWidget);
  });

  testWidgets('a filter chip keeps only its own type', (tester) async {
    when(() => repository.list()).thenAnswer(
      (_) async => [
        row('n1', type: NotificationKind.like, title: 'a liker'),
        row('n2', type: NotificationKind.comment, title: 'a commenter'),
      ],
    );

    await pumpScreen(tester);
    await tester.tap(find.text('Likes'));
    await tester.pumpAndSettle();

    expect(find.text('a liker'), findsOneWidget);
    expect(find.text('a commenter'), findsNothing);
  });

  testWidgets('tapping a row marks it read', (tester) async {
    when(() => repository.list()).thenAnswer(
      (_) async => [row('n1', type: NotificationKind.like, title: 'a liker')],
    );
    when(() => repository.markRead('n1')).thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('notification_row_n1')));
    await tester.pumpAndSettle();

    verify(() => repository.markRead('n1')).called(1);
  });

  testWidgets('mark all read is offered only while something is unread', (
    tester,
  ) async {
    when(() => repository.list()).thenAnswer(
      (_) async => [
        row('n1', type: NotificationKind.like, title: 'a liker', read: true),
      ],
    );

    await pumpScreen(tester);

    expect(find.byKey(const Key('notifications_mark_all_read')), findsNothing);
  });

  testWidgets('a guest sees an empty list, not an error', (tester) async {
    await pumpScreen(tester, signedIn: false);

    expect(find.text('Nothing here yet'), findsOneWidget);
    verifyNever(() => repository.list());
  });

  testWidgets('mark all read clears every dot', (tester) async {
    when(() => repository.list()).thenAnswer(
      (_) async => [row('n1', type: NotificationKind.like, title: 'a liker')],
    );
    when(() => repository.markAllRead()).thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('notifications_mark_all_read')));
    await tester.pumpAndSettle();

    verify(() => repository.markAllRead()).called(1);
    expect(find.byKey(const Key('notifications_mark_all_read')), findsNothing);
  });

  testWidgets('a comment notification opens its video with comments', (
    tester,
  ) async {
    when(() => repository.list()).thenAnswer(
      (_) async => [
        row(
          'n1',
          type: NotificationKind.comment,
          title: 'New comment',
        ).copyWith(referenceId: 'v9'),
      ],
    );
    when(() => repository.markRead('n1')).thenAnswer((_) async {});
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NotificationsScreen()),
        GoRoute(
          path: '/video/:videoId',
          builder: (_, state) => Text(
            'video ${state.pathParameters['videoId']} '
            'comments=${state.uri.queryParameters['comments']}',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_SignedInAuthState.new),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notification_row_n1')));
    await tester.pumpAndSettle();

    expect(find.text('video v9 comments=1'), findsOneWidget);
  });

  test('reads COMMENT_LIKE and REPOST as their own types', () {
    NotificationKind parse(String type) => NotificationModel.fromJson({
      'id': 'n1',
      'type': type,
      'title': 't',
      'body': 'b',
      'read': false,
      'createdAt': '2026-11-08T10:00:00Z',
    }).type;

    expect(parse('COMMENT_LIKE'), NotificationKind.commentLike);
    expect(parse('REPOST'), NotificationKind.repost);
    expect(parse('SOMETHING_NEW'), NotificationKind.system);
  });

  testWidgets('the Likes chip keeps likes on comments too', (tester) async {
    when(() => repository.list()).thenAnswer(
      (_) async => [
        row('n1', type: NotificationKind.commentLike, title: 'a comment liker'),
        row('n2', type: NotificationKind.repost, title: 'a reposter'),
      ],
    );

    await pumpScreen(tester);
    await tester.tap(find.text('Likes'));
    await tester.pumpAndSettle();

    expect(find.text('a comment liker'), findsOneWidget);
    expect(find.text('a reposter'), findsNothing);
  });

  Future<void> pumpRouted(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NotificationsScreen()),
        GoRoute(
          path: '/video/:videoId',
          builder: (_, state) => Text(
            'video ${state.pathParameters['videoId']} '
            'comments=${state.uri.queryParameters['comments']}',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_SignedInAuthState.new),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notification_row_n1')));
    await tester.pumpAndSettle();
  }

  testWidgets('a like on a comment opens its video with comments', (
    tester,
  ) async {
    when(() => repository.list()).thenAnswer(
      (_) async => [
        row(
          'n1',
          type: NotificationKind.commentLike,
          title: 'New like',
        ).copyWith(referenceId: 'v9'),
      ],
    );
    when(() => repository.markRead('n1')).thenAnswer((_) async {});

    await pumpRouted(tester);

    expect(find.text('video v9 comments=1'), findsOneWidget);
  });

  testWidgets('a repost opens the reposted video', (tester) async {
    when(() => repository.list()).thenAnswer(
      (_) async => [
        row(
          'n1',
          type: NotificationKind.repost,
          title: 'New repost',
        ).copyWith(referenceId: 'v7'),
      ],
    );
    when(() => repository.markRead('n1')).thenAnswer((_) async {});

    await pumpRouted(tester);

    expect(find.text('video v7 comments=null'), findsOneWidget);
  });
}
