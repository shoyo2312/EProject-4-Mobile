import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/router/app_router.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

/// Without this the signed-out bootstrap reaches the real SecureTokenStorage
/// and waits forever on a platform channel no widget test answers.
class MockTokenStorage extends Mock implements TokenStorage {}

/// Driven through the real router rather than a bare `home:` widget: the screen
/// only ever arrives carrying a challenge in `extra`, and what happens when it
/// arrives without one is half of what is worth testing here.
void main() {
  const challenge = SocialLinkRequired(
    provider: 'facebook',
    token: 'fb-token',
    message: 'Enter the code we emailed to confirm this address is yours',
  );

  final user = UserModel(
    id: '1',
    username: 'jane',
    email: 'jane@test.com',
    role: UserRole.user,
    status: UserStatus.active,
    emailVerified: true,
    createdAt: DateTime(2026, 1, 1),
  );

  late MockAuthRepository authRepository;
  late MockTokenStorage tokenStorage;

  setUp(() {
    authRepository = MockAuthRepository();
    tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
  });

  /// Boots the app signed out at [location], with an empty feed behind it so
  /// the page a successful link lands on renders something assertable.
  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    Object? extra,
  }) async {
    final feedRepository = MockFeedRepository();
    when(() => feedRepository.fetchFeed()).thenAnswer(
      (_) async => const VideoPage(items: []),
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        tokenStorageProvider.overrideWithValue(tokenStorage),
        feedRepositoryProvider.overrideWithValue(feedRepository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);

    final router = container.read(appRouterProvider);
    router.go(location, extra: extra);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the mailed code is spent together with the provider token',
      (tester) async {
    // Both halves or nothing: the code alone proves only that someone can read
    // the mailbox, so the token from the rejected login has to reach the server
    // again. Dropping it is what would end in a second account.
    when(() => authRepository.confirmSocialLink(
          provider: 'facebook',
          token: 'fb-token',
          otp: '123456',
        )).thenAnswer((_) async => (user: user, requiresEmail: false));

    await pumpAt(tester, '/social-link', extra: challenge);

    await tester.enterText(
      find.byKey(const Key('social_link_otp_field')),
      '123456',
    );
    // The button only turns actionable on the frame after the last keystroke.
    await tester.pump();
    await tester.tap(find.byKey(const Key('social_link_submit_button')));
    await tester.pumpAndSettle();

    verify(() => authRepository.confirmSocialLink(
          provider: 'facebook',
          token: 'fb-token',
          otp: '123456',
        )).called(1);
    expect(find.text('No videos yet'), findsOneWidget);
  });

  testWidgets('a rejected code keeps the screen, and with it the challenge',
      (tester) async {
    // Leaving on a wrong code would throw the provider token away, and it
    // cannot be re-obtained without sending the user through Facebook again.
    when(() => authRepository.confirmSocialLink(
          provider: 'facebook',
          token: 'fb-token',
          otp: '000000',
        )).thenThrow(
      const ServerException(400, 'Invalid or expired code', code: 'INVALID_OTP'),
    );

    await pumpAt(tester, '/social-link', extra: challenge);

    await tester.enterText(
      find.byKey(const Key('social_link_otp_field')),
      '000000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('social_link_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid or expired code'), findsOneWidget);
    expect(find.text("Confirm it's you"), findsOneWidget);
  });

  testWidgets('the code field takes six digits and nothing else',
      (tester) async {
    // The number keyboard is a hint, not a rule — a paste or a hardware
    // keyboard walks past it, and the server only ever accepts \d{6}.
    await pumpAt(tester, '/social-link', extra: challenge);

    await tester.enterText(
      find.byKey(const Key('social_link_otp_field')),
      'a1b2c3d4e5',
    );
    await tester.pump();

    expect(find.text('12345'), findsOneWidget);

    await tester.tap(find.byKey(const Key('social_link_submit_button')));
    await tester.pumpAndSettle();

    verifyNever(() => authRepository.confirmSocialLink(
          provider: any(named: 'provider'),
          token: any(named: 'token'),
          otp: any(named: 'otp'),
        ));
  });

  testWidgets('without a challenge the screen is not reachable at all',
      (tester) async {
    // A hot restart or a hand-typed link arrives with no `extra`. There is
    // nothing to confirm without the token, and the builder's cast would
    // otherwise blow up on null.
    await pumpAt(tester, '/social-link');

    expect(find.text('Log in to TikTok'), findsOneWidget);
    expect(find.text("Confirm it's you"), findsNothing);
  });
}
