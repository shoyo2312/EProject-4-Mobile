import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/create/data/music_track.dart';
import 'package:tiktok_mobile/features/create/presentation/create_screen.dart';
import 'package:tiktok_mobile/features/create/presentation/music_provider.dart';

/// There is no camera plugin under test, which is also what a phone without a
/// usable camera looks like: the screen has to stay usable — gallery and
/// story mode still work — rather than fail.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        musicSearchProvider('').overrideWith(
          (ref) async => const [
            MusicTrack(id: '42', title: 'Calm', artist: 'Someone', durationSeconds: 120, audioUrl: 'https://stream/42'),
          ],
        ),
      ],
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

  testWidgets('the filter tool opens the strip, and the choice names the tool',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('create_tool_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter_mono')));
    await tester.pumpAndSettle();

    // On the tool and under the swatch.
    expect(find.text('Mono'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('filter_none')));
    await tester.pumpAndSettle();
    expect(find.text('Filter'), findsOneWidget);
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

  testWidgets('add sound picks a song, names it, and can drop it', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('create_add_sound')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('music_use_42')));
    await tester.pumpAndSettle();
    expect(find.text('Calm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create_remove_sound')));
    await tester.pumpAndSettle();
    expect(find.text('Add sound'), findsOneWidget);
  });
}
