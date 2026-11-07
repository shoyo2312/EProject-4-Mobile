// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Friendship _$FriendshipFromJson(Map<String, dynamic> json) {
  return _Friendship.fromJson(json);
}

/// @nodoc
mixin _$Friendship {
  @JsonKey(fromJson: _idFromJson)
  String get userId => throw _privateConstructorUsedError;
  bool get friends => throw _privateConstructorUsedError;
  bool get following => throw _privateConstructorUsedError;
  bool get requested => throw _privateConstructorUsedError;
  bool get privateAccount => throw _privateConstructorUsedError;

  /// Serializes this Friendship to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendshipCopyWith<Friendship> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendshipCopyWith<$Res> {
  factory $FriendshipCopyWith(
    Friendship value,
    $Res Function(Friendship) then,
  ) = _$FriendshipCopyWithImpl<$Res, Friendship>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String userId,
    bool friends,
    bool following,
    bool requested,
    bool privateAccount,
  });
}

/// @nodoc
class _$FriendshipCopyWithImpl<$Res, $Val extends Friendship>
    implements $FriendshipCopyWith<$Res> {
  _$FriendshipCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? friends = null,
    Object? following = null,
    Object? requested = null,
    Object? privateAccount = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            friends: null == friends
                ? _value.friends
                : friends // ignore: cast_nullable_to_non_nullable
                      as bool,
            following: null == following
                ? _value.following
                : following // ignore: cast_nullable_to_non_nullable
                      as bool,
            requested: null == requested
                ? _value.requested
                : requested // ignore: cast_nullable_to_non_nullable
                      as bool,
            privateAccount: null == privateAccount
                ? _value.privateAccount
                : privateAccount // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FriendshipImplCopyWith<$Res>
    implements $FriendshipCopyWith<$Res> {
  factory _$$FriendshipImplCopyWith(
    _$FriendshipImpl value,
    $Res Function(_$FriendshipImpl) then,
  ) = __$$FriendshipImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String userId,
    bool friends,
    bool following,
    bool requested,
    bool privateAccount,
  });
}

/// @nodoc
class __$$FriendshipImplCopyWithImpl<$Res>
    extends _$FriendshipCopyWithImpl<$Res, _$FriendshipImpl>
    implements _$$FriendshipImplCopyWith<$Res> {
  __$$FriendshipImplCopyWithImpl(
    _$FriendshipImpl _value,
    $Res Function(_$FriendshipImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? friends = null,
    Object? following = null,
    Object? requested = null,
    Object? privateAccount = null,
  }) {
    return _then(
      _$FriendshipImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        friends: null == friends
            ? _value.friends
            : friends // ignore: cast_nullable_to_non_nullable
                  as bool,
        following: null == following
            ? _value.following
            : following // ignore: cast_nullable_to_non_nullable
                  as bool,
        requested: null == requested
            ? _value.requested
            : requested // ignore: cast_nullable_to_non_nullable
                  as bool,
        privateAccount: null == privateAccount
            ? _value.privateAccount
            : privateAccount // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FriendshipImpl implements _Friendship {
  const _$FriendshipImpl({
    @JsonKey(fromJson: _idFromJson) required this.userId,
    this.friends = false,
    this.following = false,
    this.requested = false,
    this.privateAccount = false,
  });

  factory _$FriendshipImpl.fromJson(Map<String, dynamic> json) =>
      _$$FriendshipImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String userId;
  @override
  @JsonKey()
  final bool friends;
  @override
  @JsonKey()
  final bool following;
  @override
  @JsonKey()
  final bool requested;
  @override
  @JsonKey()
  final bool privateAccount;

  @override
  String toString() {
    return 'Friendship(userId: $userId, friends: $friends, following: $following, requested: $requested, privateAccount: $privateAccount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendshipImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.friends, friends) || other.friends == friends) &&
            (identical(other.following, following) ||
                other.following == following) &&
            (identical(other.requested, requested) ||
                other.requested == requested) &&
            (identical(other.privateAccount, privateAccount) ||
                other.privateAccount == privateAccount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    friends,
    following,
    requested,
    privateAccount,
  );

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendshipImplCopyWith<_$FriendshipImpl> get copyWith =>
      __$$FriendshipImplCopyWithImpl<_$FriendshipImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FriendshipImplToJson(this);
  }
}

abstract class _Friendship implements Friendship {
  const factory _Friendship({
    @JsonKey(fromJson: _idFromJson) required final String userId,
    final bool friends,
    final bool following,
    final bool requested,
    final bool privateAccount,
  }) = _$FriendshipImpl;

  factory _Friendship.fromJson(Map<String, dynamic> json) =
      _$FriendshipImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get userId;
  @override
  bool get friends;
  @override
  bool get following;
  @override
  bool get requested;
  @override
  bool get privateAccount;

  /// Create a copy of Friendship
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendshipImplCopyWith<_$FriendshipImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
