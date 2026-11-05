import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/create/data/music_track.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/create/presentation/music_provider.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/music_panel.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/music_picker.dart';

const _calm = MusicTrack(
  id: '42',
  title: 'Calm',
  artist: 'Someone',
  durationSeconds: 120,
  audioUrl: 'https://stream/42',
);

void main() {
  group('the picker', () {
    Future<List<MusicTrack?>> open(WidgetTester tester, Future<List<MusicTrack>> Function() answer) async {
      final picked = <MusicTrack?>[];
      await tester.pumpWidget(ProviderScope(
        overrides: [musicSearchProvider('').overrideWith((ref) => answer())],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked.add(await showMusicPicker(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('lists the popular songs and answers the one used', (tester) async {
      final picked = await open(tester, () async => [_calm]);

      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Someone · 2:00'), findsOneWidget);

      await tester.tap(find.byKey(const Key('music_use_42')));
      await tester.pumpAndSettle();
      expect(picked.single?.id, '42');
    });

    testWidgets('says so when the catalogue is down, rather than showing nothing', (tester) async {
      await open(
        tester,
        () async => throw const ServerException(503, 'down', code: 'MUSIC_UNAVAILABLE'),
      );

      expect(find.text("Music isn't available right now"), findsOneWidget);
    });
  });

  group('the panel', () {
    Future<List<EditMusic>> show(WidgetTester tester, EditMusic music, {double videoSeconds = 15}) async {
      final changes = <EditMusic>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MusicPanel(
            music: music,
            videoSeconds: videoSeconds,
            onChanged: (m, {seek = false}) => changes.add(m),
            onChange: () {},
            onRemove: () {},
            onDone: () {},
          ),
        ),
      ));
      return changes;
    }

    testWidgets('offers a start only when the song outlasts the video', (tester) async {
      await show(tester, const EditMusic(trackId: '42', track: _calm));
      expect(find.byKey(const Key('music_start_slider')), findsOneWidget);

      await show(tester, const EditMusic(trackId: '42', track: _calm), videoSeconds: 130);
      expect(find.byKey(const Key('music_start_slider')), findsNothing);
    });

    testWidgets('turning the original down sets only its level', (tester) async {
      final changes = await show(tester, const EditMusic(trackId: '42', track: _calm));

      await tester.tap(find.byKey(const Key('music_original_volume_slider')), warnIfMissed: false);
      await tester.drag(find.byKey(const Key('music_original_volume_slider')), const Offset(-400, 0));
      await tester.pump();

      expect(changes.last.originalVolume, 0);
      expect(changes.last.volume, 1);
      expect(changes.last.trackId, '42');
    });
  });
}
