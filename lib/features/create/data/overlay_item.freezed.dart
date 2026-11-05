// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overlay_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OverlayItem {
  int get id => throw _privateConstructorUsedError;
  OverlayKind get kind => throw _privateConstructorUsedError;

  /// The words, or the sticker's id in [overlayStickers].
  String get text => throw _privateConstructorUsedError;
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;

  /// 1 is the size it is added at; pinching changes it.
  double get scale => throw _privateConstructorUsedError;

  /// Radians, clockwise.
  double get rotation => throw _privateConstructorUsedError;

  /// Index into [overlayPalette]. Text only.
  int get colour => throw _privateConstructorUsedError;

  /// Text drawn on a filled rounded box of [colour] rather than in it.
  bool get boxed => throw _privateConstructorUsedError;

  /// Index into [overlayFonts]. Text only.
  int get font => throw _privateConstructorUsedError;

  /// Seconds into the edited video — the viewer's clock, after the cuts
  /// and speed changes — when the item appears. Null from the first frame.
  double? get start => throw _privateConstructorUsedError;

  /// When it goes again. Null until the last frame.
  double? get end => throw _privateConstructorUsedError;

  /// Create a copy of OverlayItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OverlayItemCopyWith<OverlayItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OverlayItemCopyWith<$Res> {
  factory $OverlayItemCopyWith(
    OverlayItem value,
    $Res Function(OverlayItem) then,
  ) = _$OverlayItemCopyWithImpl<$Res, OverlayItem>;
  @useResult
  $Res call({
    int id,
    OverlayKind kind,
    String text,
    double x,
    double y,
    double scale,
    double rotation,
    int colour,
    bool boxed,
    int font,
    double? start,
    double? end,
  });
}

/// @nodoc
class _$OverlayItemCopyWithImpl<$Res, $Val extends OverlayItem>
    implements $OverlayItemCopyWith<$Res> {
  _$OverlayItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OverlayItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? text = null,
    Object? x = null,
    Object? y = null,
    Object? scale = null,
    Object? rotation = null,
    Object? colour = null,
    Object? boxed = null,
    Object? font = null,
    Object? start = freezed,
    Object? end = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as OverlayKind,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            x: null == x
                ? _value.x
                : x // ignore: cast_nullable_to_non_nullable
                      as double,
            y: null == y
                ? _value.y
                : y // ignore: cast_nullable_to_non_nullable
                      as double,
            scale: null == scale
                ? _value.scale
                : scale // ignore: cast_nullable_to_non_nullable
                      as double,
            rotation: null == rotation
                ? _value.rotation
                : rotation // ignore: cast_nullable_to_non_nullable
                      as double,
            colour: null == colour
                ? _value.colour
                : colour // ignore: cast_nullable_to_non_nullable
                      as int,
            boxed: null == boxed
                ? _value.boxed
                : boxed // ignore: cast_nullable_to_non_nullable
                      as bool,
            font: null == font
                ? _value.font
                : font // ignore: cast_nullable_to_non_nullable
                      as int,
            start: freezed == start
                ? _value.start
                : start // ignore: cast_nullable_to_non_nullable
                      as double?,
            end: freezed == end
                ? _value.end
                : end // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OverlayItemImplCopyWith<$Res>
    implements $OverlayItemCopyWith<$Res> {
  factory _$$OverlayItemImplCopyWith(
    _$OverlayItemImpl value,
    $Res Function(_$OverlayItemImpl) then,
  ) = __$$OverlayItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    OverlayKind kind,
    String text,
    double x,
    double y,
    double scale,
    double rotation,
    int colour,
    bool boxed,
    int font,
    double? start,
    double? end,
  });
}

/// @nodoc
class __$$OverlayItemImplCopyWithImpl<$Res>
    extends _$OverlayItemCopyWithImpl<$Res, _$OverlayItemImpl>
    implements _$$OverlayItemImplCopyWith<$Res> {
  __$$OverlayItemImplCopyWithImpl(
    _$OverlayItemImpl _value,
    $Res Function(_$OverlayItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OverlayItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? text = null,
    Object? x = null,
    Object? y = null,
    Object? scale = null,
    Object? rotation = null,
    Object? colour = null,
    Object? boxed = null,
    Object? font = null,
    Object? start = freezed,
    Object? end = freezed,
  }) {
    return _then(
      _$OverlayItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as OverlayKind,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        x: null == x
            ? _value.x
            : x // ignore: cast_nullable_to_non_nullable
                  as double,
        y: null == y
            ? _value.y
            : y // ignore: cast_nullable_to_non_nullable
                  as double,
        scale: null == scale
            ? _value.scale
            : scale // ignore: cast_nullable_to_non_nullable
                  as double,
        rotation: null == rotation
            ? _value.rotation
            : rotation // ignore: cast_nullable_to_non_nullable
                  as double,
        colour: null == colour
            ? _value.colour
            : colour // ignore: cast_nullable_to_non_nullable
                  as int,
        boxed: null == boxed
            ? _value.boxed
            : boxed // ignore: cast_nullable_to_non_nullable
                  as bool,
        font: null == font
            ? _value.font
            : font // ignore: cast_nullable_to_non_nullable
                  as int,
        start: freezed == start
            ? _value.start
            : start // ignore: cast_nullable_to_non_nullable
                  as double?,
        end: freezed == end
            ? _value.end
            : end // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc

class _$OverlayItemImpl extends _OverlayItem {
  const _$OverlayItemImpl({
    required this.id,
    required this.kind,
    required this.text,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.colour = 0,
    this.boxed = false,
    this.font = 0,
    this.start,
    this.end,
  }) : super._();

  @override
  final int id;
  @override
  final OverlayKind kind;

  /// The words, or the sticker's id in [overlayStickers].
  @override
  final String text;
  @override
  @JsonKey()
  final double x;
  @override
  @JsonKey()
  final double y;

  /// 1 is the size it is added at; pinching changes it.
  @override
  @JsonKey()
  final double scale;

  /// Radians, clockwise.
  @override
  @JsonKey()
  final double rotation;

  /// Index into [overlayPalette]. Text only.
  @override
  @JsonKey()
  final int colour;

  /// Text drawn on a filled rounded box of [colour] rather than in it.
  @override
  @JsonKey()
  final bool boxed;

  /// Index into [overlayFonts]. Text only.
  @override
  @JsonKey()
  final int font;

  /// Seconds into the edited video — the viewer's clock, after the cuts
  /// and speed changes — when the item appears. Null from the first frame.
  @override
  final double? start;

  /// When it goes again. Null until the last frame.
  @override
  final double? end;

  @override
  String toString() {
    return 'OverlayItem(id: $id, kind: $kind, text: $text, x: $x, y: $y, scale: $scale, rotation: $rotation, colour: $colour, boxed: $boxed, font: $font, start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OverlayItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.scale, scale) || other.scale == scale) &&
            (identical(other.rotation, rotation) ||
                other.rotation == rotation) &&
            (identical(other.colour, colour) || other.colour == colour) &&
            (identical(other.boxed, boxed) || other.boxed == boxed) &&
            (identical(other.font, font) || other.font == font) &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    kind,
    text,
    x,
    y,
    scale,
    rotation,
    colour,
    boxed,
    font,
    start,
    end,
  );

  /// Create a copy of OverlayItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OverlayItemImplCopyWith<_$OverlayItemImpl> get copyWith =>
      __$$OverlayItemImplCopyWithImpl<_$OverlayItemImpl>(this, _$identity);
}

abstract class _OverlayItem extends OverlayItem {
  const factory _OverlayItem({
    required final int id,
    required final OverlayKind kind,
    required final String text,
    final double x,
    final double y,
    final double scale,
    final double rotation,
    final int colour,
    final bool boxed,
    final int font,
    final double? start,
    final double? end,
  }) = _$OverlayItemImpl;
  const _OverlayItem._() : super._();

  @override
  int get id;
  @override
  OverlayKind get kind;

  /// The words, or the sticker's id in [overlayStickers].
  @override
  String get text;
  @override
  double get x;
  @override
  double get y;

  /// 1 is the size it is added at; pinching changes it.
  @override
  double get scale;

  /// Radians, clockwise.
  @override
  double get rotation;

  /// Index into [overlayPalette]. Text only.
  @override
  int get colour;

  /// Text drawn on a filled rounded box of [colour] rather than in it.
  @override
  bool get boxed;

  /// Index into [overlayFonts]. Text only.
  @override
  int get font;

  /// Seconds into the edited video — the viewer's clock, after the cuts
  /// and speed changes — when the item appears. Null from the first frame.
  @override
  double? get start;

  /// When it goes again. Null until the last frame.
  @override
  double? get end;

  /// Create a copy of OverlayItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OverlayItemImplCopyWith<_$OverlayItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
