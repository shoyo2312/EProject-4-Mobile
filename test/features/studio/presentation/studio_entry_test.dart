import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/user/presentation/profile_screen.dart';
import 'package:tiktok_mobile/mock/mock_backend.dart';

/// Studio is reached from the profile menu, the way TikTok's creator tools
/// are.
void main() {
  testWidgets('the profile menu opens Nowa Studio', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: ProfileScreen(embedded: true)),
        ),
        GoRoute(path: '/studio', builder: (_, _) => const Text('page /studio')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_menu_studio')));
    await tester.pumpAndSettle();

    expect(find.text('page /studio'), findsOneWidget);
  });
}
