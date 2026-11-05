import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/create/data/overlay_item.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/overlay_painter.dart';

void main() {
  const frame = Size(360, 640);

  group('overlayFrameFor', () {
    test('upright video is drawn 720 wide, in its own shape', () {
      expect(overlayFrameFor(9 / 16), const Size(720, 1280));
    });

    test('a video on its side is drawn 1280 wide', () {
      expect(overlayFrameFor(16 / 9), const Size(1280, 720));
    });

    test('an aspect the player has not reported yet falls back to upright', () {
      expect(overlayFrameFor(double.nan), const Size(720, 1280));
      expect(overlayFrameFor(0), const Size(720, 1280));
    });
  });

  group('overlayItemAt', () {
    const sticker = OverlayItem(id: 1, kind: OverlayKind.sticker, text: 'fire');

    test('finds the item under the point and nothing far from it', () {
      expect(overlayItemAt([sticker], frame, const Offset(180, 320))?.id, 1);
      expect(overlayItemAt([sticker], frame, const Offset(20, 40)), isNull);
    });

    test('the one on top wins where two overlap', () {
      const above = OverlayItem(id: 2, kind: OverlayKind.text, text: 'Hi');
      expect(
        overlayItemAt([sticker, above], frame, const Offset(180, 320))?.id,
        2,
      );
      expect(
        overlayItemAt([above, sticker], frame, const Offset(180, 320))?.id,
        1,
      );
    });

    /// A long line turned upright no longer reaches sideways.
    test('follows the rotation', () {
      const line = OverlayItem(
        id: 3,
        kind: OverlayKind.text,
        text: 'a fairly long line',
      );
      const sideways = Offset(180 + 110, 320);
      expect(overlayItemAt([line], frame, sideways)?.id, 3);
      expect(
        overlayItemAt([line.copyWith(rotation: 1.5708)], frame, sideways),
        isNull,
      );
    });

    test(
      'scales with the frame, so a bigger frame finds it at the same fraction',
      () {
        expect(
          overlayItemAt([sticker], frame * 2, const Offset(360, 640))?.id,
          1,
        );
      },
    );
  });

  group('overlayLayers', () {
    OverlayItem item(int id, {double? start, double? end}) => OverlayItem(
      id: id,
      kind: OverlayKind.text,
      text: '$id',
      start: start,
      end: end,
    );

    test('items showing over the same stretch share a layer', () {
      final layers = overlayLayers([
        item(1),
        item(2),
        item(3, start: 1, end: 2),
        item(4, start: 1, end: 2),
      ]);
      expect(layers.map((l) => l.map((i) => i.id).toList()), [
        [1, 2],
        [3, 4],
      ]);
    });

    /// Merging 1 and 3 past 2 would draw 3 under 2, where the poster put it on top.
    test('never merges across an item stacked between them', () {
      final layers = overlayLayers([item(1), item(2, start: 1), item(3)]);
      expect(layers.map((l) => l.map((i) => i.id).toList()), [
        [1],
        [2],
        [3],
      ]);
    });
  });

  test('showsAt is inclusive at both ends and open where unset', () {
    const timed = OverlayItem(
      id: 1,
      kind: OverlayKind.text,
      text: 'x',
      start: 1,
      end: 2,
    );
    expect(<double>[0.5, 1, 1.5, 2, 2.5].map(timed.showsAt), [
      false,
      true,
      true,
      true,
      false,
    ]);
    expect(
      const OverlayItem(id: 2, kind: OverlayKind.text, text: 'x').showsAt(99),
      isTrue,
    );
  });

  testWidgets('renders a transparent PNG of exactly the frame size', (
    tester,
  ) async {
    final png = await tester.runAsync(
      () => renderOverlayPng(
        const [
          OverlayItem(
            id: 1,
            kind: OverlayKind.text,
            text: 'Hello',
            boxed: true,
          ),
        ],
        StickerImages(),
        const Size(72, 128),
      ),
    );

    final bytes = ByteData.sublistView(png!);
    expect(png.sublist(1, 4), 'PNG'.codeUnits);
    expect(bytes.getUint32(16), 72);
    expect(bytes.getUint32(20), 128);
  });

  /// Every sticker on offer is a bundled picture, so none can be missing on
  /// some phone.
  testWidgets('every sticker decodes from the bundle', (tester) async {
    final stickers = StickerImages();
    await tester.runAsync(() async {
      for (final id in overlayStickers) {
        await stickers.load(id, bundle: rootBundle);
        expect(stickers[id]?.width, 256, reason: id);
      }
    });
    stickers.dispose();
  });
}
