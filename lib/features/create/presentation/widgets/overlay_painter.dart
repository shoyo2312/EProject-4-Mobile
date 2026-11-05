import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiktok_mobile/features/create/data/overlay_item.dart';

/// Text height as a fraction of the frame's width, at scale 1.
const _textSize = 0.075;

/// Sticker side as a fraction of the frame's width, at scale 1.
const _stickerSize = 0.28;

/// Text wraps at this fraction of the frame's width, times the item's scale —
/// so pinching resizes a block of text without re-breaking its lines.
const _wrapWidth = 0.8;

/// Sticker pictures, decoded once and shared by every drawing of them. Owned
/// by whoever creates it, which disposes it.
class StickerImages {
  final _images = <String, ui.Image>{};

  ui.Image? operator [](String id) => _images[id];

  /// Decodes [id]'s picture unless it already is. Painting needs it decoded:
  /// a canvas cannot wait for an asset.
  Future<void> load(String id, {AssetBundle? bundle}) async {
    if (_images.containsKey(id)) return;
    final data = await (bundle ?? rootBundle).load(stickerAsset(id));
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    _images[id]?.dispose();
    _images[id] = frame.image;
  }

  /// For tests, which have no asset bundle to decode from.
  @visibleForTesting
  void put(String id, ui.Image image) => _images[id] = image;

  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }
}

/// Draws [items] over a frame of the painted size, last on top. The one
/// drawing used both on screen, over the preview, and off screen, into the
/// PNGs that are uploaded — every length is a fraction of the frame's width,
/// so the two only differ in resolution.
class OverlayPainter extends CustomPainter {
  const OverlayPainter(
    this.items,
    this.stickers, {
    this.highlight,
    this.outlined,
  });

  final List<OverlayItem> items;
  final StickerImages stickers;

  /// Drawn translucent: the item being dragged over the trash.
  final int? highlight;

  /// Framed with a thin line: the item selected for editing. Screen only.
  final int? outlined;

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      final laid = OverlayLayout.of(item, size);
      canvas
        ..save()
        ..translate(laid.centre.dx, laid.centre.dy)
        ..rotate(item.rotation);
      if (item.id == highlight) {
        canvas.saveLayer(null, Paint()..color = const Color(0x66FFFFFF));
      }
      final bounds = Rect.fromCenter(
        center: Offset.zero,
        width: laid.extent.width,
        height: laid.extent.height,
      );
      if (laid.box != null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bounds, Radius.circular(laid.fontSize * 0.3)),
          Paint()..color = laid.box!,
        );
      }
      final text = laid.text;
      if (text != null) {
        text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      } else {
        final image = stickers[item.text];
        if (image != null) {
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(
              0,
              0,
              image.width.toDouble(),
              image.height.toDouble(),
            ),
            bounds,
            Paint()..filterQuality = FilterQuality.medium,
          );
        }
      }
      if (item.id == highlight) canvas.restore();
      if (item.id == outlined) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bounds.inflate(6), const Radius.circular(6)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = const Color(0xE6FFFFFF),
        );
      }
      canvas.restore();
      text?.dispose();
    }
  }

  @override
  bool shouldRepaint(OverlayPainter old) =>
      old.items != items ||
      old.highlight != highlight ||
      old.outlined != outlined ||
      old.stickers != stickers;
}

/// One item laid out in a frame: where it sits and how big it is before its
/// rotation.
class OverlayLayout {
  OverlayLayout._(this.text, this.centre, this.extent, this.fontSize, this.box);

  factory OverlayLayout.of(OverlayItem item, Size frame) {
    final centre = Offset(item.x * frame.width, item.y * frame.height);
    if (item.kind == OverlayKind.sticker) {
      final side = frame.width * _stickerSize * item.scale;
      return OverlayLayout._(null, centre, Size.square(side), side, null);
    }

    final fontSize = frame.width * _textSize * item.scale;
    final colour =
        overlayPalette[item.colour.clamp(0, overlayPalette.length - 1)];
    final font = overlayFonts[item.font.clamp(0, overlayFonts.length - 1)];
    final box = item.boxed ? colour : null;
    final ink = box == null ? colour : _readableOn(colour);

    final text = TextPainter(
      text: TextSpan(
        text: item.text,
        style: overlayTextStyle(font, fontSize: fontSize, colour: ink).copyWith(
          // Plain text over a busy video needs an edge to stay readable.
          shadows: box != null
              ? null
              : [
                  Shadow(
                    color: const Color(0x8C000000),
                    blurRadius: fontSize * 0.12,
                  ),
                ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(1, frame.width * _wrapWidth * item.scale));

    final pad = box == null ? 0.0 : fontSize * 0.35;
    return OverlayLayout._(
      text,
      centre,
      Size(text.width + pad * 2, text.height + pad),
      fontSize,
      box,
    );
  }

  /// Null for a sticker, which is a picture.
  final TextPainter? text;
  final Offset centre;

  /// Before rotation, box included.
  final Size extent;
  final double fontSize;

  /// The filled box behind the text, or null.
  final Color? box;

  /// Black on light colours, white on the rest.
  static Color _readableOn(Color colour) => colour.computeLuminance() > 0.5
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);

  /// Whether [point] (in the frame) falls on the item, rotation included,
  /// with [slop] pixels to spare all round for a fingertip.
  bool contains(Offset point, double rotation, {double slop = 12}) {
    final d = point - centre;
    final cos = math.cos(-rotation), sin = math.sin(-rotation);
    final local = Offset(d.dx * cos - d.dy * sin, d.dx * sin + d.dy * cos);
    return local.dx.abs() <= extent.width / 2 + slop &&
        local.dy.abs() <= extent.height / 2 + slop;
  }
}

/// How [font] draws, the same in the editor's text box and on the video.
TextStyle overlayTextStyle(
  OverlayFont font, {
  required double fontSize,
  required Color colour,
}) => TextStyle(
  fontFamily: font.family,
  fontSize: fontSize,
  height: 1.2,
  fontWeight: font.weight,
  fontVariations: font.variations,
  color: colour,
);

/// The topmost item at [point] in a frame of [frame] size, or null.
OverlayItem? overlayItemAt(List<OverlayItem> items, Size frame, Offset point) {
  for (final item in items.reversed) {
    final laid = OverlayLayout.of(item, frame);
    final hit = laid.contains(point, item.rotation);
    laid.text?.dispose();
    if (hit) return item;
  }
  return null;
}

/// The frame size the overlay PNGs are drawn at for a video of [aspectRatio]
/// (width / height): 720 wide upright, 1280 wide on its side — the size the
/// server caps the video at, so the text is drawn at about the resolution it
/// is shown at.
Size overlayFrameFor(double aspectRatio) {
  final ratio = aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 9 / 16;
  final width = ratio < 1 ? 720.0 : 1280.0;
  return Size(width, (width / ratio).roundToDouble());
}

/// [items] drawn over a transparent [frame], as PNG bytes.
Future<Uint8List> renderOverlayPng(
  List<OverlayItem> items,
  StickerImages stickers,
  Size frame,
) async {
  final recorder = ui.PictureRecorder();
  OverlayPainter(items, stickers).paint(Canvas(recorder), frame);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    frame.width.round(),
    frame.height.round(),
  );
  picture.dispose();
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// [items] split into the layers that are uploaded: runs of neighbours, in
/// stacking order, that show over the same stretch of the video. Neighbours
/// only, so a layer never jumps over an item that sits between its members —
/// the server stacks layers in this order, and the picture keeps the order
/// the poster arranged.
List<List<OverlayItem>> overlayLayers(List<OverlayItem> items) {
  final layers = <List<OverlayItem>>[];
  for (final item in items) {
    final last = layers.lastOrNull;
    if (last != null &&
        last.first.start == item.start &&
        last.first.end == item.end) {
      last.add(item);
    } else {
      layers.add([item]);
    }
  }
  return layers;
}
