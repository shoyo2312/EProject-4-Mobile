// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LikeStatus _$LikeStatusFromJson(Map<String, dynamic> json) {
  return _LikeStatus.fromJson(json);
}

/// @nodoc
mixin _$LikeStatus {
  @JsonKey(fromJson: _idFromJson)
  String get videoId => throw _privateConstructorUsedError;
  bool get liked => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;

  /// Serializes this LikeStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LikeStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LikeStatusCopyWith<LikeStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LikeStatusCopyWith<$Res> {
  factory $LikeStatusCopyWith(
    LikeStatus value,
    $Res Function(LikeStatus) then,
  ) = _$LikeStatusCopyWithImpl<$Res, LikeStatus>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String videoId,
    bool liked,
    int likeCount,
  });
}

/// @nodoc
class _$LikeStatusCopyWithImpl<$Res, $Val extends LikeStatus>
    implements $LikeStatusCopyWith<$Res> {
  _$LikeStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LikeStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? liked = null,
    Object? likeCount = null,
  }) {
    return _then(
      _value.copyWith(
            videoId: null == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                      as String,
            liked: null == liked
                ? _value.liked
                : liked // ignore: cast_nullable_to_non_nullable
                      as bool,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LikeStatusImplCopyWith<$Res>
    implements $LikeStatusCopyWith<$Res> {
  factory _$$LikeStatusImplCopyWith(
    _$LikeStatusImpl value,
    $Res Function(_$LikeStatusImpl) then,
  ) = __$$LikeStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String videoId,
    bool liked,
    int likeCount,
  });
}

/// @nodoc
class __$$LikeStatusImplCopyWithImpl<$Res>
    extends _$LikeStatusCopyWithImpl<$Res, _$LikeStatusImpl>
    implements _$$LikeStatusImplCopyWith<$Res> {
  __$$LikeStatusImplCopyWithImpl(
    _$LikeStatusImpl _value,
    $Res Function(_$LikeStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LikeStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? liked = null,
    Object? likeCount = null,
  }) {
    return _then(
      _$LikeStatusImpl(
        videoId: null == videoId
            ? _value.videoId
            : videoId // ignore: cast_nullable_to_non_nullable
                  as String,
        liked: null == liked
            ? _value.liked
            : liked // ignore: cast_nullable_to_non_nullable
                  as bool,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LikeStatusImpl implements _LikeStatus {
  const _$LikeStatusImpl({
    @JsonKey(fromJson: _idFromJson) required this.videoId,
    required this.liked,
    required this.likeCount,
  });

  factory _$LikeStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$LikeStatusImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String videoId;
  @override
  final bool liked;
  @override
  final int likeCount;

  @override
  String toString() {
    return 'LikeStatus(videoId: $videoId, liked: $liked, likeCount: $likeCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LikeStatusImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.liked, liked) || other.liked == liked) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, videoId, liked, likeCount);

  /// Create a copy of LikeStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LikeStatusImplCopyWith<_$LikeStatusImpl> get copyWith =>
      __$$LikeStatusImplCopyWithImpl<_$LikeStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LikeStatusImplToJson(this);
  }
}

abstract class _LikeStatus implements LikeStatus {
  const factory _LikeStatus({
    @JsonKey(fromJson: _idFromJson) required final String videoId,
    required final bool liked,
    required final int likeCount,
  }) = _$LikeStatusImpl;

  factory _LikeStatus.fromJson(Map<String, dynamic> json) =
      _$LikeStatusImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get videoId;
  @override
  bool get liked;
  @override
  int get likeCount;

  /// Create a copy of LikeStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LikeStatusImplCopyWith<_$LikeStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InteractionCounts _$InteractionCountsFromJson(Map<String, dynamic> json) {
  return _InteractionCounts.fromJson(json);
}

/// @nodoc
mixin _$InteractionCounts {
  @JsonKey(fromJson: _idFromJson)
  String get videoId => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;
  int get commentCount => throw _privateConstructorUsedError;
  int get shareCount => throw _privateConstructorUsedError;
  int get viewCount => throw _privateConstructorUsedError;

  /// Serializes this InteractionCounts to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InteractionCounts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InteractionCountsCopyWith<InteractionCounts> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InteractionCountsCopyWith<$Res> {
  factory $InteractionCountsCopyWith(
    InteractionCounts value,
    $Res Function(InteractionCounts) then,
  ) = _$InteractionCountsCopyWithImpl<$Res, InteractionCounts>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String videoId,
    int likeCount,
    int commentCount,
    int shareCount,
    int viewCount,
  });
}

/// @nodoc
class _$InteractionCountsCopyWithImpl<$Res, $Val extends InteractionCounts>
    implements $InteractionCountsCopyWith<$Res> {
  _$InteractionCountsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InteractionCounts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? shareCount = null,
    Object? viewCount = null,
  }) {
    return _then(
      _value.copyWith(
            videoId: null == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                      as String,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            commentCount: null == commentCount
                ? _value.commentCount
                : commentCount // ignore: cast_nullable_to_non_nullable
                      as int,
            shareCount: null == shareCount
                ? _value.shareCount
                : shareCount // ignore: cast_nullable_to_non_nullable
                      as int,
            viewCount: null == viewCount
                ? _value.viewCount
                : viewCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InteractionCountsImplCopyWith<$Res>
    implements $InteractionCountsCopyWith<$Res> {
  factory _$$InteractionCountsImplCopyWith(
    _$InteractionCountsImpl value,
    $Res Function(_$InteractionCountsImpl) then,
  ) = __$$InteractionCountsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String videoId,
    int likeCount,
    int commentCount,
    int shareCount,
    int viewCount,
  });
}

/// @nodoc
class __$$InteractionCountsImplCopyWithImpl<$Res>
    extends _$InteractionCountsCopyWithImpl<$Res, _$InteractionCountsImpl>
    implements _$$InteractionCountsImplCopyWith<$Res> {
  __$$InteractionCountsImplCopyWithImpl(
    _$InteractionCountsImpl _value,
    $Res Function(_$InteractionCountsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InteractionCounts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? shareCount = null,
    Object? viewCount = null,
  }) {
    return _then(
      _$InteractionCountsImpl(
        videoId: null == videoId
            ? _value.videoId
            : videoId // ignore: cast_nullable_to_non_nullable
                  as String,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        commentCount: null == commentCount
            ? _value.commentCount
            : commentCount // ignore: cast_nullable_to_non_nullable
                  as int,
        shareCount: null == shareCount
            ? _value.shareCount
            : shareCount // ignore: cast_nullable_to_non_nullable
                  as int,
        viewCount: null == viewCount
            ? _value.viewCount
            : viewCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InteractionCountsImpl implements _InteractionCounts {
  const _$InteractionCountsImpl({
    @JsonKey(fromJson: _idFromJson) required this.videoId,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.viewCount,
  });

  factory _$InteractionCountsImpl.fromJson(Map<String, dynamic> json) =>
      _$$InteractionCountsImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String videoId;
  @override
  final int likeCount;
  @override
  final int commentCount;
  @override
  final int shareCount;
  @override
  final int viewCount;

  @override
  String toString() {
    return 'InteractionCounts(videoId: $videoId, likeCount: $likeCount, commentCount: $commentCount, shareCount: $shareCount, viewCount: $viewCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InteractionCountsImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.shareCount, shareCount) ||
                other.shareCount == shareCount) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    videoId,
    likeCount,
    commentCount,
    shareCount,
    viewCount,
  );

  /// Create a copy of InteractionCounts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InteractionCountsImplCopyWith<_$InteractionCountsImpl> get copyWith =>
      __$$InteractionCountsImplCopyWithImpl<_$InteractionCountsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InteractionCountsImplToJson(this);
  }
}

abstract class _InteractionCounts implements InteractionCounts {
  const factory _InteractionCounts({
    @JsonKey(fromJson: _idFromJson) required final String videoId,
    required final int likeCount,
    required final int commentCount,
    required final int shareCount,
    required final int viewCount,
  }) = _$InteractionCountsImpl;

  factory _InteractionCounts.fromJson(Map<String, dynamic> json) =
      _$InteractionCountsImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get videoId;
  @override
  int get likeCount;
  @override
  int get commentCount;
  @override
  int get shareCount;
  @override
  int get viewCount;

  /// Create a copy of InteractionCounts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InteractionCountsImplCopyWith<_$InteractionCountsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
