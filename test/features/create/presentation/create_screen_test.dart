import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/create/presentation/create_screen.dart';

/// There is no camera plugin under test, which is also what a phone without a
/// usable camera looks like: the screen has to stay usable — gallery and
/// story mode still work — rather than fail.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: CreateScreen(
            onClose: () {},
            onPosted: () {},
            findCameras: () async => const [],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('without a camera the screen says so and keeps the gallery',
      (tester) async {
    await pump(tester);

    expect(find.text('No camera on this device'), findsOneWidget);
    expect(find.byKey(const Key('create_gallery_button')), findsOneWidget);
    expect(find.byKey(const Key('create_done_button')), findsNothing);
  });

  testWidgets('the shutter does nothing without a camera', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('create_record_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_record_progress')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the speed tool opens the speed picker, and the choice sticks',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('create_tool_speed')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_speed_2.0')));
    await tester.pumpAndSettle();

    expect(find.text('2x'), findsWidgets);
  });

  testWidgets('the timer cycles off, 3s, 10s', (tester) async {
    await pump(tester);
    final timer = find.byKey(const Key('create_tool_timer'));

    await tester.tap(timer);
    await tester.pumpAndSettle();
    expect(find.text('3s'), findsOneWidget);

    await tester.tap(timer);
    await tester.pumpAndSettle();
    expect(find.text('10s'), findsOneWidget);

    await tester.tap(timer);
    await tester.pumpAndSettle();
    expect(find.text('Timer'), findsOneWidget);
  });

  testWidgets('story mode hides the post-only tools', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('create_mode_story')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_tool_speed')), findsNothing);
    expect(find.byKey(const Key('create_story_hint')), findsOneWidget);
  });
}
