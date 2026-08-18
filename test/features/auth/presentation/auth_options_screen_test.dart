import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/router/app_router.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/social_sign_in.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

/// What the provider buttons do with each way a social login can end. Driven
/// through the real router, because the interesting part is where each outcome
/// lands rather than what the repository was asked for.
void main() {
  late MockAuthRepository authRepository;
  late MockTokenStorage tokenStorage;

  setUp(() {
    authRepository = MockAuthRepository();
    tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
  });

  Future<void> pumpLoginOptions(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        tokenStorageProvider.overrideWithValue(tokenStorage),
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
  }

  testWidgets('an address owned by another account opens the confirm screen',
      (tester) async {
    // The catch arm for this has to sit above the AppException one, which it is
    // a subtype of. Get the order wrong and the challenge is downgraded to a
    // toast: the user is stuck, and the provider token goes with the screen.
    when(() => authRepository.loginWithFacebook()).thenThrow(
      const SocialLinkRequired(
        provider: 'facebook',
        token: 'fb-token',
        message: 'Enter the code we emailed to confirm this address is yours',
      ),
    );

    await pumpLoginOptions(tester);
    await tester.tap(find.byKey(const Key('login_option_facebook')));
    await tester.pumpAndSettle();

    expect(find.text("Confirm it's you"), findsOneWidget);
  });

  testWidgets('backing out of the provider sheet says nothing at all',
      (tester) async {
    // Cancelling is a decision, not a failure. A snackbar here would accuse the
    // user of an error they did not make.
    when(() => authRepository.loginWithGoogle())
        .thenThrow(const SocialSignInCancelled());

    await pumpLoginOptions(tester);
    await tester.tap(find.byKey(const Key('login_option_google')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Log in to TikTok'), findsOneWidget);
  });

  testWidgets('a real failure is reported without leaving the screen',
      (tester) async {
    when(() => authRepository.loginWithGoogle())
        .thenThrow(const NetworkException());

    await pumpLoginOptions(tester);
    await tester.tap(find.byKey(const Key('login_option_google')));
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Log in to TikTok'), findsOneWidget);
  });
}
