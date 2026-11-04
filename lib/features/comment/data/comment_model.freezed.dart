// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CommentSticker _$CommentStickerFromJson(Map<String, dynamic> json) {
  return _CommentSticker.fromJson(json);
}

/// @nodoc
mixin _$CommentSticker {
  String get stickerId => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;

  /// Serializes this CommentSticker to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentSticker
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentStickerCopyWith<CommentSticker> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentStickerCopyWith<$Res> {
  factory $CommentStickerCopyWith(
    CommentSticker value,
    $Res Function(CommentSticker) then,
  ) = _$CommentStickerCopyWithImpl<$Res, CommentSticker>;
  @useResult
  $Res call({String stickerId, String url, int width, int height});
}

/// @nodoc
class _$CommentStickerCopyWithImpl<$Res, $Val extends CommentSticker>
    implements $CommentStickerCopyWith<$Res> {
  _$CommentStickerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentSticker
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stickerId = null,
    Object? url = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(
      _value.copyWith(
            stickerId: null == stickerId
                ? _value.stickerId
                : stickerId // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            width: null == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                      as int,
            height: null == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CommentStickerImplCopyWith<$Res>
    implements $CommentStickerCopyWith<$Res> {
  factory _$$CommentStickerImplCopyWith(
    _$CommentStickerImpl value,
    $Res Function(_$CommentStickerImpl) then,
  ) = __$$CommentStickerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String stickerId, String url, int width, int height});
}

/// @nodoc
class __$$CommentStickerImplCopyWithImpl<$Res>
    extends _$CommentStickerCopyWithImpl<$Res, _$CommentStickerImpl>
    implements _$$CommentStickerImplCopyWith<$Res> {
  __$$CommentStickerImplCopyWithImpl(
    _$CommentStickerImpl _value,
    $Res Function(_$CommentStickerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommentSticker
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stickerId = null,
    Object? url = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(
      _$CommentStickerImpl(
        stickerId: null == stickerId
            ? _value.stickerId
            : stickerId // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        width: null == width
            ? _value.width
            : width // ignore: cast_nullable_to_non_nullable
                  as int,
        height: null == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentStickerImpl implements _CommentSticker {
  const _$CommentStickerImpl({
    required this.stickerId,
    required this.url,
    this.width = 0,
    this.height = 0,
  });

  factory _$CommentStickerImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentStickerImplFromJson(json);

  @override
  final String stickerId;
  @override
  final String url;
  @override
  @JsonKey()
  final int width;
  @override
  @JsonKey()
  final int height;

  @override
  String toString() {
    return 'CommentSticker(stickerId: $stickerId, url: $url, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentStickerImpl &&
            (identical(other.stickerId, stickerId) ||
                other.stickerId == stickerId) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, stickerId, url, width, height);

  /// Create a copy of CommentSticker
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentStickerImplCopyWith<_$CommentStickerImpl> get copyWith =>
      __$$CommentStickerImplCopyWithImpl<_$CommentStickerImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentStickerImplToJson(this);
  }
}

abstract class _CommentSticker implements CommentSticker {
  const factory _CommentSticker({
    required final String stickerId,
    required final String url,
    final int width,
    final int height,
  }) = _$CommentStickerImpl;

  factory _CommentSticker.fromJson(Map<String, dynamic> json) =
      _$CommentStickerImpl.fromJson;

  @override
  String get stickerId;
  @override
  String get url;
  @override
  int get width;
  @override
  int get height;

  /// Create a copy of CommentSticker
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentStickerImplCopyWith<_$CommentStickerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) {
  return _CommentModel.fromJson(json);
}

/// @nodoc
mixin _$CommentModel {
  @JsonKey(name: 'commentId', fromJson: _idFromJson)
  String get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _idFromJson)
  String get videoId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _idFromJson)
  String get userId => throw _privateConstructorUsedError;

  /// Empty for a sticker-only comment.
  @JsonKey(name: 'content')
  String get text => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Null for a top-level comment; the top-level comment's id for a reply
  /// (the thread is one level deep — the server flattens deeper replies).
  @JsonKey(fromJson: _idOrNullFromJson)
  String? get parentId => throw _privateConstructorUsedError;

  /// Set only on a reply to another reply: whom it answers, for "A > B".
  @JsonKey(fromJson: _idOrNullFromJson)
  String? get replyToUserId => throw _privateConstructorUsedError;

  /// Live replies under a top-level comment. Always 0 on a reply.
  int get replyCount => throw _privateConstructorUsedError;
  CommentSticker? get sticker => throw _privateConstructorUsedError;

  /// Set once the author has edited the text.
  DateTime? get editedAt => throw _privateConstructorUsedError;

  /// Denormalised tally kept by interaction-service.
  int get likeCount => throw _privateConstructorUsedError;

  /// Always false on an anonymous listing — a guest has no hearts to fill.
  bool get likedByMe => throw _privateConstructorUsedError;

  /// Absent on rows written before moderation existed, which are visible.
  @JsonKey(unknownEnumValue: CommentStatus.unknown)
  CommentStatus get status => throw _privateConstructorUsedError;

  /// Serializes this CommentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentModelCopyWith<CommentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentModelCopyWith<$Res> {
  factory $CommentModelCopyWith(
    CommentModel value,
    $Res Function(CommentModel) then,
  ) = _$CommentModelCopyWithImpl<$Res, CommentModel>;
  @useResult
  $Res call({
    @JsonKey(name: 'commentId', fromJson: _idFromJson) String id,
    @JsonKey(fromJson: _idFromJson) String videoId,
    @JsonKey(fromJson: _idFromJson) String userId,
    @JsonKey(name: 'content') String text,
    DateTime createdAt,
    @JsonKey(fromJson: _idOrNullFromJson) String? parentId,
    @JsonKey(fromJson: _idOrNullFromJson) String? replyToUserId,
    int replyCount,
    CommentSticker? sticker,
    DateTime? editedAt,
    int likeCount,
    bool likedByMe,
    @JsonKey(unknownEnumValue: CommentStatus.unknown) CommentStatus status,
  });

  $CommentStickerCopyWith<$Res>? get sticker;
}

/// @nodoc
class _$CommentModelCopyWithImpl<$Res, $Val extends CommentModel>
    implements $CommentModelCopyWith<$Res> {
  _$CommentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? videoId = null,
    Object? userId = null,
    Object? text = null,
    Object? createdAt = null,
    Object? parentId = freezed,
    Object? replyToUserId = freezed,
    Object? replyCount = null,
    Object? sticker = freezed,
    Object? editedAt = freezed,
    Object? likeCount = null,
    Object? likedByMe = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            videoId: null == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            parentId: freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            replyToUserId: freezed == replyToUserId
                ? _value.replyToUserId
                : replyToUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
            replyCount: null == replyCount
                ? _value.replyCount
                : replyCount // ignore: cast_nullable_to_non_nullable
                      as int,
            sticker: freezed == sticker
                ? _value.sticker
                : sticker // ignore: cast_nullable_to_non_nullable
                      as CommentSticker?,
            editedAt: freezed == editedAt
                ? _value.editedAt
                : editedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            likedByMe: null == likedByMe
                ? _value.likedByMe
                : likedByMe // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as CommentStatus,
          )
          as $Val,
    );
  }

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CommentStickerCopyWith<$Res>? get sticker {
    if (_value.sticker == null) {
      return null;
    }

    return $CommentStickerCopyWith<$Res>(_value.sticker!, (value) {
      return _then(_value.copyWith(sticker: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommentModelImplCopyWith<$Res>
    implements $CommentModelCopyWith<$Res> {
  factory _$$CommentModelImplCopyWith(
    _$CommentModelImpl value,
    $Res Function(_$CommentModelImpl) then,
  ) = __$$CommentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'commentId', fromJson: _idFromJson) String id,
    @JsonKey(fromJson: _idFromJson) String videoId,
    @JsonKey(fromJson: _idFromJson) String userId,
    @JsonKey(name: 'content') String text,
    DateTime createdAt,
    @JsonKey(fromJson: _idOrNullFromJson) String? parentId,
    @JsonKey(fromJson: _idOrNullFromJson) String? replyToUserId,
    int replyCount,
    CommentSticker? sticker,
    DateTime? editedAt,
    int likeCount,
    bool likedByMe,
    @JsonKey(unknownEnumValue: CommentStatus.unknown) CommentStatus status,
  });

  @override
  $CommentStickerCopyWith<$Res>? get sticker;
}

/// @nodoc
class __$$CommentModelImplCopyWithImpl<$Res>
    extends _$CommentModelCopyWithImpl<$Res, _$CommentModelImpl>
    implements _$$CommentModelImplCopyWith<$Res> {
  __$$CommentModelImplCopyWithImpl(
    _$CommentModelImpl _value,
    $Res Function(_$CommentModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? videoId = null,
    Object? userId = null,
    Object? text = null,
    Object? createdAt = null,
    Object? parentId = freezed,
    Object? replyToUserId = freezed,
    Object? replyCount = null,
    Object? sticker = freezed,
    Object? editedAt = freezed,
    Object? likeCount = null,
    Object? likedByMe = null,
    Object? status = null,
  }) {
    return _then(
      _$CommentModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        videoId: null == videoId
            ? _value.videoId
            : videoId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        parentId: freezed == parentId
            ? _value.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        replyToUserId: freezed == replyToUserId
            ? _value.replyToUserId
            : replyToUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        replyCount: null == replyCount
            ? _value.replyCount
            : replyCount // ignore: cast_nullable_to_non_nullable
                  as int,
        sticker: freezed == sticker
            ? _value.sticker
            : sticker // ignore: cast_nullable_to_non_nullable
                  as CommentSticker?,
        editedAt: freezed == editedAt
            ? _value.editedAt
            : editedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        likedByMe: null == likedByMe
            ? _value.likedByMe
            : likedByMe // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as CommentStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentModelImpl extends _CommentModel {
  const _$CommentModelImpl({
    @JsonKey(name: 'commentId', fromJson: _idFromJson) required this.id,
    @JsonKey(fromJson: _idFromJson) required this.videoId,
    @JsonKey(fromJson: _idFromJson) required this.userId,
    @JsonKey(name: 'content') this.text = '',
    required this.createdAt,
    @JsonKey(fromJson: _idOrNullFromJson) this.parentId,
    @JsonKey(fromJson: _idOrNullFromJson) this.replyToUserId,
    this.replyCount = 0,
    this.sticker,
    this.editedAt,
    this.likeCount = 0,
    this.likedByMe = false,
    @JsonKey(unknownEnumValue: CommentStatus.unknown)
    this.status = CommentStatus.visible,
  }) : super._();

  factory _$CommentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentModelImplFromJson(json);

  @override
  @JsonKey(name: 'commentId', fromJson: _idFromJson)
  final String id;
  @override
  @JsonKey(fromJson: _idFromJson)
  final String videoId;
  @override
  @JsonKey(fromJson: _idFromJson)
  final String userId;

  /// Empty for a sticker-only comment.
  @override
  @JsonKey(name: 'content')
  final String text;
  @override
  final DateTime createdAt;

  /// Null for a top-level comment; the top-level comment's id for a reply
  /// (the thread is one level deep — the server flattens deeper replies).
  @override
  @JsonKey(fromJson: _idOrNullFromJson)
  final String? parentId;

  /// Set only on a reply to another reply: whom it answers, for "A > B".
  @override
  @JsonKey(fromJson: _idOrNullFromJson)
  final String? replyToUserId;

  /// Live replies under a top-level comment. Always 0 on a reply.
  @override
  @JsonKey()
  final int replyCount;
  @override
  final CommentSticker? sticker;

  /// Set once the author has edited the text.
  @override
  final DateTime? editedAt;

  /// Denormalised tally kept by interaction-service.
  @override
  @JsonKey()
  final int likeCount;

  /// Always false on an anonymous listing — a guest has no hearts to fill.
  @override
  @JsonKey()
  final bool likedByMe;

  /// Absent on rows written before moderation existed, which are visible.
  @override
  @JsonKey(unknownEnumValue: CommentStatus.unknown)
  final CommentStatus status;

  @override
  String toString() {
    return 'CommentModel(id: $id, videoId: $videoId, userId: $userId, text: $text, createdAt: $createdAt, parentId: $parentId, replyToUserId: $replyToUserId, replyCount: $replyCount, sticker: $sticker, editedAt: $editedAt, likeCount: $likeCount, likedByMe: $likedByMe, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.replyToUserId, replyToUserId) ||
                other.replyToUserId == replyToUserId) &&
            (identical(other.replyCount, replyCount) ||
                other.replyCount == replyCount) &&
            (identical(other.sticker, sticker) || other.sticker == sticker) &&
            (identical(other.editedAt, editedAt) ||
                other.editedAt == editedAt) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.likedByMe, likedByMe) ||
                other.likedByMe == likedByMe) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    videoId,
    userId,
    text,
    createdAt,
    parentId,
    replyToUserId,
    replyCount,
    sticker,
    editedAt,
    likeCount,
    likedByMe,
    status,
  );

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentModelImplCopyWith<_$CommentModelImpl> get copyWith =>
      __$$CommentModelImplCopyWithImpl<_$CommentModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentModelImplToJson(this);
  }
}

abstract class _CommentModel extends CommentModel {
  const factory _CommentModel({
    @JsonKey(name: 'commentId', fromJson: _idFromJson) required final String id,
    @JsonKey(fromJson: _idFromJson) required final String videoId,
    @JsonKey(fromJson: _idFromJson) required final String userId,
    @JsonKey(name: 'content') final String text,
    required final DateTime createdAt,
    @JsonKey(fromJson: _idOrNullFromJson) final String? parentId,
    @JsonKey(fromJson: _idOrNullFromJson) final String? replyToUserId,
    final int replyCount,
    final CommentSticker? sticker,
    final DateTime? editedAt,
    final int likeCount,
    final bool likedByMe,
    @JsonKey(unknownEnumValue: CommentStatus.unknown)
    final CommentStatus status,
  }) = _$CommentModelImpl;
  const _CommentModel._() : super._();

  factory _CommentModel.fromJson(Map<String, dynamic> json) =
      _$CommentModelImpl.fromJson;

  @override
  @JsonKey(name: 'commentId', fromJson: _idFromJson)
  String get id;
  @override
  @JsonKey(fromJson: _idFromJson)
  String get videoId;
  @override
  @JsonKey(fromJson: _idFromJson)
  String get userId;

  /// Empty for a sticker-only comment.
  @override
  @JsonKey(name: 'content')
  String get text;
  @override
  DateTime get createdAt;

  /// Null for a top-level comment; the top-level comment's id for a reply
  /// (the thread is one level deep — the server flattens deeper replies).
  @override
  @JsonKey(fromJson: _idOrNullFromJson)
  String? get parentId;

  /// Set only on a reply to another reply: whom it answers, for "A > B".
  @override
  @JsonKey(fromJson: _idOrNullFromJson)
  String? get replyToUserId;

  /// Live replies under a top-level comment. Always 0 on a reply.
  @override
  int get replyCount;
  @override
  CommentSticker? get sticker;

  /// Set once the author has edited the text.
  @override
  DateTime? get editedAt;

  /// Denormalised tally kept by interaction-service.
  @override
  int get likeCount;

  /// Always false on an anonymous listing — a guest has no hearts to fill.
  @override
  bool get likedByMe;

  /// Absent on rows written before moderation existed, which are visible.
  @override
  @JsonKey(unknownEnumValue: CommentStatus.unknown)
  CommentStatus get status;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentModelImplCopyWith<_$CommentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
