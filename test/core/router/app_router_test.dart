import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/router/app_router.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  testWidgets('redirects to /login when signed out and /feed is requested', (tester) async {
    final container = ProviderContainer(
      overrides: [authStateProvider.overrideWith(_SignedOutAuthState.new)],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);

    final router = container.read(appRouterProvider);
    router.go('/feed');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log in to TikTok'), findsOneWidget);
  });

  testWidgets('redirects to /feed when signed in and /login is requested', (tester) async {
    final feedRepository = MockFeedRepository();
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => const FeedPage(items: [], nextCursor: null),
    );
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_SignedInAuthState.new),
        feedRepositoryProvider.overrideWithValue(feedRepository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);

    final router = container.read(appRouterProvider);
    router.go('/login');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No videos yet'), findsOneWidget);
  });
}

class _SignedOutAuthState extends AuthState {
  @override
  FutureOr<UserModel?> build() => null;
}

class _SignedInAuthState extends AuthState {
  @override
  FutureOr<UserModel?> build() => UserModel(
        id: '1',
        username: 'jane',
        email: 'jane@test.com',
        role: UserRole.user,
        status: UserStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );
}
