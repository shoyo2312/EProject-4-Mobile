import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/create/presentation/photo_editor_screen.dart';

/// A 30x40 picture, made by the engine.
Future<ui.Image> _picture() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 30, 40), Paint()..color = const Color(0xFF2040C0));
  final picture = recorder.endRecording();
  return picture.toImage(30, 40);
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('photo_editor_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// The picture comes in decoded, and redrawing it is stubbed: both run on
  /// the engine's own threads, which the test's fake clock does not drive.
  Future<List<PhotoEditResult>> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picture = (await tester.runAsync(_picture))!;
    addTearDown(picture.dispose);
    final file = File('${dir.path}/photo.jpg')..writeAsBytesSync([0]);
    final results = <PhotoEditResult>[];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: PhotoEditorScreen(
          file: file,
          contentType: 'image/jpeg',
          decoded: picture,
          encodePng: (_) async => [1, 2, 3],
          onNext: (_, result) async {
            results.add(result);
            return false;
          },
        ),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const Key('photo_editor_picture')), findsOneWidget);
    return results;
  }

  testWidgets('an untouched photo goes on as it was picked, with no recipe', (tester) async {
    final results = await open(tester);

    await tester.tap(find.byKey(const Key('photo_editor_continue')));
    await tester.pump();

    expect(results.single.edit, isNull);
    expect(results.single.contentType, 'image/jpeg');
    expect(results.single.file.path, endsWith('photo.jpg'));
    expect(results.single.aspectRatio, closeTo(0.75, 0.001));
  });

  /// The server applies the colour, so the picture uploaded is redrawn upright
  /// but left uncoloured, and the recipe names the filter.
  testWidgets('a colour sends the picture redrawn as a PNG and the recipe', (tester) async {
    final results = await open(tester);

    await tester.tap(find.byKey(const Key('filter_mono')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('photo_editor_continue')));
    await tester.pump();

    final result = results.single;
    expect(result.edit?.filter?.id, 'mono');
    expect(result.edit?.music, isNull);
    expect(result.photoSeconds, isNull, reason: 'only a photo with a song has a length');
    expect(result.contentType, 'image/png');
    expect(result.file.readAsBytesSync(), [1, 2, 3]);
  });

  /// What the server is sent: no wider than a phone screen, even on both
  /// sides for the encoder, the shape kept.
  testWidgets('the redrawn picture is capped at 1080 wide with even sides', (tester) async {
    final size = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 2001, 1001), Paint()..color = const Color(0xFF00FF00));
      final big = await recorder.endRecording().toImage(2001, 1001);
      final png = await uprightPng(big);
      big.dispose();
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
      final frame = await codec.getNextFrame();
      final size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      frame.image.dispose();
      return size;
    });

    expect(size, const Size(1080, 540));
  });
}
