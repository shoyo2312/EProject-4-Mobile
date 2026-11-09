import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/user/presentation/profile_screen.dart';
import 'package:tiktok_mobile/mock/mock_backend.dart';

void main() {
  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: ProfileScreen(embedded: true)),
        ),
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

  Future<void> openManageSheet(WidgetTester tester, String videoId) async {
    final tile = find.byKey(Key('profile_video_$videoId'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.longPress(tile);
    await tester.pumpAndSettle();
  }

  /// Lets the toast's own timer run out so the test ends with none pending.
  Future<void> dismissToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  }

  testWidgets('pin to top marks the tile and moves it first', (tester) async {
    await pumpProfile(tester);
    expect(find.byKey(const Key('profile_video_pinned_v3')), findsNothing);

    await openManageSheet(tester, 'v3');
    expect(find.text('Pin to top'), findsOneWidget);
    await tester.tap(find.byKey(const Key('manage_video_pin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_video_pinned_v3')), findsOneWidget);
    // The first cell of the grid: no tile sits above or left of it.
    final pinned = tester.getTopLeft(find.byKey(const Key('profile_video_v3')));
    for (final id in ['v12', 'v13', 'v14', 'v15']) {
      final other = tester.getTopLeft(find.byKey(Key('profile_video_$id')));
      expect(
        other.dy > pinned.dy || (other.dy == pinned.dy && other.dx > pinned.dx),
        isTrue,
        reason: '$id should come after the pinned video',
      );
    }
    await dismissToast(tester);

    await openManageSheet(tester, 'v3');
    expect(find.text('Unpin'), findsOneWidget);
    await tester.tap(find.byKey(const Key('manage_video_pin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_video_pinned_v3')), findsNothing);
    await dismissToast(tester);
  });

  testWidgets('a video still processing cannot be pinned', (tester) async {
    await pumpProfile(tester);

    await openManageSheet(tester, 'v6');

    expect(find.byKey(const Key('manage_video_edit')), findsOneWidget);
    expect(find.byKey(const Key('manage_video_pin')), findsNothing);
  });

  testWidgets('edit video changes who can watch and turns comments off', (
    tester,
  ) async {
    await pumpProfile(tester);

    await openManageSheet(tester, 'v3');
    expect(find.text('Make private'), findsNothing);
    expect(find.text('Turn comments off'), findsNothing);
    await tester.tap(find.byKey(const Key('manage_video_edit')));
    await tester.pumpAndSettle();

    final private = find.byKey(const Key('edit_video_visibility_private'));
    expect(private, findsOneWidget);
    expect(find.byKey(const Key('edit_video_visibility_friends')), findsOneWidget);
    expect(find.byKey(const Key('edit_video_visibility_public')), findsOneWidget);
    expect(
      find.descendant(of: private, matching: find.byIcon(Icons.check)),
      findsNothing,
    );

    await tester.tap(private);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: private, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );

    final comments = find.byKey(const Key('edit_video_comments'));
    expect(tester.widget<SwitchListTile>(comments).value, isTrue);
    await tester.tap(comments);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(comments).value, isFalse);
  });
}
