// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StoryModel _$StoryModelFromJson(Map<String, dynamic> json) {
  return _StoryModel.fromJson(json);
}

/// @nodoc
mixin _$StoryModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _idFromJson)
  String get userId => throw _privateConstructorUsedError;
  String get mediaUrl => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: StoryMediaType.unknown)
  StoryMediaType get mediaType => throw _privateConstructorUsedError;
  String? get caption => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: StoryVisibility.unknown)
  StoryVisibility get visibility => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: StoryStatus.unknown)
  StoryStatus? get status => throw _privateConstructorUsedError;
  int? get durationSeconds => throw _privateConstructorUsedError;
  int? get viewCount => throw _privateConstructorUsedError;
  bool get viewedByMe => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: StoryReaction.unknown)
  StoryReaction? get myReaction => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _countsFromJson, toJson: _countsToJson)
  Map<StoryReaction, int>? get reactionCounts =>
      throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this StoryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoryModelCopyWith<StoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoryModelCopyWith<$Res> {
  factory $StoryModelCopyWith(
    StoryModel value,
    $Res Function(StoryModel) then,
  ) = _$StoryModelCopyWithImpl<$Res, StoryModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(fromJson: _idFromJson) String userId,
    String mediaUrl,
    @JsonKey(unknownEnumValue: StoryMediaType.unknown) StoryMediaType mediaType,
    String? caption,
    @JsonKey(unknownEnumValue: StoryVisibility.unknown)
    StoryVisibility visibility,
    @JsonKey(unknownEnumValue: StoryStatus.unknown) StoryStatus? status,
    int? durationSeconds,
    int? viewCount,
    bool viewedByMe,
    @JsonKey(unknownEnumValue: StoryReaction.unknown) StoryReaction? myReaction,
    @JsonKey(fromJson: _countsFromJson, toJson: _countsToJson)
    Map<StoryReaction, int>? reactionCounts,
    DateTime createdAt,
    DateTime expiresAt,
  });
}

/// @nodoc
class _$StoryModelCopyWithImpl<$Res, $Val extends StoryModel>
    implements $StoryModelCopyWith<$Res> {
  _$StoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? mediaUrl = null,
    Object? mediaType = null,
    Object? caption = freezed,
    Object? visibility = null,
    Object? status = freezed,
    Object? durationSeconds = freezed,
    Object? viewCount = freezed,
    Object? viewedByMe = null,
    Object? myReaction = freezed,
    Object? reactionCounts = freezed,
    Object? createdAt = null,
    Object? expiresAt = null,
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
            mediaUrl: null == mediaUrl
                ? _value.mediaUrl
                : mediaUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            mediaType: null == mediaType
                ? _value.mediaType
                : mediaType // ignore: cast_nullable_to_non_nullable
                      as StoryMediaType,
            caption: freezed == caption
                ? _value.caption
                : caption // ignore: cast_nullable_to_non_nullable
                      as String?,
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as StoryVisibility,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as StoryStatus?,
            durationSeconds: freezed == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
            viewCount: freezed == viewCount
                ? _value.viewCount
                : viewCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            viewedByMe: null == viewedByMe
                ? _value.viewedByMe
                : viewedByMe // ignore: cast_nullable_to_non_nullable
                      as bool,
            myReaction: freezed == myReaction
                ? _value.myReaction
                : myReaction // ignore: cast_nullable_to_non_nullable
                      as StoryReaction?,
            reactionCounts: freezed == reactionCounts
                ? _value.reactionCounts
                : reactionCounts // ignore: cast_nullable_to_non_nullable
                      as Map<StoryReaction, int>?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StoryModelImplCopyWith<$Res>
    implements $StoryModelCopyWith<$Res> {
  factory _$$StoryModelImplCopyWith(
    _$StoryModelImpl value,
    $Res Function(_$StoryModelImpl) then,
  ) = __$$StoryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(fromJson: _idFromJson) String userId,
    String mediaUrl,
    @JsonKey(unknownEnumValue: StoryMediaType.unknown) StoryMediaType mediaType,
    String? caption,
    @JsonKey(unknownEnumValue: StoryVisibility.unknown)
    StoryVisibility visibility,
    @JsonKey(unknownEnumValue: StoryStatus.unknown) StoryStatus? status,
    int? durationSeconds,
    int? viewCount,
    bool viewedByMe,
    @JsonKey(unknownEnumValue: StoryReaction.unknown) StoryReaction? myReaction,
    @JsonKey(fromJson: _countsFromJson, toJson: _countsToJson)
    Map<StoryReaction, int>? reactionCounts,
    DateTime createdAt,
    DateTime expiresAt,
  });
}

/// @nodoc
class __$$StoryModelImplCopyWithImpl<$Res>
    extends _$StoryModelCopyWithImpl<$Res, _$StoryModelImpl>
    implements _$$StoryModelImplCopyWith<$Res> {
  __$$StoryModelImplCopyWithImpl(
    _$StoryModelImpl _value,
    $Res Function(_$StoryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? mediaUrl = null,
    Object? mediaType = null,
    Object? caption = freezed,
    Object? visibility = null,
    Object? status = freezed,
    Object? durationSeconds = freezed,
    Object? viewCount = freezed,
    Object? viewedByMe = null,
    Object? myReaction = freezed,
    Object? reactionCounts = freezed,
    Object? createdAt = null,
    Object? expiresAt = null,
  }) {
    return _then(
      _$StoryModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        mediaUrl: null == mediaUrl
            ? _value.mediaUrl
            : mediaUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        mediaType: null == mediaType
            ? _value.mediaType
            : mediaType // ignore: cast_nullable_to_non_nullable
                  as StoryMediaType,
        caption: freezed == caption
            ? _value.caption
            : caption // ignore: cast_nullable_to_non_nullable
                  as String?,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as StoryVisibility,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as StoryStatus?,
        durationSeconds: freezed == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
        viewCount: freezed == viewCount
            ? _value.viewCount
            : viewCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        viewedByMe: null == viewedByMe
            ? _value.viewedByMe
            : viewedByMe // ignore: cast_nullable_to_non_nullable
                  as bool,
        myReaction: freezed == myReaction
            ? _value.myReaction
            : myReaction // ignore: cast_nullable_to_non_nullable
                  as StoryReaction?,
        reactionCounts: freezed == reactionCounts
            ? _value._reactionCounts
            : reactionCounts // ignore: cast_nullable_to_non_nullable
                  as Map<StoryReaction, int>?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StoryModelImpl implements _StoryModel {
  const _$StoryModelImpl({
    required this.id,
    @JsonKey(fromJson: _idFromJson) required this.userId,
    required this.mediaUrl,
    @JsonKey(unknownEnumValue: StoryMediaType.unknown) required this.mediaType,
    this.caption,
    @JsonKey(unknownEnumValue: StoryVisibility.unknown)
    required this.visibility,
    @JsonKey(unknownEnumValue: StoryStatus.unknown) this.status,
    this.durationSeconds,
    this.viewCount,
    this.viewedByMe = false,
    @JsonKey(unknownEnumValue: StoryReaction.unknown) this.myReaction,
    @JsonKey(fromJson: _countsFromJson, toJson: _countsToJson)
    final Map<StoryReaction, int>? reactionCounts,
    required this.createdAt,
    required this.expiresAt,
  }) : _reactionCounts = reactionCounts;

  factory _$StoryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoryModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(fromJson: _idFromJson)
  final String userId;
  @override
  final String mediaUrl;
  @override
  @JsonKey(unknownEnumValue: StoryMediaType.unknown)
  final StoryMediaType mediaType;
  @override
  final String? caption;
  @override
  @JsonKey(unknownEnumValue: StoryVisibility.unknown)
  final StoryVisibility visibility;
  @override
  @JsonKey(unknownEnumValue: StoryStatus.unknown)
  final StoryStatus? status;
  @override
  final int? durationSeconds;
  @override
  final int? viewCount;
  @override
  @JsonKey()
  final bool viewedByMe;
  @override
  @JsonKey(unknownEnumValue: StoryReaction.unknown)
  final StoryReaction? myReaction;
  final Map<StoryReaction, int>? _reactionCounts;
  @override
  @JsonKey(fromJson: _countsFromJson, toJson: _countsToJson)
  Map<StoryReaction, int>? get reactionCounts {
    final value = _reactionCounts;
    if (value == null) return null;
    if (_reactionCounts is EqualUnmodifiableMapView) return _reactionCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime expiresAt;

  @override
  String toString() {
    return 'StoryModel(id: $id, userId: $userId, mediaUrl: $mediaUrl, mediaType: $mediaType, caption: $caption, visibility: $visibility, status: $status, durationSeconds: $durationSeconds, viewCount: $viewCount, viewedByMe: $viewedByMe, myReaction: $myReaction, reactionCounts: $reactionCounts, createdAt: $createdAt, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.mediaType, mediaType) ||
                other.mediaType == mediaType) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.viewedByMe, viewedByMe) ||
                other.viewedByMe == viewedByMe) &&
            (identical(other.myReaction, myReaction) ||
                other.myReaction == myReaction) &&
            const DeepCollectionEquality().equals(
              other._reactionCounts,
              _reactionCounts,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    mediaUrl,
    mediaType,
    caption,
    visibility,
    status,
    durationSeconds,
    viewCount,
    viewedByMe,
    myReaction,
    const DeepCollectionEquality().hash(_reactionCounts),
    createdAt,
    expiresAt,
  );

  /// Create a copy of StoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoryModelImplCopyWith<_$StoryModelImpl> get copyWith =>
      __$$StoryModelImplCopyWithImpl<_$StoryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoryModelImplToJson(this);
  }
}

abstract class _StoryModel implements StoryModel {
  const factory _StoryModel({
    required final String id,
    @JsonKey(fromJson: _idFromJson) required final String userId,
    required final String mediaUrl,
    @JsonKey(unknownEnumValue: StoryMediaType.unknown)
    required final StoryMediaType mediaType,
    final String? caption,
    @JsonKey(unknownEnumValue: StoryVisibility.unknown)
    required final StoryVisibility visibility,
    @JsonKey(unknownEnumValue: StoryStatus.unknown) final StoryStatus? status,
    final int? durationSeconds,
    final int? viewCount,
    final bool viewedByMe,
    @JsonKey(unknownEnumValue: StoryReaction.unknown)
    final StoryReaction? myReaction,
    @JsonKey(fromJson: _countsFromJson, toJson: _countsToJson)
    final Map<StoryReaction, int>? reactionCounts,
    required final DateTime createdAt,
    required final DateTime expiresAt,
  }) = _$StoryModelImpl;

  factory _StoryModel.fromJson(Map<String, dynamic> json) =
      _$StoryModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(fromJson: _idFromJson)
  String get userId;
  @override
  String get mediaUrl;
  @override
  @JsonKey(unknownEnumValue: StoryMediaType.unknown)
  StoryMediaType get mediaType;
  @override
  String? get caption;
  @override
  @JsonKey(unknownEnumValue: StoryVisibility.unknown)
  StoryVisibility get visibility;
  @override
  @JsonKey(unknownEnumValue: StoryStatus.unknown)
  StoryStatus? get status;
  @override
  int? get durationSeconds;
  @override
  int? get viewCount;
  @override
  bool get viewedByMe;
  @override
  @JsonKey(unknownEnumValue: StoryReaction.unknown)
  StoryReaction? get myReaction;
  @override
  @JsonKey(fromJson: _countsFromJson, toJson: _countsToJson)
  Map<StoryReaction, int>? get reactionCounts;
  @override
  DateTime get createdAt;
  @override
  DateTime get expiresAt;

  /// Create a copy of StoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoryModelImplCopyWith<_$StoryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoryGroup _$StoryGroupFromJson(Map<String, dynamic> json) {
  return _StoryGroup.fromJson(json);
}

/// @nodoc
mixin _$StoryGroup {
  @JsonKey(fromJson: _idFromJson)
  String get userId => throw _privateConstructorUsedError;
  List<StoryModel> get stories => throw _privateConstructorUsedError;
  bool get hasUnseen => throw _privateConstructorUsedError;

  /// Serializes this StoryGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoryGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoryGroupCopyWith<StoryGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoryGroupCopyWith<$Res> {
  factory $StoryGroupCopyWith(
    StoryGroup value,
    $Res Function(StoryGroup) then,
  ) = _$StoryGroupCopyWithImpl<$Res, StoryGroup>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String userId,
    List<StoryModel> stories,
    bool hasUnseen,
  });
}

/// @nodoc
class _$StoryGroupCopyWithImpl<$Res, $Val extends StoryGroup>
    implements $StoryGroupCopyWith<$Res> {
  _$StoryGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoryGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? stories = null,
    Object? hasUnseen = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            stories: null == stories
                ? _value.stories
                : stories // ignore: cast_nullable_to_non_nullable
                      as List<StoryModel>,
            hasUnseen: null == hasUnseen
                ? _value.hasUnseen
                : hasUnseen // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StoryGroupImplCopyWith<$Res>
    implements $StoryGroupCopyWith<$Res> {
  factory _$$StoryGroupImplCopyWith(
    _$StoryGroupImpl value,
    $Res Function(_$StoryGroupImpl) then,
  ) = __$$StoryGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String userId,
    List<StoryModel> stories,
    bool hasUnseen,
  });
}

/// @nodoc
class __$$StoryGroupImplCopyWithImpl<$Res>
    extends _$StoryGroupCopyWithImpl<$Res, _$StoryGroupImpl>
    implements _$$StoryGroupImplCopyWith<$Res> {
  __$$StoryGroupImplCopyWithImpl(
    _$StoryGroupImpl _value,
    $Res Function(_$StoryGroupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StoryGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? stories = null,
    Object? hasUnseen = null,
  }) {
    return _then(
      _$StoryGroupImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        stories: null == stories
            ? _value._stories
            : stories // ignore: cast_nullable_to_non_nullable
                  as List<StoryModel>,
        hasUnseen: null == hasUnseen
            ? _value.hasUnseen
            : hasUnseen // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StoryGroupImpl implements _StoryGroup {
  const _$StoryGroupImpl({
    @JsonKey(fromJson: _idFromJson) required this.userId,
    required final List<StoryModel> stories,
    this.hasUnseen = false,
  }) : _stories = stories;

  factory _$StoryGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoryGroupImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String userId;
  final List<StoryModel> _stories;
  @override
  List<StoryModel> get stories {
    if (_stories is EqualUnmodifiableListView) return _stories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stories);
  }

  @override
  @JsonKey()
  final bool hasUnseen;

  @override
  String toString() {
    return 'StoryGroup(userId: $userId, stories: $stories, hasUnseen: $hasUnseen)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoryGroupImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other._stories, _stories) &&
            (identical(other.hasUnseen, hasUnseen) ||
                other.hasUnseen == hasUnseen));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    const DeepCollectionEquality().hash(_stories),
    hasUnseen,
  );

  /// Create a copy of StoryGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoryGroupImplCopyWith<_$StoryGroupImpl> get copyWith =>
      __$$StoryGroupImplCopyWithImpl<_$StoryGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoryGroupImplToJson(this);
  }
}

abstract class _StoryGroup implements StoryGroup {
  const factory _StoryGroup({
    @JsonKey(fromJson: _idFromJson) required final String userId,
    required final List<StoryModel> stories,
    final bool hasUnseen,
  }) = _$StoryGroupImpl;

  factory _StoryGroup.fromJson(Map<String, dynamic> json) =
      _$StoryGroupImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get userId;
  @override
  List<StoryModel> get stories;
  @override
  bool get hasUnseen;

  /// Create a copy of StoryGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoryGroupImplCopyWith<_$StoryGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoryRing _$StoryRingFromJson(Map<String, dynamic> json) {
  return _StoryRing.fromJson(json);
}

/// @nodoc
mixin _$StoryRing {
  @JsonKey(fromJson: _idFromJson)
  String get userId => throw _privateConstructorUsedError;
  bool get hasUnseen => throw _privateConstructorUsedError;

  /// Serializes this StoryRing to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoryRing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoryRingCopyWith<StoryRing> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoryRingCopyWith<$Res> {
  factory $StoryRingCopyWith(StoryRing value, $Res Function(StoryRing) then) =
      _$StoryRingCopyWithImpl<$Res, StoryRing>;
  @useResult
  $Res call({@JsonKey(fromJson: _idFromJson) String userId, bool hasUnseen});
}

/// @nodoc
class _$StoryRingCopyWithImpl<$Res, $Val extends StoryRing>
    implements $StoryRingCopyWith<$Res> {
  _$StoryRingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoryRing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? hasUnseen = null}) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            hasUnseen: null == hasUnseen
                ? _value.hasUnseen
                : hasUnseen // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StoryRingImplCopyWith<$Res>
    implements $StoryRingCopyWith<$Res> {
  factory _$$StoryRingImplCopyWith(
    _$StoryRingImpl value,
    $Res Function(_$StoryRingImpl) then,
  ) = __$$StoryRingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(fromJson: _idFromJson) String userId, bool hasUnseen});
}

/// @nodoc
class __$$StoryRingImplCopyWithImpl<$Res>
    extends _$StoryRingCopyWithImpl<$Res, _$StoryRingImpl>
    implements _$$StoryRingImplCopyWith<$Res> {
  __$$StoryRingImplCopyWithImpl(
    _$StoryRingImpl _value,
    $Res Function(_$StoryRingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StoryRing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? hasUnseen = null}) {
    return _then(
      _$StoryRingImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        hasUnseen: null == hasUnseen
            ? _value.hasUnseen
            : hasUnseen // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StoryRingImpl implements _StoryRing {
  const _$StoryRingImpl({
    @JsonKey(fromJson: _idFromJson) required this.userId,
    this.hasUnseen = false,
  });

  factory _$StoryRingImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoryRingImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String userId;
  @override
  @JsonKey()
  final bool hasUnseen;

  @override
  String toString() {
    return 'StoryRing(userId: $userId, hasUnseen: $hasUnseen)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoryRingImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.hasUnseen, hasUnseen) ||
                other.hasUnseen == hasUnseen));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, hasUnseen);

  /// Create a copy of StoryRing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoryRingImplCopyWith<_$StoryRingImpl> get copyWith =>
      __$$StoryRingImplCopyWithImpl<_$StoryRingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoryRingImplToJson(this);
  }
}

abstract class _StoryRing implements StoryRing {
  const factory _StoryRing({
    @JsonKey(fromJson: _idFromJson) required final String userId,
    final bool hasUnseen,
  }) = _$StoryRingImpl;

  factory _StoryRing.fromJson(Map<String, dynamic> json) =
      _$StoryRingImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get userId;
  @override
  bool get hasUnseen;

  /// Create a copy of StoryRing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoryRingImplCopyWith<_$StoryRingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoryViewer _$StoryViewerFromJson(Map<String, dynamic> json) {
  return _StoryViewer.fromJson(json);
}

/// @nodoc
mixin _$StoryViewer {
  @JsonKey(fromJson: _idFromJson)
  String get viewerId => throw _privateConstructorUsedError;
  DateTime get viewedAt => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: StoryReaction.unknown)
  StoryReaction? get reaction => throw _privateConstructorUsedError;

  /// Serializes this StoryViewer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoryViewer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoryViewerCopyWith<StoryViewer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoryViewerCopyWith<$Res> {
  factory $StoryViewerCopyWith(
    StoryViewer value,
    $Res Function(StoryViewer) then,
  ) = _$StoryViewerCopyWithImpl<$Res, StoryViewer>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String viewerId,
    DateTime viewedAt,
    @JsonKey(unknownEnumValue: StoryReaction.unknown) StoryReaction? reaction,
  });
}

/// @nodoc
class _$StoryViewerCopyWithImpl<$Res, $Val extends StoryViewer>
    implements $StoryViewerCopyWith<$Res> {
  _$StoryViewerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoryViewer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? viewerId = null,
    Object? viewedAt = null,
    Object? reaction = freezed,
  }) {
    return _then(
      _value.copyWith(
            viewerId: null == viewerId
                ? _value.viewerId
                : viewerId // ignore: cast_nullable_to_non_nullable
                      as String,
            viewedAt: null == viewedAt
                ? _value.viewedAt
                : viewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            reaction: freezed == reaction
                ? _value.reaction
                : reaction // ignore: cast_nullable_to_non_nullable
                      as StoryReaction?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StoryViewerImplCopyWith<$Res>
    implements $StoryViewerCopyWith<$Res> {
  factory _$$StoryViewerImplCopyWith(
    _$StoryViewerImpl value,
    $Res Function(_$StoryViewerImpl) then,
  ) = __$$StoryViewerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String viewerId,
    DateTime viewedAt,
    @JsonKey(unknownEnumValue: StoryReaction.unknown) StoryReaction? reaction,
  });
}

/// @nodoc
class __$$StoryViewerImplCopyWithImpl<$Res>
    extends _$StoryViewerCopyWithImpl<$Res, _$StoryViewerImpl>
    implements _$$StoryViewerImplCopyWith<$Res> {
  __$$StoryViewerImplCopyWithImpl(
    _$StoryViewerImpl _value,
    $Res Function(_$StoryViewerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StoryViewer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? viewerId = null,
    Object? viewedAt = null,
    Object? reaction = freezed,
  }) {
    return _then(
      _$StoryViewerImpl(
        viewerId: null == viewerId
            ? _value.viewerId
            : viewerId // ignore: cast_nullable_to_non_nullable
                  as String,
        viewedAt: null == viewedAt
            ? _value.viewedAt
            : viewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        reaction: freezed == reaction
            ? _value.reaction
            : reaction // ignore: cast_nullable_to_non_nullable
                  as StoryReaction?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StoryViewerImpl implements _StoryViewer {
  const _$StoryViewerImpl({
    @JsonKey(fromJson: _idFromJson) required this.viewerId,
    required this.viewedAt,
    @JsonKey(unknownEnumValue: StoryReaction.unknown) this.reaction,
  });

  factory _$StoryViewerImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoryViewerImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String viewerId;
  @override
  final DateTime viewedAt;
  @override
  @JsonKey(unknownEnumValue: StoryReaction.unknown)
  final StoryReaction? reaction;

  @override
  String toString() {
    return 'StoryViewer(viewerId: $viewerId, viewedAt: $viewedAt, reaction: $reaction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoryViewerImpl &&
            (identical(other.viewerId, viewerId) ||
                other.viewerId == viewerId) &&
            (identical(other.viewedAt, viewedAt) ||
                other.viewedAt == viewedAt) &&
            (identical(other.reaction, reaction) ||
                other.reaction == reaction));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, viewerId, viewedAt, reaction);

  /// Create a copy of StoryViewer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoryViewerImplCopyWith<_$StoryViewerImpl> get copyWith =>
      __$$StoryViewerImplCopyWithImpl<_$StoryViewerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoryViewerImplToJson(this);
  }
}

abstract class _StoryViewer implements StoryViewer {
  const factory _StoryViewer({
    @JsonKey(fromJson: _idFromJson) required final String viewerId,
    required final DateTime viewedAt,
    @JsonKey(unknownEnumValue: StoryReaction.unknown)
    final StoryReaction? reaction,
  }) = _$StoryViewerImpl;

  factory _StoryViewer.fromJson(Map<String, dynamic> json) =
      _$StoryViewerImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get viewerId;
  @override
  DateTime get viewedAt;
  @override
  @JsonKey(unknownEnumValue: StoryReaction.unknown)
  StoryReaction? get reaction;

  /// Create a copy of StoryViewer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoryViewerImplCopyWith<_$StoryViewerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
