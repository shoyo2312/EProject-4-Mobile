import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
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

NotificationModel row(String id, {bool read = false}) => NotificationModel(
      id: id,
      type: NotificationKind.like,
      title: 'someone',
      body: 'liked your video',
      read: read,
      createdAt: DateTime(2026, 9, 1),
    );

void main() {
  late MockNotificationRepository repository;

  setUp(() {
    repository = MockNotificationRepository();
  });

  ProviderContainer containerFor({required bool signedIn}) {
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith(
        signedIn ? _SignedInAuthState.new : _SignedOutAuthState.new,
      ),
      notificationRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('a guest gets an empty inbox instead of a 401', () async {
    final container = containerFor(signedIn: false);

    expect(await container.read(inboxProvider.future), isEmpty);
    expect(await container.read(unreadCountProvider.future), 0);
    verifyNever(() => repository.list());
    verifyNever(() => repository.unreadCount());
  });

  test('marking one read clears its dot and refreshes the badge', () async {
    when(() => repository.list())
        .thenAnswer((_) async => [row('n1'), row('n2')]);
    when(() => repository.markRead('n1')).thenAnswer((_) async {});
    var count = 2;
    when(() => repository.unreadCount()).thenAnswer((_) async => count);

    final container = containerFor(signedIn: true);
    await container.read(inboxProvider.future);
    expect(await container.read(unreadCountProvider.future), 2);

    count = 1;
    await container.read(inboxProvider.notifier).markRead('n1');

    final rows = container.read(inboxProvider).value!;
    expect(rows.firstWhere((n) => n.id == 'n1').read, isTrue);
    expect(rows.firstWhere((n) => n.id == 'n2').read, isFalse);
    // The badge is re-read from the server, not decremented locally: the same
    // account may be reading the inbox on another device.
    expect(await container.read(unreadCountProvider.future), 1);
  });

  test('a rejected mark-read puts the dot back', () async {
    when(() => repository.list()).thenAnswer((_) async => [row('n1')]);
    when(() => repository.unreadCount()).thenAnswer((_) async => 1);
    when(() => repository.markRead('n1'))
        .thenThrow(const NetworkException());

    final container = containerFor(signedIn: true);
    await container.read(inboxProvider.future);

    await expectLater(
      container.read(inboxProvider.notifier).markRead('n1'),
      throwsA(isA<NetworkException>()),
    );
    expect(container.read(inboxProvider).value!.single.read, isFalse);
  });

  test('mark-all-read asks once, not once per row', () async {
    when(() => repository.list())
        .thenAnswer((_) async => [row('n1'), row('n2'), row('n3', read: true)]);
    when(() => repository.unreadCount()).thenAnswer((_) async => 2);
    when(() => repository.markAllRead()).thenAnswer((_) async {});

    final container = containerFor(signedIn: true);
    await container.read(inboxProvider.future);
    await container.read(inboxProvider.notifier).markAllRead();

    expect(container.read(inboxProvider).value!.every((n) => n.read), isTrue);
    verify(() => repository.markAllRead()).called(1);
    verifyNever(() => repository.markRead(any()));
  });

  test('mark-all-read on an already-read inbox is not a request', () async {
    when(() => repository.list())
        .thenAnswer((_) async => [row('n1', read: true)]);
    when(() => repository.unreadCount()).thenAnswer((_) async => 0);

    final container = containerFor(signedIn: true);
    await container.read(inboxProvider.future);
    await container.read(inboxProvider.notifier).markAllRead();

    verifyNever(() => repository.markAllRead());
  });
}
