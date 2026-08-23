// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProfileState {
  UserProfileModel get profile => throw _privateConstructorUsedError;
  bool? get isFollowing => throw _privateConstructorUsedError;
  bool? get isBlocked => throw _privateConstructorUsedError;
  bool? get isMuted => throw _privateConstructorUsedError;

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileStateCopyWith<ProfileState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileStateCopyWith<$Res> {
  factory $ProfileStateCopyWith(
    ProfileState value,
    $Res Function(ProfileState) then,
  ) = _$ProfileStateCopyWithImpl<$Res, ProfileState>;
  @useResult
  $Res call({
    UserProfileModel profile,
    bool? isFollowing,
    bool? isBlocked,
    bool? isMuted,
  });

  $UserProfileModelCopyWith<$Res> get profile;
}

/// @nodoc
class _$ProfileStateCopyWithImpl<$Res, $Val extends ProfileState>
    implements $ProfileStateCopyWith<$Res> {
  _$ProfileStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profile = null,
    Object? isFollowing = freezed,
    Object? isBlocked = freezed,
    Object? isMuted = freezed,
  }) {
    return _then(
      _value.copyWith(
            profile: null == profile
                ? _value.profile
                : profile // ignore: cast_nullable_to_non_nullable
                      as UserProfileModel,
            isFollowing: freezed == isFollowing
                ? _value.isFollowing
                : isFollowing // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isBlocked: freezed == isBlocked
                ? _value.isBlocked
                : isBlocked // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isMuted: freezed == isMuted
                ? _value.isMuted
                : isMuted // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserProfileModelCopyWith<$Res> get profile {
    return $UserProfileModelCopyWith<$Res>(_value.profile, (value) {
      return _then(_value.copyWith(profile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProfileStateImplCopyWith<$Res>
    implements $ProfileStateCopyWith<$Res> {
  factory _$$ProfileStateImplCopyWith(
    _$ProfileStateImpl value,
    $Res Function(_$ProfileStateImpl) then,
  ) = __$$ProfileStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    UserProfileModel profile,
    bool? isFollowing,
    bool? isBlocked,
    bool? isMuted,
  });

  @override
  $UserProfileModelCopyWith<$Res> get profile;
}

/// @nodoc
class __$$ProfileStateImplCopyWithImpl<$Res>
    extends _$ProfileStateCopyWithImpl<$Res, _$ProfileStateImpl>
    implements _$$ProfileStateImplCopyWith<$Res> {
  __$$ProfileStateImplCopyWithImpl(
    _$ProfileStateImpl _value,
    $Res Function(_$ProfileStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profile = null,
    Object? isFollowing = freezed,
    Object? isBlocked = freezed,
    Object? isMuted = freezed,
  }) {
    return _then(
      _$ProfileStateImpl(
        profile: null == profile
            ? _value.profile
            : profile // ignore: cast_nullable_to_non_nullable
                  as UserProfileModel,
        isFollowing: freezed == isFollowing
            ? _value.isFollowing
            : isFollowing // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isBlocked: freezed == isBlocked
            ? _value.isBlocked
            : isBlocked // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isMuted: freezed == isMuted
            ? _value.isMuted
            : isMuted // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc

class _$ProfileStateImpl implements _ProfileState {
  const _$ProfileStateImpl({
    required this.profile,
    this.isFollowing,
    this.isBlocked,
    this.isMuted,
  });

  @override
  final UserProfileModel profile;
  @override
  final bool? isFollowing;
  @override
  final bool? isBlocked;
  @override
  final bool? isMuted;

  @override
  String toString() {
    return 'ProfileState(profile: $profile, isFollowing: $isFollowing, isBlocked: $isBlocked, isMuted: $isMuted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileStateImpl &&
            (identical(other.profile, profile) || other.profile == profile) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.isBlocked, isBlocked) ||
                other.isBlocked == isBlocked) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, profile, isFollowing, isBlocked, isMuted);

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileStateImplCopyWith<_$ProfileStateImpl> get copyWith =>
      __$$ProfileStateImplCopyWithImpl<_$ProfileStateImpl>(this, _$identity);
}

abstract class _ProfileState implements ProfileState {
  const factory _ProfileState({
    required final UserProfileModel profile,
    final bool? isFollowing,
    final bool? isBlocked,
    final bool? isMuted,
  }) = _$ProfileStateImpl;

  @override
  UserProfileModel get profile;
  @override
  bool? get isFollowing;
  @override
  bool? get isBlocked;
  @override
  bool? get isMuted;

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileStateImplCopyWith<_$ProfileStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
