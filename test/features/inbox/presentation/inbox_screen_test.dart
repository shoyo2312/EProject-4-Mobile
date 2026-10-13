import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/inbox/presentation/inbox_screen.dart';
import 'package:tiktok_mobile/features/notification/data/notification_model.dart';
import 'package:tiktok_mobile/features/notification/data/notification_repository.dart';
import 'package:tiktok_mobile/features/notification/presentation/notification_provider.dart';

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
}) =>
    NotificationModel(
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

  Future<void> pumpInbox(WidgetTester tester, {bool signedIn = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            signedIn ? _SignedInAuthState.new : _SignedOutAuthState.new,
          ),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: InboxScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the rows the service returned', (tester) async {
    when(() => repository.list()).thenAnswer((_) async => [
          row('n1', type: NotificationKind.like, title: 'Benri Studio'),
          row('n2', type: NotificationKind.system, title: 'Welcome to TikTok!'),
        ]);

    await pumpInbox(tester);

    expect(find.text('Benri Studio'), findsOneWidget);
    expect(find.text('Welcome to TikTok!'), findsOneWidget);
  });

  testWidgets('a filter chip keeps only its own type', (tester) async {
    when(() => repository.list()).thenAnswer((_) async => [
          row('n1', type: NotificationKind.like, title: 'a liker'),
          row('n2', type: NotificationKind.comment, title: 'a commenter'),
        ]);

    await pumpInbox(tester);
    await tester.tap(find.text('Likes'));
    await tester.pumpAndSettle();

    expect(find.text('a liker'), findsOneWidget);
    expect(find.text('a commenter'), findsNothing);
  });

  testWidgets('tapping a row marks it read', (tester) async {
    when(() => repository.list()).thenAnswer(
        (_) async => [row('n1', type: NotificationKind.like, title: 'a liker')]);
    when(() => repository.markRead('n1')).thenAnswer((_) async {});

    await pumpInbox(tester);
    await tester.tap(find.byKey(const Key('inbox_row_n1')));
    await tester.pumpAndSettle();

    verify(() => repository.markRead('n1')).called(1);
  });

  testWidgets('mark all read is offered only while something is unread',
      (tester) async {
    when(() => repository.list()).thenAnswer((_) async =>
        [row('n1', type: NotificationKind.like, title: 'a liker', read: true)]);

    await pumpInbox(tester);

    expect(find.byKey(const Key('inbox_mark_all_read')), findsNothing);
  });

  testWidgets('a guest is asked to sign in, not shown an error',
      (tester) async {
    await pumpInbox(tester, signedIn: false);

    expect(find.text('Sign in to see your notifications'), findsOneWidget);
    verifyNever(() => repository.list());
  });
}
