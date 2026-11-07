import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/user/presentation/profile_screen.dart';
import 'package:tiktok_mobile/mock/mock_backend.dart';

void main() {
  Future<void> pumpProfile(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: ProfileScreen(embedded: true)),
        ),
        for (final path in [
          '/profile/edit',
          '/me/blocked',
          '/me/comment-filters',
          '/me/qr-login',
          '/me/devices',
        ])
          GoRoute(path: path, builder: (_, _) => Text('page $path')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('own profile keeps its actions in the corner menu', (
    tester,
  ) async {
    await pumpProfile(tester);

    // No row of buttons under the bio any more, and no mute at all.
    expect(find.byKey(const Key('profile_edit_button')), findsNothing);
    expect(find.byKey(const Key('profile_muted_list_button')), findsNothing);

    await tester.tap(find.byKey(const Key('profile_menu_button')));
    await tester.pumpAndSettle();

    for (final key in [
      'profile_menu_edit',
      'profile_menu_blocked',
      'profile_menu_comment_filters',
      'profile_menu_qr_login',
      'profile_menu_devices',
      'profile_menu_logout',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(find.text('Muted accounts'), findsNothing);
  });

  testWidgets('a menu item opens its page', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.byKey(const Key('profile_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_menu_edit')));
    await tester.pumpAndSettle();

    expect(find.text('page /profile/edit'), findsOneWidget);
  });
}
