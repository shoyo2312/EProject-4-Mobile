// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VideoModel _$VideoModelFromJson(Map<String, dynamic> json) {
  return _VideoModel.fromJson(json);
}

/// @nodoc
mixin _$VideoModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _idFromJson)
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description =>
      throw _privateConstructorUsedError; // These three stay null until transcoding finishes.
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  String? get hlsUrl => throw _privateConstructorUsedError;
  int? get durationSeconds => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: VideoStatus.unknown)
  VideoStatus get status => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: VideoVisibility.unknown)
  VideoVisibility get visibility => throw _privateConstructorUsedError; // Updated asynchronously via Kafka, so they lag behind a like/comment that
  // just happened — a value to sync against on reload, not an immediate
  // result (video doc 5).
  int get viewCount => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;
  int get commentCount =>
      throw _privateConstructorUsedError; // Save/share have no counter in the API yet, so they default to 0 and the
  // rail falls back to a plain label — same arrangement as
  // CommentModel.replyCount.
  int get saveCount => throw _privateConstructorUsedError;
  int get shareCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this VideoModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoModelCopyWith<VideoModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoModelCopyWith<$Res> {
  factory $VideoModelCopyWith(
    VideoModel value,
    $Res Function(VideoModel) then,
  ) = _$VideoModelCopyWithImpl<$Res, VideoModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(fromJson: _idFromJson) String userId,
    String title,
    String? description,
    String? thumbnailUrl,
    String? hlsUrl,
    int? durationSeconds,
    @JsonKey(unknownEnumValue: VideoStatus.unknown) VideoStatus status,
    @JsonKey(unknownEnumValue: VideoVisibility.unknown)
    VideoVisibility visibility,
    int viewCount,
    int likeCount,
    int commentCount,
    int saveCount,
    int shareCount,
    DateTime createdAt,
  });
}

/// @nodoc
class _$VideoModelCopyWithImpl<$Res, $Val extends VideoModel>
    implements $VideoModelCopyWith<$Res> {
  _$VideoModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? description = freezed,
    Object? thumbnailUrl = freezed,
    Object? hlsUrl = freezed,
    Object? durationSeconds = freezed,
    Object? status = null,
    Object? visibility = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? saveCount = null,
    Object? shareCount = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            thumbnailUrl: freezed == thumbnailUrl
                ? _value.thumbnailUrl
                : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            hlsUrl: freezed == hlsUrl
                ? _value.hlsUrl
                : hlsUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            durationSeconds: freezed == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as VideoStatus,
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as VideoVisibility,
            viewCount: null == viewCount
                ? _value.viewCount
                : viewCount // ignore: cast_nullable_to_non_nullable
                      as int,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            commentCount: null == commentCount
                ? _value.commentCount
                : commentCount // ignore: cast_nullable_to_non_nullable
                      as int,
            saveCount: null == saveCount
                ? _value.saveCount
                : saveCount // ignore: cast_nullable_to_non_nullable
                      as int,
            shareCount: null == shareCount
                ? _value.shareCount
                : shareCount // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VideoModelImplCopyWith<$Res>
    implements $VideoModelCopyWith<$Res> {
  factory _$$VideoModelImplCopyWith(
    _$VideoModelImpl value,
    $Res Function(_$VideoModelImpl) then,
  ) = __$$VideoModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(fromJson: _idFromJson) String userId,
    String title,
    String? description,
    String? thumbnailUrl,
    String? hlsUrl,
    int? durationSeconds,
    @JsonKey(unknownEnumValue: VideoStatus.unknown) VideoStatus status,
    @JsonKey(unknownEnumValue: VideoVisibility.unknown)
    VideoVisibility visibility,
    int viewCount,
    int likeCount,
    int commentCount,
    int saveCount,
    int shareCount,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$VideoModelImplCopyWithImpl<$Res>
    extends _$VideoModelCopyWithImpl<$Res, _$VideoModelImpl>
    implements _$$VideoModelImplCopyWith<$Res> {
  __$$VideoModelImplCopyWithImpl(
    _$VideoModelImpl _value,
    $Res Function(_$VideoModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? description = freezed,
    Object? thumbnailUrl = freezed,
    Object? hlsUrl = freezed,
    Object? durationSeconds = freezed,
    Object? status = null,
    Object? visibility = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? saveCount = null,
    Object? shareCount = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$VideoModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        thumbnailUrl: freezed == thumbnailUrl
            ? _value.thumbnailUrl
            : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        hlsUrl: freezed == hlsUrl
            ? _value.hlsUrl
            : hlsUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        durationSeconds: freezed == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as VideoStatus,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as VideoVisibility,
        viewCount: null == viewCount
            ? _value.viewCount
            : viewCount // ignore: cast_nullable_to_non_nullable
                  as int,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        commentCount: null == commentCount
            ? _value.commentCount
            : commentCount // ignore: cast_nullable_to_non_nullable
                  as int,
        saveCount: null == saveCount
            ? _value.saveCount
            : saveCount // ignore: cast_nullable_to_non_nullable
                  as int,
        shareCount: null == shareCount
            ? _value.shareCount
            : shareCount // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoModelImpl implements _VideoModel {
  const _$VideoModelImpl({
    required this.id,
    @JsonKey(fromJson: _idFromJson) required this.userId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.hlsUrl,
    this.durationSeconds,
    @JsonKey(unknownEnumValue: VideoStatus.unknown) required this.status,
    @JsonKey(unknownEnumValue: VideoVisibility.unknown)
    required this.visibility,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    this.saveCount = 0,
    this.shareCount = 0,
    required this.createdAt,
  });

  factory _$VideoModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(fromJson: _idFromJson)
  final String userId;
  @override
  final String title;
  @override
  final String? description;
  // These three stay null until transcoding finishes.
  @override
  final String? thumbnailUrl;
  @override
  final String? hlsUrl;
  @override
  final int? durationSeconds;
  @override
  @JsonKey(unknownEnumValue: VideoStatus.unknown)
  final VideoStatus status;
  @override
  @JsonKey(unknownEnumValue: VideoVisibility.unknown)
  final VideoVisibility visibility;
  // Updated asynchronously via Kafka, so they lag behind a like/comment that
  // just happened — a value to sync against on reload, not an immediate
  // result (video doc 5).
  @override
  final int viewCount;
  @override
  final int likeCount;
  @override
  final int commentCount;
  // Save/share have no counter in the API yet, so they default to 0 and the
  // rail falls back to a plain label — same arrangement as
  // CommentModel.replyCount.
  @override
  @JsonKey()
  final int saveCount;
  @override
  @JsonKey()
  final int shareCount;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'VideoModel(id: $id, userId: $userId, title: $title, description: $description, thumbnailUrl: $thumbnailUrl, hlsUrl: $hlsUrl, durationSeconds: $durationSeconds, status: $status, visibility: $visibility, viewCount: $viewCount, likeCount: $likeCount, commentCount: $commentCount, saveCount: $saveCount, shareCount: $shareCount, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.hlsUrl, hlsUrl) || other.hlsUrl == hlsUrl) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.saveCount, saveCount) ||
                other.saveCount == saveCount) &&
            (identical(other.shareCount, shareCount) ||
                other.shareCount == shareCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    title,
    description,
    thumbnailUrl,
    hlsUrl,
    durationSeconds,
    status,
    visibility,
    viewCount,
    likeCount,
    commentCount,
    saveCount,
    shareCount,
    createdAt,
  );

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoModelImplCopyWith<_$VideoModelImpl> get copyWith =>
      __$$VideoModelImplCopyWithImpl<_$VideoModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoModelImplToJson(this);
  }
}

abstract class _VideoModel implements VideoModel {
  const factory _VideoModel({
    required final String id,
    @JsonKey(fromJson: _idFromJson) required final String userId,
    required final String title,
    final String? description,
    final String? thumbnailUrl,
    final String? hlsUrl,
    final int? durationSeconds,
    @JsonKey(unknownEnumValue: VideoStatus.unknown)
    required final VideoStatus status,
    @JsonKey(unknownEnumValue: VideoVisibility.unknown)
    required final VideoVisibility visibility,
    required final int viewCount,
    required final int likeCount,
    required final int commentCount,
    final int saveCount,
    final int shareCount,
    required final DateTime createdAt,
  }) = _$VideoModelImpl;

  factory _VideoModel.fromJson(Map<String, dynamic> json) =
      _$VideoModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(fromJson: _idFromJson)
  String get userId;
  @override
  String get title;
  @override
  String? get description; // These three stay null until transcoding finishes.
  @override
  String? get thumbnailUrl;
  @override
  String? get hlsUrl;
  @override
  int? get durationSeconds;
  @override
  @JsonKey(unknownEnumValue: VideoStatus.unknown)
  VideoStatus get status;
  @override
  @JsonKey(unknownEnumValue: VideoVisibility.unknown)
  VideoVisibility get visibility; // Updated asynchronously via Kafka, so they lag behind a like/comment that
  // just happened — a value to sync against on reload, not an immediate
  // result (video doc 5).
  @override
  int get viewCount;
  @override
  int get likeCount;
  @override
  int get commentCount; // Save/share have no counter in the API yet, so they default to 0 and the
  // rail falls back to a plain label — same arrangement as
  // CommentModel.replyCount.
  @override
  int get saveCount;
  @override
  int get shareCount;
  @override
  DateTime get createdAt;

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoModelImplCopyWith<_$VideoModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
