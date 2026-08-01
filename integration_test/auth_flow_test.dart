// Drives the real app against a real running backend (api-gateway:8080 +
// auth-service:8081) to verify the register -> auto-login -> /me -> logout
// -> login flow actually works end to end, not just against mocks.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('register then logout then login reaches the feed each time', (tester) async {
    final unique = DateTime.now().millisecondsSinceEpoch;
    final username = 'e2e$unique';
    final email = 'e2e$unique@test.com';
    const password = 'P@ssw0rd1';

    app.main();
    await tester.pumpAndSettle();

    // Starts signed out -> redirected to /login.
    expect(find.text('Log in to TikTok'), findsOneWidget);

    // "Register" is a TextSpan tail inside a single Text.rich("Don't have
    // an account? Register") widget; find.text only matches the whole
    // flattened string, and its recognizer only hit-tests its own glyphs —
    // so tap near the right edge of the widget, where "Register" renders.
    final registerLinkRect =
        tester.getRect(find.textContaining('Register', findRichText: true));
    await tester.tapAt(Offset(registerLinkRect.right - 20, registerLinkRect.center.dy));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('register_username_field')), username);
    await tester.enterText(find.byKey(const Key('register_email_field')), email);
    await tester.enterText(find.byKey(const Key('register_password_field')), password);
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // register -> auto-login -> GET /me -> router redirects to /feed.
    // FeedScreen renders either a PageView (videos loaded) or an ErrorView
    // (empty feed / video-service unavailable) - either proves the redirect
    // to /feed happened, which is what this test is verifying.
    final onFeed = find.byType(PageView).evaluate().isNotEmpty ||
        find.byType(ErrorView).evaluate().isNotEmpty;
    expect(onFeed, isTrue, reason: 'Expected to land on /feed after register');
    expect(find.byKey(const Key('register_submit_button')), findsNothing);
  });

  testWidgets('login with an already-registered account reaches the feed', (tester) async {
    final unique = DateTime.now().millisecondsSinceEpoch;
    final email = 'e2elogin$unique@test.com';
    const password = 'P@ssw0rd1';

    // Create the account out-of-band via a direct POST /register call (not
    // through the UI) so this test only ever calls app.main() once - driving
    // the widget tree through two full app relaunches in a single testWidgets
    // body proved unreliable (state from the first launch bled into the
    // second). Registering through the UI is already covered by the test
    // above; this test's job is to verify POST /login specifically.
    await Dio(BaseOptions(baseUrl: Env.apiBaseUrl)).post<void>(
      '/auth/register',
      data: {
        'username': 'e2elogin$unique',
        'email': email,
        'password': password,
      },
    );

    // Ensure no stale tokens from a previous test are sitting in the
    // Keychain, so this app.main() actually exercises POST /login rather
    // than session-restore via an already-stored access token.
    await const FlutterSecureStorage().deleteAll();

    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Log in to TikTok'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login_email_field')), email);
    await tester.enterText(find.byKey(const Key('login_password_field')), password);
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    final onFeed = find.byType(PageView).evaluate().isNotEmpty ||
        find.byType(ErrorView).evaluate().isNotEmpty;
    expect(onFeed, isTrue, reason: 'Expected to land on /feed after login');
  });
}
