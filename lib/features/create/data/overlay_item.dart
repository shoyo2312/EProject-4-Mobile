import 'dart:ui' show Color, FontVariation, FontWeight;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'overlay_item.freezed.dart';

/// A word or a sticker the poster laid over the video in the editor.
///
/// Everything is relative to the video's frame, never to the screen: [x] and
/// [y] are where the centre sits as a fraction of the frame's width and
/// height, and the size scales with the frame's width. The same item then
/// draws the same over a phone-sized preview and over the full-size PNG the
/// server lays on the published video (video doc 3.2, `edit.overlays`).
@freezed
class OverlayItem with _$OverlayItem {
  const OverlayItem._();

  const factory OverlayItem({
    required int id,
    required OverlayKind kind,

    /// The words, or the sticker's id in [overlayStickers].
    required String text,
    @Default(0.5) double x,
    @Default(0.5) double y,

    /// 1 is the size it is added at; pinching changes it.
    @Default(1.0) double scale,

    /// Radians, clockwise.
    @Default(0.0) double rotation,

    /// Index into [overlayPalette]. Text only.
    @Default(0) int colour,

    /// Text drawn on a filled rounded box of [colour] rather than in it.
    @Default(false) bool boxed,

    /// Index into [overlayFonts]. Text only.
    @Default(0) int font,

    /// Seconds into the edited video — the viewer's clock, after the cuts
    /// and speed changes — when the item appears. Null from the first frame.
    double? start,

    /// When it goes again. Null until the last frame.
    double? end,
  }) = _OverlayItem;

  /// Whether the item is up at [seconds] on the edited video's clock.
  bool showsAt(double seconds) =>
      (start == null || seconds >= start!) && (end == null || seconds <= end!);
}

enum OverlayKind { text, sticker }

/// Smallest and largest a pinch can make an item, so it can neither vanish
/// nor swallow the frame.
const overlayMinScale = 0.3;
const overlayMaxScale = 5.0;

/// Text colours on offer. These are colours of the poster's content, burnt
/// into their video, not the app's theme — which is why they live here
/// rather than in NowaColors.
const overlayPalette = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFF000000),
  Color(0xFFFF3B5C),
  Color(0xFFFF8A00),
  Color(0xFFFFD60A),
  Color(0xFF34C759),
  Color(0xFF32D2F5),
  Color(0xFF2F6BFF),
  Color(0xFFAF52DE),
  Color(0xFFFF7EB6),
];

/// A typeface for text on the video. Bundled with the app (assets/fonts,
/// SIL Open Font License) rather than taken from the phone, so the words look
/// the same whoever posts them, and every one covers Vietnamese.
class OverlayFont {
  const OverlayFont(
    this.name,
    this.family,
    this.weight, [
    this.variations = const [],
  ]);

  final String name;

  /// As declared under `fonts:` in pubspec.yaml.
  final String family;

  /// The weight the file was drawn at. Asking a single-weight font for more
  /// makes the engine smear a fake bold, so each says what it has.
  final FontWeight weight;

  /// For the variable fonts: which point on their weight axis to draw.
  final List<FontVariation> variations;
}

const overlayFonts = <OverlayFont>[
  OverlayFont('Classic', 'OverlayClassic', FontWeight.w800),
  OverlayFont('Serif', 'OverlaySerif', FontWeight.w800, [
    FontVariation('wght', 800),
  ]),
  OverlayFont('Script', 'OverlayScript', FontWeight.w700, [
    FontVariation('wght', 700),
  ]),
  OverlayFont('Bold', 'OverlayBungee', FontWeight.w400),
  OverlayFont('Retro', 'OverlayPacifico', FontWeight.w400),
  OverlayFont('Hand', 'OverlayHand', FontWeight.w400),
];

/// The stickers on offer: Microsoft's Fluent 3D emoji (MIT, see
/// assets/stickers/LICENSE-fluentui-emoji.txt), bundled as pictures so a
/// sticker is the same drawing on every phone rather than whatever emoji
/// font its maker ships.
const overlayStickers = <String>[
  'face-with-tears-of-joy',
  'heart-eyes',
  'smiling-face-with-hearts',
  'sunglasses',
  'star-struck',
  'loudly-crying',
  'pleading',
  'enraged',
  'exploding-head',
  'partying',
  'sleeping',
  'thinking',
  'rolling-eyes',
  'halo',
  'clown',
  'ghost',
  'skull',
  'eyes',
  'thumbs-up',
  'clapping-hands',
  'raising-hands',
  'folded-hands',
  'flexed-biceps',
  'fire',
  'sparkles',
  'hundred-points',
  'red-heart',
  'broken-heart',
  'sparkling-heart',
  'star',
  'rainbow',
  'sun',
  'crescent-moon',
  'high-voltage',
  'party-popper',
  'birthday-cake',
  'wrapped-gift',
  'musical-notes',
  'video-game',
  'soccer-ball',
  'basketball',
  'pizza',
  'hamburger',
  'steaming-bowl',
  'hot-beverage',
  'bubble-tea',
  'strawberry',
  'dog-face',
  'cat-face',
];

String stickerAsset(String id) => 'assets/stickers/$id.png';
