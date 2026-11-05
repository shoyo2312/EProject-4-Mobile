// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_edit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VideoEdit _$VideoEditFromJson(Map<String, dynamic> json) {
  return _VideoEdit.fromJson(json);
}

/// @nodoc
mixin _$VideoEdit {
  /// Empty is the whole clip at normal speed: an edit that only changes
  /// the colour.
  List<EditSegment> get segments => throw _privateConstructorUsedError;
  EditFilter? get filter => throw _privateConstructorUsedError;

  /// Serializes this VideoEdit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VideoEdit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoEditCopyWith<VideoEdit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoEditCopyWith<$Res> {
  factory $VideoEditCopyWith(VideoEdit value, $Res Function(VideoEdit) then) =
      _$VideoEditCopyWithImpl<$Res, VideoEdit>;
  @useResult
  $Res call({List<EditSegment> segments, EditFilter? filter});

  $EditFilterCopyWith<$Res>? get filter;
}

/// @nodoc
class _$VideoEditCopyWithImpl<$Res, $Val extends VideoEdit>
    implements $VideoEditCopyWith<$Res> {
  _$VideoEditCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoEdit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? segments = null, Object? filter = freezed}) {
    return _then(
      _value.copyWith(
            segments: null == segments
                ? _value.segments
                : segments // ignore: cast_nullable_to_non_nullable
                      as List<EditSegment>,
            filter: freezed == filter
                ? _value.filter
                : filter // ignore: cast_nullable_to_non_nullable
                      as EditFilter?,
          )
          as $Val,
    );
  }

  /// Create a copy of VideoEdit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EditFilterCopyWith<$Res>? get filter {
    if (_value.filter == null) {
      return null;
    }

    return $EditFilterCopyWith<$Res>(_value.filter!, (value) {
      return _then(_value.copyWith(filter: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VideoEditImplCopyWith<$Res>
    implements $VideoEditCopyWith<$Res> {
  factory _$$VideoEditImplCopyWith(
    _$VideoEditImpl value,
    $Res Function(_$VideoEditImpl) then,
  ) = __$$VideoEditImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<EditSegment> segments, EditFilter? filter});

  @override
  $EditFilterCopyWith<$Res>? get filter;
}

/// @nodoc
class __$$VideoEditImplCopyWithImpl<$Res>
    extends _$VideoEditCopyWithImpl<$Res, _$VideoEditImpl>
    implements _$$VideoEditImplCopyWith<$Res> {
  __$$VideoEditImplCopyWithImpl(
    _$VideoEditImpl _value,
    $Res Function(_$VideoEditImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VideoEdit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? segments = null, Object? filter = freezed}) {
    return _then(
      _$VideoEditImpl(
        segments: null == segments
            ? _value._segments
            : segments // ignore: cast_nullable_to_non_nullable
                  as List<EditSegment>,
        filter: freezed == filter
            ? _value.filter
            : filter // ignore: cast_nullable_to_non_nullable
                  as EditFilter?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoEditImpl extends _VideoEdit {
  const _$VideoEditImpl({
    final List<EditSegment> segments = const [],
    this.filter,
  }) : _segments = segments,
       super._();

  factory _$VideoEditImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoEditImplFromJson(json);

  /// Empty is the whole clip at normal speed: an edit that only changes
  /// the colour.
  final List<EditSegment> _segments;

  /// Empty is the whole clip at normal speed: an edit that only changes
  /// the colour.
  @override
  @JsonKey()
  List<EditSegment> get segments {
    if (_segments is EqualUnmodifiableListView) return _segments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_segments);
  }

  @override
  final EditFilter? filter;

  @override
  String toString() {
    return 'VideoEdit(segments: $segments, filter: $filter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoEditImpl &&
            const DeepCollectionEquality().equals(other._segments, _segments) &&
            (identical(other.filter, filter) || other.filter == filter));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_segments),
    filter,
  );

  /// Create a copy of VideoEdit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoEditImplCopyWith<_$VideoEditImpl> get copyWith =>
      __$$VideoEditImplCopyWithImpl<_$VideoEditImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoEditImplToJson(this);
  }
}

abstract class _VideoEdit extends VideoEdit {
  const factory _VideoEdit({
    final List<EditSegment> segments,
    final EditFilter? filter,
  }) = _$VideoEditImpl;
  const _VideoEdit._() : super._();

  factory _VideoEdit.fromJson(Map<String, dynamic> json) =
      _$VideoEditImpl.fromJson;

  /// Empty is the whole clip at normal speed: an edit that only changes
  /// the colour.
  @override
  List<EditSegment> get segments;
  @override
  EditFilter? get filter;

  /// Create a copy of VideoEdit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoEditImplCopyWith<_$VideoEditImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EditFilter _$EditFilterFromJson(Map<String, dynamic> json) {
  return _EditFilter.fromJson(json);
}

/// @nodoc
mixin _$EditFilter {
  String get id => throw _privateConstructorUsedError;
  double get intensity => throw _privateConstructorUsedError;

  /// Serializes this EditFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EditFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditFilterCopyWith<EditFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditFilterCopyWith<$Res> {
  factory $EditFilterCopyWith(
    EditFilter value,
    $Res Function(EditFilter) then,
  ) = _$EditFilterCopyWithImpl<$Res, EditFilter>;
  @useResult
  $Res call({String id, double intensity});
}

/// @nodoc
class _$EditFilterCopyWithImpl<$Res, $Val extends EditFilter>
    implements $EditFilterCopyWith<$Res> {
  _$EditFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? intensity = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            intensity: null == intensity
                ? _value.intensity
                : intensity // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EditFilterImplCopyWith<$Res>
    implements $EditFilterCopyWith<$Res> {
  factory _$$EditFilterImplCopyWith(
    _$EditFilterImpl value,
    $Res Function(_$EditFilterImpl) then,
  ) = __$$EditFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, double intensity});
}

/// @nodoc
class __$$EditFilterImplCopyWithImpl<$Res>
    extends _$EditFilterCopyWithImpl<$Res, _$EditFilterImpl>
    implements _$$EditFilterImplCopyWith<$Res> {
  __$$EditFilterImplCopyWithImpl(
    _$EditFilterImpl _value,
    $Res Function(_$EditFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EditFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? intensity = null}) {
    return _then(
      _$EditFilterImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        intensity: null == intensity
            ? _value.intensity
            : intensity // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EditFilterImpl implements _EditFilter {
  const _$EditFilterImpl({required this.id, this.intensity = 1.0});

  factory _$EditFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$EditFilterImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final double intensity;

  @override
  String toString() {
    return 'EditFilter(id: $id, intensity: $intensity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditFilterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, intensity);

  /// Create a copy of EditFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditFilterImplCopyWith<_$EditFilterImpl> get copyWith =>
      __$$EditFilterImplCopyWithImpl<_$EditFilterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EditFilterImplToJson(this);
  }
}

abstract class _EditFilter implements EditFilter {
  const factory _EditFilter({
    required final String id,
    final double intensity,
  }) = _$EditFilterImpl;

  factory _EditFilter.fromJson(Map<String, dynamic> json) =
      _$EditFilterImpl.fromJson;

  @override
  String get id;
  @override
  double get intensity;

  /// Create a copy of EditFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditFilterImplCopyWith<_$EditFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EditSegment _$EditSegmentFromJson(Map<String, dynamic> json) {
  return _EditSegment.fromJson(json);
}

/// @nodoc
mixin _$EditSegment {
  double get start => throw _privateConstructorUsedError;
  double get end => throw _privateConstructorUsedError;
  double get speed => throw _privateConstructorUsedError;

  /// Serializes this EditSegment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EditSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditSegmentCopyWith<EditSegment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditSegmentCopyWith<$Res> {
  factory $EditSegmentCopyWith(
    EditSegment value,
    $Res Function(EditSegment) then,
  ) = _$EditSegmentCopyWithImpl<$Res, EditSegment>;
  @useResult
  $Res call({double start, double end, double speed});
}

/// @nodoc
class _$EditSegmentCopyWithImpl<$Res, $Val extends EditSegment>
    implements $EditSegmentCopyWith<$Res> {
  _$EditSegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? start = null, Object? end = null, Object? speed = null}) {
    return _then(
      _value.copyWith(
            start: null == start
                ? _value.start
                : start // ignore: cast_nullable_to_non_nullable
                      as double,
            end: null == end
                ? _value.end
                : end // ignore: cast_nullable_to_non_nullable
                      as double,
            speed: null == speed
                ? _value.speed
                : speed // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EditSegmentImplCopyWith<$Res>
    implements $EditSegmentCopyWith<$Res> {
  factory _$$EditSegmentImplCopyWith(
    _$EditSegmentImpl value,
    $Res Function(_$EditSegmentImpl) then,
  ) = __$$EditSegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double start, double end, double speed});
}

/// @nodoc
class __$$EditSegmentImplCopyWithImpl<$Res>
    extends _$EditSegmentCopyWithImpl<$Res, _$EditSegmentImpl>
    implements _$$EditSegmentImplCopyWith<$Res> {
  __$$EditSegmentImplCopyWithImpl(
    _$EditSegmentImpl _value,
    $Res Function(_$EditSegmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EditSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? start = null, Object? end = null, Object? speed = null}) {
    return _then(
      _$EditSegmentImpl(
        start: null == start
            ? _value.start
            : start // ignore: cast_nullable_to_non_nullable
                  as double,
        end: null == end
            ? _value.end
            : end // ignore: cast_nullable_to_non_nullable
                  as double,
        speed: null == speed
            ? _value.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EditSegmentImpl implements _EditSegment {
  const _$EditSegmentImpl({
    required this.start,
    required this.end,
    this.speed = 1.0,
  });

  factory _$EditSegmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$EditSegmentImplFromJson(json);

  @override
  final double start;
  @override
  final double end;
  @override
  @JsonKey()
  final double speed;

  @override
  String toString() {
    return 'EditSegment(start: $start, end: $end, speed: $speed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditSegmentImpl &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            (identical(other.speed, speed) || other.speed == speed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, start, end, speed);

  /// Create a copy of EditSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditSegmentImplCopyWith<_$EditSegmentImpl> get copyWith =>
      __$$EditSegmentImplCopyWithImpl<_$EditSegmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EditSegmentImplToJson(this);
  }
}

abstract class _EditSegment implements EditSegment {
  const factory _EditSegment({
    required final double start,
    required final double end,
    final double speed,
  }) = _$EditSegmentImpl;

  factory _EditSegment.fromJson(Map<String, dynamic> json) =
      _$EditSegmentImpl.fromJson;

  @override
  double get start;
  @override
  double get end;
  @override
  double get speed;

  /// Create a copy of EditSegment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditSegmentImplCopyWith<_$EditSegmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
