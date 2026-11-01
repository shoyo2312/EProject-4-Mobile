// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ConversationModel _$ConversationModelFromJson(Map<String, dynamic> json) {
  return _ConversationModel.fromJson(json);
}

/// @nodoc
mixin _$ConversationModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _idsFromJson)
  List<String> get participantIds => throw _privateConstructorUsedError;
  String? get lastMessageContent => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _nullableIdFromJson)
  String? get lastMessageSenderId => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  bool get hasUnread => throw _privateConstructorUsedError;

  /// Serializes this ConversationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationModelCopyWith<ConversationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationModelCopyWith<$Res> {
  factory $ConversationModelCopyWith(
    ConversationModel value,
    $Res Function(ConversationModel) then,
  ) = _$ConversationModelCopyWithImpl<$Res, ConversationModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(fromJson: _idsFromJson) List<String> participantIds,
    String? lastMessageContent,
    @JsonKey(fromJson: _nullableIdFromJson) String? lastMessageSenderId,
    DateTime? lastMessageAt,
    DateTime createdAt,
    bool hasUnread,
  });
}

/// @nodoc
class _$ConversationModelCopyWithImpl<$Res, $Val extends ConversationModel>
    implements $ConversationModelCopyWith<$Res> {
  _$ConversationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participantIds = null,
    Object? lastMessageContent = freezed,
    Object? lastMessageSenderId = freezed,
    Object? lastMessageAt = freezed,
    Object? createdAt = null,
    Object? hasUnread = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            participantIds: null == participantIds
                ? _value.participantIds
                : participantIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            lastMessageContent: freezed == lastMessageContent
                ? _value.lastMessageContent
                : lastMessageContent // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastMessageSenderId: freezed == lastMessageSenderId
                ? _value.lastMessageSenderId
                : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastMessageAt: freezed == lastMessageAt
                ? _value.lastMessageAt
                : lastMessageAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            hasUnread: null == hasUnread
                ? _value.hasUnread
                : hasUnread // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConversationModelImplCopyWith<$Res>
    implements $ConversationModelCopyWith<$Res> {
  factory _$$ConversationModelImplCopyWith(
    _$ConversationModelImpl value,
    $Res Function(_$ConversationModelImpl) then,
  ) = __$$ConversationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(fromJson: _idsFromJson) List<String> participantIds,
    String? lastMessageContent,
    @JsonKey(fromJson: _nullableIdFromJson) String? lastMessageSenderId,
    DateTime? lastMessageAt,
    DateTime createdAt,
    bool hasUnread,
  });
}

/// @nodoc
class __$$ConversationModelImplCopyWithImpl<$Res>
    extends _$ConversationModelCopyWithImpl<$Res, _$ConversationModelImpl>
    implements _$$ConversationModelImplCopyWith<$Res> {
  __$$ConversationModelImplCopyWithImpl(
    _$ConversationModelImpl _value,
    $Res Function(_$ConversationModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participantIds = null,
    Object? lastMessageContent = freezed,
    Object? lastMessageSenderId = freezed,
    Object? lastMessageAt = freezed,
    Object? createdAt = null,
    Object? hasUnread = null,
  }) {
    return _then(
      _$ConversationModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        participantIds: null == participantIds
            ? _value._participantIds
            : participantIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        lastMessageContent: freezed == lastMessageContent
            ? _value.lastMessageContent
            : lastMessageContent // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastMessageSenderId: freezed == lastMessageSenderId
            ? _value.lastMessageSenderId
            : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastMessageAt: freezed == lastMessageAt
            ? _value.lastMessageAt
            : lastMessageAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        hasUnread: null == hasUnread
            ? _value.hasUnread
            : hasUnread // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationModelImpl extends _ConversationModel {
  const _$ConversationModelImpl({
    required this.id,
    @JsonKey(fromJson: _idsFromJson) required final List<String> participantIds,
    this.lastMessageContent,
    @JsonKey(fromJson: _nullableIdFromJson) this.lastMessageSenderId,
    this.lastMessageAt,
    required this.createdAt,
    this.hasUnread = false,
  }) : _participantIds = participantIds,
       super._();

  factory _$ConversationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationModelImplFromJson(json);

  @override
  final String id;
  final List<String> _participantIds;
  @override
  @JsonKey(fromJson: _idsFromJson)
  List<String> get participantIds {
    if (_participantIds is EqualUnmodifiableListView) return _participantIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participantIds);
  }

  @override
  final String? lastMessageContent;
  @override
  @JsonKey(fromJson: _nullableIdFromJson)
  final String? lastMessageSenderId;
  @override
  final DateTime? lastMessageAt;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final bool hasUnread;

  @override
  String toString() {
    return 'ConversationModel(id: $id, participantIds: $participantIds, lastMessageContent: $lastMessageContent, lastMessageSenderId: $lastMessageSenderId, lastMessageAt: $lastMessageAt, createdAt: $createdAt, hasUnread: $hasUnread)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(
              other._participantIds,
              _participantIds,
            ) &&
            (identical(other.lastMessageContent, lastMessageContent) ||
                other.lastMessageContent == lastMessageContent) &&
            (identical(other.lastMessageSenderId, lastMessageSenderId) ||
                other.lastMessageSenderId == lastMessageSenderId) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.hasUnread, hasUnread) ||
                other.hasUnread == hasUnread));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(_participantIds),
    lastMessageContent,
    lastMessageSenderId,
    lastMessageAt,
    createdAt,
    hasUnread,
  );

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationModelImplCopyWith<_$ConversationModelImpl> get copyWith =>
      __$$ConversationModelImplCopyWithImpl<_$ConversationModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationModelImplToJson(this);
  }
}

abstract class _ConversationModel extends ConversationModel {
  const factory _ConversationModel({
    required final String id,
    @JsonKey(fromJson: _idsFromJson) required final List<String> participantIds,
    final String? lastMessageContent,
    @JsonKey(fromJson: _nullableIdFromJson) final String? lastMessageSenderId,
    final DateTime? lastMessageAt,
    required final DateTime createdAt,
    final bool hasUnread,
  }) = _$ConversationModelImpl;
  const _ConversationModel._() : super._();

  factory _ConversationModel.fromJson(Map<String, dynamic> json) =
      _$ConversationModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(fromJson: _idsFromJson)
  List<String> get participantIds;
  @override
  String? get lastMessageContent;
  @override
  @JsonKey(fromJson: _nullableIdFromJson)
  String? get lastMessageSenderId;
  @override
  DateTime? get lastMessageAt;
  @override
  DateTime get createdAt;
  @override
  bool get hasUnread;

  /// Create a copy of ConversationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationModelImplCopyWith<_$ConversationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StickerModel _$StickerModelFromJson(Map<String, dynamic> json) {
  return _StickerModel.fromJson(json);
}

/// @nodoc
mixin _$StickerModel {
  String get stickerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;

  /// Serializes this StickerModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StickerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StickerModelCopyWith<StickerModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StickerModelCopyWith<$Res> {
  factory $StickerModelCopyWith(
    StickerModel value,
    $Res Function(StickerModel) then,
  ) = _$StickerModelCopyWithImpl<$Res, StickerModel>;
  @useResult
  $Res call({String stickerId, String name, String url, int width, int height});
}

/// @nodoc
class _$StickerModelCopyWithImpl<$Res, $Val extends StickerModel>
    implements $StickerModelCopyWith<$Res> {
  _$StickerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StickerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stickerId = null,
    Object? name = null,
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
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
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
abstract class _$$StickerModelImplCopyWith<$Res>
    implements $StickerModelCopyWith<$Res> {
  factory _$$StickerModelImplCopyWith(
    _$StickerModelImpl value,
    $Res Function(_$StickerModelImpl) then,
  ) = __$$StickerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String stickerId, String name, String url, int width, int height});
}

/// @nodoc
class __$$StickerModelImplCopyWithImpl<$Res>
    extends _$StickerModelCopyWithImpl<$Res, _$StickerModelImpl>
    implements _$$StickerModelImplCopyWith<$Res> {
  __$$StickerModelImplCopyWithImpl(
    _$StickerModelImpl _value,
    $Res Function(_$StickerModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StickerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stickerId = null,
    Object? name = null,
    Object? url = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(
      _$StickerModelImpl(
        stickerId: null == stickerId
            ? _value.stickerId
            : stickerId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
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
class _$StickerModelImpl implements _StickerModel {
  const _$StickerModelImpl({
    required this.stickerId,
    required this.name,
    required this.url,
    this.width = 0,
    this.height = 0,
  });

  factory _$StickerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StickerModelImplFromJson(json);

  @override
  final String stickerId;
  @override
  final String name;
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
    return 'StickerModel(stickerId: $stickerId, name: $name, url: $url, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StickerModelImpl &&
            (identical(other.stickerId, stickerId) ||
                other.stickerId == stickerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, stickerId, name, url, width, height);

  /// Create a copy of StickerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StickerModelImplCopyWith<_$StickerModelImpl> get copyWith =>
      __$$StickerModelImplCopyWithImpl<_$StickerModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StickerModelImplToJson(this);
  }
}

abstract class _StickerModel implements StickerModel {
  const factory _StickerModel({
    required final String stickerId,
    required final String name,
    required final String url,
    final int width,
    final int height,
  }) = _$StickerModelImpl;

  factory _StickerModel.fromJson(Map<String, dynamic> json) =
      _$StickerModelImpl.fromJson;

  @override
  String get stickerId;
  @override
  String get name;
  @override
  String get url;
  @override
  int get width;
  @override
  int get height;

  /// Create a copy of StickerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StickerModelImplCopyWith<_$StickerModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StickerPack _$StickerPackFromJson(Map<String, dynamic> json) {
  return _StickerPack.fromJson(json);
}

/// @nodoc
mixin _$StickerPack {
  String get packId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<StickerModel> get stickers => throw _privateConstructorUsedError;

  /// Serializes this StickerPack to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StickerPack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StickerPackCopyWith<StickerPack> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StickerPackCopyWith<$Res> {
  factory $StickerPackCopyWith(
    StickerPack value,
    $Res Function(StickerPack) then,
  ) = _$StickerPackCopyWithImpl<$Res, StickerPack>;
  @useResult
  $Res call({String packId, String name, List<StickerModel> stickers});
}

/// @nodoc
class _$StickerPackCopyWithImpl<$Res, $Val extends StickerPack>
    implements $StickerPackCopyWith<$Res> {
  _$StickerPackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StickerPack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? packId = null,
    Object? name = null,
    Object? stickers = null,
  }) {
    return _then(
      _value.copyWith(
            packId: null == packId
                ? _value.packId
                : packId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            stickers: null == stickers
                ? _value.stickers
                : stickers // ignore: cast_nullable_to_non_nullable
                      as List<StickerModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StickerPackImplCopyWith<$Res>
    implements $StickerPackCopyWith<$Res> {
  factory _$$StickerPackImplCopyWith(
    _$StickerPackImpl value,
    $Res Function(_$StickerPackImpl) then,
  ) = __$$StickerPackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String packId, String name, List<StickerModel> stickers});
}

/// @nodoc
class __$$StickerPackImplCopyWithImpl<$Res>
    extends _$StickerPackCopyWithImpl<$Res, _$StickerPackImpl>
    implements _$$StickerPackImplCopyWith<$Res> {
  __$$StickerPackImplCopyWithImpl(
    _$StickerPackImpl _value,
    $Res Function(_$StickerPackImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StickerPack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? packId = null,
    Object? name = null,
    Object? stickers = null,
  }) {
    return _then(
      _$StickerPackImpl(
        packId: null == packId
            ? _value.packId
            : packId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        stickers: null == stickers
            ? _value._stickers
            : stickers // ignore: cast_nullable_to_non_nullable
                  as List<StickerModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StickerPackImpl implements _StickerPack {
  const _$StickerPackImpl({
    required this.packId,
    required this.name,
    final List<StickerModel> stickers = const [],
  }) : _stickers = stickers;

  factory _$StickerPackImpl.fromJson(Map<String, dynamic> json) =>
      _$$StickerPackImplFromJson(json);

  @override
  final String packId;
  @override
  final String name;
  final List<StickerModel> _stickers;
  @override
  @JsonKey()
  List<StickerModel> get stickers {
    if (_stickers is EqualUnmodifiableListView) return _stickers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stickers);
  }

  @override
  String toString() {
    return 'StickerPack(packId: $packId, name: $name, stickers: $stickers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StickerPackImpl &&
            (identical(other.packId, packId) || other.packId == packId) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._stickers, _stickers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    packId,
    name,
    const DeepCollectionEquality().hash(_stickers),
  );

  /// Create a copy of StickerPack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StickerPackImplCopyWith<_$StickerPackImpl> get copyWith =>
      __$$StickerPackImplCopyWithImpl<_$StickerPackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StickerPackImplToJson(this);
  }
}

abstract class _StickerPack implements StickerPack {
  const factory _StickerPack({
    required final String packId,
    required final String name,
    final List<StickerModel> stickers,
  }) = _$StickerPackImpl;

  factory _StickerPack.fromJson(Map<String, dynamic> json) =
      _$StickerPackImpl.fromJson;

  @override
  String get packId;
  @override
  String get name;
  @override
  List<StickerModel> get stickers;

  /// Create a copy of StickerPack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StickerPackImplCopyWith<_$StickerPackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatImageModel _$ChatImageModelFromJson(Map<String, dynamic> json) {
  return _ChatImageModel.fromJson(json);
}

/// @nodoc
mixin _$ChatImageModel {
  String get imageId => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String? get mime => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;

  /// Serializes this ChatImageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatImageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatImageModelCopyWith<ChatImageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatImageModelCopyWith<$Res> {
  factory $ChatImageModelCopyWith(
    ChatImageModel value,
    $Res Function(ChatImageModel) then,
  ) = _$ChatImageModelCopyWithImpl<$Res, ChatImageModel>;
  @useResult
  $Res call({
    String imageId,
    String url,
    String? mime,
    int width,
    int height,
    int size,
  });
}

/// @nodoc
class _$ChatImageModelCopyWithImpl<$Res, $Val extends ChatImageModel>
    implements $ChatImageModelCopyWith<$Res> {
  _$ChatImageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatImageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageId = null,
    Object? url = null,
    Object? mime = freezed,
    Object? width = null,
    Object? height = null,
    Object? size = null,
  }) {
    return _then(
      _value.copyWith(
            imageId: null == imageId
                ? _value.imageId
                : imageId // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            mime: freezed == mime
                ? _value.mime
                : mime // ignore: cast_nullable_to_non_nullable
                      as String?,
            width: null == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                      as int,
            height: null == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as int,
            size: null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatImageModelImplCopyWith<$Res>
    implements $ChatImageModelCopyWith<$Res> {
  factory _$$ChatImageModelImplCopyWith(
    _$ChatImageModelImpl value,
    $Res Function(_$ChatImageModelImpl) then,
  ) = __$$ChatImageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String imageId,
    String url,
    String? mime,
    int width,
    int height,
    int size,
  });
}

/// @nodoc
class __$$ChatImageModelImplCopyWithImpl<$Res>
    extends _$ChatImageModelCopyWithImpl<$Res, _$ChatImageModelImpl>
    implements _$$ChatImageModelImplCopyWith<$Res> {
  __$$ChatImageModelImplCopyWithImpl(
    _$ChatImageModelImpl _value,
    $Res Function(_$ChatImageModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatImageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageId = null,
    Object? url = null,
    Object? mime = freezed,
    Object? width = null,
    Object? height = null,
    Object? size = null,
  }) {
    return _then(
      _$ChatImageModelImpl(
        imageId: null == imageId
            ? _value.imageId
            : imageId // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        mime: freezed == mime
            ? _value.mime
            : mime // ignore: cast_nullable_to_non_nullable
                  as String?,
        width: null == width
            ? _value.width
            : width // ignore: cast_nullable_to_non_nullable
                  as int,
        height: null == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as int,
        size: null == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatImageModelImpl implements _ChatImageModel {
  const _$ChatImageModelImpl({
    required this.imageId,
    required this.url,
    this.mime,
    this.width = 0,
    this.height = 0,
    this.size = 0,
  });

  factory _$ChatImageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatImageModelImplFromJson(json);

  @override
  final String imageId;
  @override
  final String url;
  @override
  final String? mime;
  @override
  @JsonKey()
  final int width;
  @override
  @JsonKey()
  final int height;
  @override
  @JsonKey()
  final int size;

  @override
  String toString() {
    return 'ChatImageModel(imageId: $imageId, url: $url, mime: $mime, width: $width, height: $height, size: $size)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatImageModelImpl &&
            (identical(other.imageId, imageId) || other.imageId == imageId) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.mime, mime) || other.mime == mime) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.size, size) || other.size == size));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, imageId, url, mime, width, height, size);

  /// Create a copy of ChatImageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatImageModelImplCopyWith<_$ChatImageModelImpl> get copyWith =>
      __$$ChatImageModelImplCopyWithImpl<_$ChatImageModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatImageModelImplToJson(this);
  }
}

abstract class _ChatImageModel implements ChatImageModel {
  const factory _ChatImageModel({
    required final String imageId,
    required final String url,
    final String? mime,
    final int width,
    final int height,
    final int size,
  }) = _$ChatImageModelImpl;

  factory _ChatImageModel.fromJson(Map<String, dynamic> json) =
      _$ChatImageModelImpl.fromJson;

  @override
  String get imageId;
  @override
  String get url;
  @override
  String? get mime;
  @override
  int get width;
  @override
  int get height;
  @override
  int get size;

  /// Create a copy of ChatImageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatImageModelImplCopyWith<_$ChatImageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) {
  return _MessageModel.fromJson(json);
}

/// @nodoc
mixin _$MessageModel {
  String get id => throw _privateConstructorUsedError;
  String get conversationId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _idFromJson)
  String get senderId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime get sentAt => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: MessageType.unknown)
  MessageType get type => throw _privateConstructorUsedError;
  StickerModel? get sticker => throw _privateConstructorUsedError;
  ChatImageModel? get image => throw _privateConstructorUsedError;
  DateTime? get recalledAt => throw _privateConstructorUsedError;

  /// Serializes this MessageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageModelCopyWith<MessageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageModelCopyWith<$Res> {
  factory $MessageModelCopyWith(
    MessageModel value,
    $Res Function(MessageModel) then,
  ) = _$MessageModelCopyWithImpl<$Res, MessageModel>;
  @useResult
  $Res call({
    String id,
    String conversationId,
    @JsonKey(fromJson: _idFromJson) String senderId,
    String content,
    DateTime sentAt,
    @JsonKey(unknownEnumValue: MessageType.unknown) MessageType type,
    StickerModel? sticker,
    ChatImageModel? image,
    DateTime? recalledAt,
  });

  $StickerModelCopyWith<$Res>? get sticker;
  $ChatImageModelCopyWith<$Res>? get image;
}

/// @nodoc
class _$MessageModelCopyWithImpl<$Res, $Val extends MessageModel>
    implements $MessageModelCopyWith<$Res> {
  _$MessageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? content = null,
    Object? sentAt = null,
    Object? type = null,
    Object? sticker = freezed,
    Object? image = freezed,
    Object? recalledAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            conversationId: null == conversationId
                ? _value.conversationId
                : conversationId // ignore: cast_nullable_to_non_nullable
                      as String,
            senderId: null == senderId
                ? _value.senderId
                : senderId // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            sentAt: null == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as MessageType,
            sticker: freezed == sticker
                ? _value.sticker
                : sticker // ignore: cast_nullable_to_non_nullable
                      as StickerModel?,
            image: freezed == image
                ? _value.image
                : image // ignore: cast_nullable_to_non_nullable
                      as ChatImageModel?,
            recalledAt: freezed == recalledAt
                ? _value.recalledAt
                : recalledAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StickerModelCopyWith<$Res>? get sticker {
    if (_value.sticker == null) {
      return null;
    }

    return $StickerModelCopyWith<$Res>(_value.sticker!, (value) {
      return _then(_value.copyWith(sticker: value) as $Val);
    });
  }

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChatImageModelCopyWith<$Res>? get image {
    if (_value.image == null) {
      return null;
    }

    return $ChatImageModelCopyWith<$Res>(_value.image!, (value) {
      return _then(_value.copyWith(image: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageModelImplCopyWith<$Res>
    implements $MessageModelCopyWith<$Res> {
  factory _$$MessageModelImplCopyWith(
    _$MessageModelImpl value,
    $Res Function(_$MessageModelImpl) then,
  ) = __$$MessageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String conversationId,
    @JsonKey(fromJson: _idFromJson) String senderId,
    String content,
    DateTime sentAt,
    @JsonKey(unknownEnumValue: MessageType.unknown) MessageType type,
    StickerModel? sticker,
    ChatImageModel? image,
    DateTime? recalledAt,
  });

  @override
  $StickerModelCopyWith<$Res>? get sticker;
  @override
  $ChatImageModelCopyWith<$Res>? get image;
}

/// @nodoc
class __$$MessageModelImplCopyWithImpl<$Res>
    extends _$MessageModelCopyWithImpl<$Res, _$MessageModelImpl>
    implements _$$MessageModelImplCopyWith<$Res> {
  __$$MessageModelImplCopyWithImpl(
    _$MessageModelImpl _value,
    $Res Function(_$MessageModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? content = null,
    Object? sentAt = null,
    Object? type = null,
    Object? sticker = freezed,
    Object? image = freezed,
    Object? recalledAt = freezed,
  }) {
    return _then(
      _$MessageModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        conversationId: null == conversationId
            ? _value.conversationId
            : conversationId // ignore: cast_nullable_to_non_nullable
                  as String,
        senderId: null == senderId
            ? _value.senderId
            : senderId // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        sentAt: null == sentAt
            ? _value.sentAt
            : sentAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as MessageType,
        sticker: freezed == sticker
            ? _value.sticker
            : sticker // ignore: cast_nullable_to_non_nullable
                  as StickerModel?,
        image: freezed == image
            ? _value.image
            : image // ignore: cast_nullable_to_non_nullable
                  as ChatImageModel?,
        recalledAt: freezed == recalledAt
            ? _value.recalledAt
            : recalledAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageModelImpl extends _MessageModel {
  const _$MessageModelImpl({
    required this.id,
    required this.conversationId,
    @JsonKey(fromJson: _idFromJson) required this.senderId,
    required this.content,
    required this.sentAt,
    @JsonKey(unknownEnumValue: MessageType.unknown)
    this.type = MessageType.text,
    this.sticker,
    this.image,
    this.recalledAt,
  }) : super._();

  factory _$MessageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageModelImplFromJson(json);

  @override
  final String id;
  @override
  final String conversationId;
  @override
  @JsonKey(fromJson: _idFromJson)
  final String senderId;
  @override
  final String content;
  @override
  final DateTime sentAt;
  @override
  @JsonKey(unknownEnumValue: MessageType.unknown)
  final MessageType type;
  @override
  final StickerModel? sticker;
  @override
  final ChatImageModel? image;
  @override
  final DateTime? recalledAt;

  @override
  String toString() {
    return 'MessageModel(id: $id, conversationId: $conversationId, senderId: $senderId, content: $content, sentAt: $sentAt, type: $type, sticker: $sticker, image: $image, recalledAt: $recalledAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sticker, sticker) || other.sticker == sticker) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.recalledAt, recalledAt) ||
                other.recalledAt == recalledAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    conversationId,
    senderId,
    content,
    sentAt,
    type,
    sticker,
    image,
    recalledAt,
  );

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageModelImplCopyWith<_$MessageModelImpl> get copyWith =>
      __$$MessageModelImplCopyWithImpl<_$MessageModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageModelImplToJson(this);
  }
}

abstract class _MessageModel extends MessageModel {
  const factory _MessageModel({
    required final String id,
    required final String conversationId,
    @JsonKey(fromJson: _idFromJson) required final String senderId,
    required final String content,
    required final DateTime sentAt,
    @JsonKey(unknownEnumValue: MessageType.unknown) final MessageType type,
    final StickerModel? sticker,
    final ChatImageModel? image,
    final DateTime? recalledAt,
  }) = _$MessageModelImpl;
  const _MessageModel._() : super._();

  factory _MessageModel.fromJson(Map<String, dynamic> json) =
      _$MessageModelImpl.fromJson;

  @override
  String get id;
  @override
  String get conversationId;
  @override
  @JsonKey(fromJson: _idFromJson)
  String get senderId;
  @override
  String get content;
  @override
  DateTime get sentAt;
  @override
  @JsonKey(unknownEnumValue: MessageType.unknown)
  MessageType get type;
  @override
  StickerModel? get sticker;
  @override
  ChatImageModel? get image;
  @override
  DateTime? get recalledAt;

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageModelImplCopyWith<_$MessageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
