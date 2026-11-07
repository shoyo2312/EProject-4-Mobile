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
  VideoVisibility get visibility => throw _privateConstructorUsedError;

  /// Set by the owner. New comments are refused while it is true; the ones
  /// already posted stay readable.
  bool get commentsDisabled =>
      throw _privateConstructorUsedError; // Updated asynchronously via Kafka, so they lag behind a like/comment that
  // just happened — a value to sync against on reload, not an immediate
  // result (video doc 5).
  int get viewCount => throw _privateConstructorUsedError;
  int get likeCount =>
      throw _privateConstructorUsedError; // Null from the server while comments are off — the video's own switch or
  // the owner's account setting (video doc 3.2) — and the total is not shown
  // then, so 0 stands in.
  @JsonKey(fromJson: _countOrZero)
  int get commentCount => throw _privateConstructorUsedError; // Shares have no counter on VideoResponse, so this stays 0 and the rail
  // falls back to a plain label. Saves have no counter anywhere — a save is
  // private — so there is no field for them at all.
  int get shareCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// The song under the video and its credit; null without one.
  MusicCredit? get music => throw _privateConstructorUsedError;

  /// When the owner pinned it to the top of their profile; null when not
  /// pinned. At most three are pinned at once.
  DateTime? get pinnedAt => throw _privateConstructorUsedError;

  /// Why transcoding failed (FAILED) or why a moderator removed it
  /// (TAKEN_DOWN). Sent to the owner only.
  String? get failureReason => throw _privateConstructorUsedError;
  String? get takedownReason => throw _privateConstructorUsedError;

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
    bool commentsDisabled,
    int viewCount,
    int likeCount,
    @JsonKey(fromJson: _countOrZero) int commentCount,
    int shareCount,
    DateTime createdAt,
    MusicCredit? music,
    DateTime? pinnedAt,
    String? failureReason,
    String? takedownReason,
  });

  $MusicCreditCopyWith<$Res>? get music;
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
    Object? commentsDisabled = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? shareCount = null,
    Object? createdAt = null,
    Object? music = freezed,
    Object? pinnedAt = freezed,
    Object? failureReason = freezed,
    Object? takedownReason = freezed,
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
            commentsDisabled: null == commentsDisabled
                ? _value.commentsDisabled
                : commentsDisabled // ignore: cast_nullable_to_non_nullable
                      as bool,
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
            shareCount: null == shareCount
                ? _value.shareCount
                : shareCount // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            music: freezed == music
                ? _value.music
                : music // ignore: cast_nullable_to_non_nullable
                      as MusicCredit?,
            pinnedAt: freezed == pinnedAt
                ? _value.pinnedAt
                : pinnedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            failureReason: freezed == failureReason
                ? _value.failureReason
                : failureReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            takedownReason: freezed == takedownReason
                ? _value.takedownReason
                : takedownReason // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MusicCreditCopyWith<$Res>? get music {
    if (_value.music == null) {
      return null;
    }

    return $MusicCreditCopyWith<$Res>(_value.music!, (value) {
      return _then(_value.copyWith(music: value) as $Val);
    });
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
    bool commentsDisabled,
    int viewCount,
    int likeCount,
    @JsonKey(fromJson: _countOrZero) int commentCount,
    int shareCount,
    DateTime createdAt,
    MusicCredit? music,
    DateTime? pinnedAt,
    String? failureReason,
    String? takedownReason,
  });

  @override
  $MusicCreditCopyWith<$Res>? get music;
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
    Object? commentsDisabled = null,
    Object? viewCount = null,
    Object? likeCount = null,
    Object? commentCount = null,
    Object? shareCount = null,
    Object? createdAt = null,
    Object? music = freezed,
    Object? pinnedAt = freezed,
    Object? failureReason = freezed,
    Object? takedownReason = freezed,
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
        commentsDisabled: null == commentsDisabled
            ? _value.commentsDisabled
            : commentsDisabled // ignore: cast_nullable_to_non_nullable
                  as bool,
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
        shareCount: null == shareCount
            ? _value.shareCount
            : shareCount // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        music: freezed == music
            ? _value.music
            : music // ignore: cast_nullable_to_non_nullable
                  as MusicCredit?,
        pinnedAt: freezed == pinnedAt
            ? _value.pinnedAt
            : pinnedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        failureReason: freezed == failureReason
            ? _value.failureReason
            : failureReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        takedownReason: freezed == takedownReason
            ? _value.takedownReason
            : takedownReason // ignore: cast_nullable_to_non_nullable
                  as String?,
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
    this.commentsDisabled = false,
    required this.viewCount,
    required this.likeCount,
    @JsonKey(fromJson: _countOrZero) required this.commentCount,
    this.shareCount = 0,
    required this.createdAt,
    this.music,
    this.pinnedAt,
    this.failureReason,
    this.takedownReason,
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

  /// Set by the owner. New comments are refused while it is true; the ones
  /// already posted stay readable.
  @override
  @JsonKey()
  final bool commentsDisabled;
  // Updated asynchronously via Kafka, so they lag behind a like/comment that
  // just happened — a value to sync against on reload, not an immediate
  // result (video doc 5).
  @override
  final int viewCount;
  @override
  final int likeCount;
  // Null from the server while comments are off — the video's own switch or
  // the owner's account setting (video doc 3.2) — and the total is not shown
  // then, so 0 stands in.
  @override
  @JsonKey(fromJson: _countOrZero)
  final int commentCount;
  // Shares have no counter on VideoResponse, so this stays 0 and the rail
  // falls back to a plain label. Saves have no counter anywhere — a save is
  // private — so there is no field for them at all.
  @override
  @JsonKey()
  final int shareCount;
  @override
  final DateTime createdAt;

  /// The song under the video and its credit; null without one.
  @override
  final MusicCredit? music;

  /// When the owner pinned it to the top of their profile; null when not
  /// pinned. At most three are pinned at once.
  @override
  final DateTime? pinnedAt;

  /// Why transcoding failed (FAILED) or why a moderator removed it
  /// (TAKEN_DOWN). Sent to the owner only.
  @override
  final String? failureReason;
  @override
  final String? takedownReason;

  @override
  String toString() {
    return 'VideoModel(id: $id, userId: $userId, title: $title, description: $description, thumbnailUrl: $thumbnailUrl, hlsUrl: $hlsUrl, durationSeconds: $durationSeconds, status: $status, visibility: $visibility, commentsDisabled: $commentsDisabled, viewCount: $viewCount, likeCount: $likeCount, commentCount: $commentCount, shareCount: $shareCount, createdAt: $createdAt, music: $music, pinnedAt: $pinnedAt, failureReason: $failureReason, takedownReason: $takedownReason)';
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
            (identical(other.commentsDisabled, commentsDisabled) ||
                other.commentsDisabled == commentsDisabled) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.shareCount, shareCount) ||
                other.shareCount == shareCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.music, music) || other.music == music) &&
            (identical(other.pinnedAt, pinnedAt) ||
                other.pinnedAt == pinnedAt) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason) &&
            (identical(other.takedownReason, takedownReason) ||
                other.takedownReason == takedownReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
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
    commentsDisabled,
    viewCount,
    likeCount,
    commentCount,
    shareCount,
    createdAt,
    music,
    pinnedAt,
    failureReason,
    takedownReason,
  ]);

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
    final bool commentsDisabled,
    required final int viewCount,
    required final int likeCount,
    @JsonKey(fromJson: _countOrZero) required final int commentCount,
    final int shareCount,
    required final DateTime createdAt,
    final MusicCredit? music,
    final DateTime? pinnedAt,
    final String? failureReason,
    final String? takedownReason,
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
  VideoVisibility get visibility;

  /// Set by the owner. New comments are refused while it is true; the ones
  /// already posted stay readable.
  @override
  bool get commentsDisabled; // Updated asynchronously via Kafka, so they lag behind a like/comment that
  // just happened — a value to sync against on reload, not an immediate
  // result (video doc 5).
  @override
  int get viewCount;
  @override
  int get likeCount; // Null from the server while comments are off — the video's own switch or
  // the owner's account setting (video doc 3.2) — and the total is not shown
  // then, so 0 stands in.
  @override
  @JsonKey(fromJson: _countOrZero)
  int get commentCount; // Shares have no counter on VideoResponse, so this stays 0 and the rail
  // falls back to a plain label. Saves have no counter anywhere — a save is
  // private — so there is no field for them at all.
  @override
  int get shareCount;
  @override
  DateTime get createdAt;

  /// The song under the video and its credit; null without one.
  @override
  MusicCredit? get music;

  /// When the owner pinned it to the top of their profile; null when not
  /// pinned. At most three are pinned at once.
  @override
  DateTime? get pinnedAt;

  /// Why transcoding failed (FAILED) or why a moderator removed it
  /// (TAKEN_DOWN). Sent to the owner only.
  @override
  String? get failureReason;
  @override
  String? get takedownReason;

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoModelImplCopyWith<_$VideoModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MusicCredit _$MusicCreditFromJson(Map<String, dynamic> json) {
  return _MusicCredit.fromJson(json);
}

/// @nodoc
mixin _$MusicCredit {
  String get title => throw _privateConstructorUsedError;
  String get artist => throw _privateConstructorUsedError;
  String? get trackId => throw _privateConstructorUsedError;
  String? get licenseUrl => throw _privateConstructorUsedError;
  String? get shareUrl => throw _privateConstructorUsedError;

  /// Serializes this MusicCredit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MusicCredit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MusicCreditCopyWith<MusicCredit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MusicCreditCopyWith<$Res> {
  factory $MusicCreditCopyWith(
    MusicCredit value,
    $Res Function(MusicCredit) then,
  ) = _$MusicCreditCopyWithImpl<$Res, MusicCredit>;
  @useResult
  $Res call({
    String title,
    String artist,
    String? trackId,
    String? licenseUrl,
    String? shareUrl,
  });
}

/// @nodoc
class _$MusicCreditCopyWithImpl<$Res, $Val extends MusicCredit>
    implements $MusicCreditCopyWith<$Res> {
  _$MusicCreditCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MusicCredit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? artist = null,
    Object? trackId = freezed,
    Object? licenseUrl = freezed,
    Object? shareUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            artist: null == artist
                ? _value.artist
                : artist // ignore: cast_nullable_to_non_nullable
                      as String,
            trackId: freezed == trackId
                ? _value.trackId
                : trackId // ignore: cast_nullable_to_non_nullable
                      as String?,
            licenseUrl: freezed == licenseUrl
                ? _value.licenseUrl
                : licenseUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            shareUrl: freezed == shareUrl
                ? _value.shareUrl
                : shareUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MusicCreditImplCopyWith<$Res>
    implements $MusicCreditCopyWith<$Res> {
  factory _$$MusicCreditImplCopyWith(
    _$MusicCreditImpl value,
    $Res Function(_$MusicCreditImpl) then,
  ) = __$$MusicCreditImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String artist,
    String? trackId,
    String? licenseUrl,
    String? shareUrl,
  });
}

/// @nodoc
class __$$MusicCreditImplCopyWithImpl<$Res>
    extends _$MusicCreditCopyWithImpl<$Res, _$MusicCreditImpl>
    implements _$$MusicCreditImplCopyWith<$Res> {
  __$$MusicCreditImplCopyWithImpl(
    _$MusicCreditImpl _value,
    $Res Function(_$MusicCreditImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MusicCredit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? artist = null,
    Object? trackId = freezed,
    Object? licenseUrl = freezed,
    Object? shareUrl = freezed,
  }) {
    return _then(
      _$MusicCreditImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        artist: null == artist
            ? _value.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as String,
        trackId: freezed == trackId
            ? _value.trackId
            : trackId // ignore: cast_nullable_to_non_nullable
                  as String?,
        licenseUrl: freezed == licenseUrl
            ? _value.licenseUrl
            : licenseUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        shareUrl: freezed == shareUrl
            ? _value.shareUrl
            : shareUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MusicCreditImpl implements _MusicCredit {
  const _$MusicCreditImpl({
    required this.title,
    required this.artist,
    this.trackId,
    this.licenseUrl,
    this.shareUrl,
  });

  factory _$MusicCreditImpl.fromJson(Map<String, dynamic> json) =>
      _$$MusicCreditImplFromJson(json);

  @override
  final String title;
  @override
  final String artist;
  @override
  final String? trackId;
  @override
  final String? licenseUrl;
  @override
  final String? shareUrl;

  @override
  String toString() {
    return 'MusicCredit(title: $title, artist: $artist, trackId: $trackId, licenseUrl: $licenseUrl, shareUrl: $shareUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MusicCreditImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.trackId, trackId) || other.trackId == trackId) &&
            (identical(other.licenseUrl, licenseUrl) ||
                other.licenseUrl == licenseUrl) &&
            (identical(other.shareUrl, shareUrl) ||
                other.shareUrl == shareUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, title, artist, trackId, licenseUrl, shareUrl);

  /// Create a copy of MusicCredit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MusicCreditImplCopyWith<_$MusicCreditImpl> get copyWith =>
      __$$MusicCreditImplCopyWithImpl<_$MusicCreditImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MusicCreditImplToJson(this);
  }
}

abstract class _MusicCredit implements MusicCredit {
  const factory _MusicCredit({
    required final String title,
    required final String artist,
    final String? trackId,
    final String? licenseUrl,
    final String? shareUrl,
  }) = _$MusicCreditImpl;

  factory _MusicCredit.fromJson(Map<String, dynamic> json) =
      _$MusicCreditImpl.fromJson;

  @override
  String get title;
  @override
  String get artist;
  @override
  String? get trackId;
  @override
  String? get licenseUrl;
  @override
  String? get shareUrl;

  /// Create a copy of MusicCredit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MusicCreditImplCopyWith<_$MusicCreditImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
