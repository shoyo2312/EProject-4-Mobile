import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/router/app_router.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

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

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('redirects to /feed when signed in and /login is requested', (tester) async {
    final container = ProviderContainer(
      overrides: [authStateProvider.overrideWith(_SignedInAuthState.new)],
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

    expect(find.text('Feed'), findsOneWidget);
  });
}

class _SignedOutAuthState extends AuthState {
  @override
  FutureOr<UserModel?> build() => null;
}

class _SignedInAuthState extends AuthState {
  @override
  FutureOr<UserModel?> build() => const UserModel(
        id: '1',
        username: 'jane',
        email: 'jane@test.com',
      );
}
