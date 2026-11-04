// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) {
  return _SessionModel.fromJson(json);
}

/// @nodoc
mixin _$SessionModel {
  @JsonKey(fromJson: _idFromJson)
  String get id => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: DeviceType.unknown)
  DeviceType get deviceType => throw _privateConstructorUsedError; // "Chrome on Windows 11", "Nowa app on Android 14 · Samsung SM-A525F"
  String? get deviceLabel => throw _privateConstructorUsedError;
  String? get deviceModel => throw _privateConstructorUsedError;
  String? get ipAddress =>
      throw _privateConstructorUsedError; // "Bien Hoa, Dong Nai, Vietnam" — approximate, from the sign-in address
  String? get location => throw _privateConstructorUsedError;
  DateTime get signedInAt => throw _privateConstructorUsedError;
  DateTime get lastActiveAt => throw _privateConstructorUsedError;
  bool get current => throw _privateConstructorUsedError;

  /// Serializes this SessionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionModelCopyWith<SessionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionModelCopyWith<$Res> {
  factory $SessionModelCopyWith(
    SessionModel value,
    $Res Function(SessionModel) then,
  ) = _$SessionModelCopyWithImpl<$Res, SessionModel>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String id,
    @JsonKey(unknownEnumValue: DeviceType.unknown) DeviceType deviceType,
    String? deviceLabel,
    String? deviceModel,
    String? ipAddress,
    String? location,
    DateTime signedInAt,
    DateTime lastActiveAt,
    bool current,
  });
}

/// @nodoc
class _$SessionModelCopyWithImpl<$Res, $Val extends SessionModel>
    implements $SessionModelCopyWith<$Res> {
  _$SessionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceType = null,
    Object? deviceLabel = freezed,
    Object? deviceModel = freezed,
    Object? ipAddress = freezed,
    Object? location = freezed,
    Object? signedInAt = null,
    Object? lastActiveAt = null,
    Object? current = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceType: null == deviceType
                ? _value.deviceType
                : deviceType // ignore: cast_nullable_to_non_nullable
                      as DeviceType,
            deviceLabel: freezed == deviceLabel
                ? _value.deviceLabel
                : deviceLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceModel: freezed == deviceModel
                ? _value.deviceModel
                : deviceModel // ignore: cast_nullable_to_non_nullable
                      as String?,
            ipAddress: freezed == ipAddress
                ? _value.ipAddress
                : ipAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
            signedInAt: null == signedInAt
                ? _value.signedInAt
                : signedInAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            lastActiveAt: null == lastActiveAt
                ? _value.lastActiveAt
                : lastActiveAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            current: null == current
                ? _value.current
                : current // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SessionModelImplCopyWith<$Res>
    implements $SessionModelCopyWith<$Res> {
  factory _$$SessionModelImplCopyWith(
    _$SessionModelImpl value,
    $Res Function(_$SessionModelImpl) then,
  ) = __$$SessionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _idFromJson) String id,
    @JsonKey(unknownEnumValue: DeviceType.unknown) DeviceType deviceType,
    String? deviceLabel,
    String? deviceModel,
    String? ipAddress,
    String? location,
    DateTime signedInAt,
    DateTime lastActiveAt,
    bool current,
  });
}

/// @nodoc
class __$$SessionModelImplCopyWithImpl<$Res>
    extends _$SessionModelCopyWithImpl<$Res, _$SessionModelImpl>
    implements _$$SessionModelImplCopyWith<$Res> {
  __$$SessionModelImplCopyWithImpl(
    _$SessionModelImpl _value,
    $Res Function(_$SessionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceType = null,
    Object? deviceLabel = freezed,
    Object? deviceModel = freezed,
    Object? ipAddress = freezed,
    Object? location = freezed,
    Object? signedInAt = null,
    Object? lastActiveAt = null,
    Object? current = null,
  }) {
    return _then(
      _$SessionModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceType: null == deviceType
            ? _value.deviceType
            : deviceType // ignore: cast_nullable_to_non_nullable
                  as DeviceType,
        deviceLabel: freezed == deviceLabel
            ? _value.deviceLabel
            : deviceLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceModel: freezed == deviceModel
            ? _value.deviceModel
            : deviceModel // ignore: cast_nullable_to_non_nullable
                  as String?,
        ipAddress: freezed == ipAddress
            ? _value.ipAddress
            : ipAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
        signedInAt: null == signedInAt
            ? _value.signedInAt
            : signedInAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        lastActiveAt: null == lastActiveAt
            ? _value.lastActiveAt
            : lastActiveAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        current: null == current
            ? _value.current
            : current // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionModelImpl implements _SessionModel {
  const _$SessionModelImpl({
    @JsonKey(fromJson: _idFromJson) required this.id,
    @JsonKey(unknownEnumValue: DeviceType.unknown)
    this.deviceType = DeviceType.unknown,
    this.deviceLabel,
    this.deviceModel,
    this.ipAddress,
    this.location,
    required this.signedInAt,
    required this.lastActiveAt,
    this.current = false,
  });

  factory _$SessionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionModelImplFromJson(json);

  @override
  @JsonKey(fromJson: _idFromJson)
  final String id;
  @override
  @JsonKey(unknownEnumValue: DeviceType.unknown)
  final DeviceType deviceType;
  // "Chrome on Windows 11", "Nowa app on Android 14 · Samsung SM-A525F"
  @override
  final String? deviceLabel;
  @override
  final String? deviceModel;
  @override
  final String? ipAddress;
  // "Bien Hoa, Dong Nai, Vietnam" — approximate, from the sign-in address
  @override
  final String? location;
  @override
  final DateTime signedInAt;
  @override
  final DateTime lastActiveAt;
  @override
  @JsonKey()
  final bool current;

  @override
  String toString() {
    return 'SessionModel(id: $id, deviceType: $deviceType, deviceLabel: $deviceLabel, deviceModel: $deviceModel, ipAddress: $ipAddress, location: $location, signedInAt: $signedInAt, lastActiveAt: $lastActiveAt, current: $current)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceType, deviceType) ||
                other.deviceType == deviceType) &&
            (identical(other.deviceLabel, deviceLabel) ||
                other.deviceLabel == deviceLabel) &&
            (identical(other.deviceModel, deviceModel) ||
                other.deviceModel == deviceModel) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.signedInAt, signedInAt) ||
                other.signedInAt == signedInAt) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt) &&
            (identical(other.current, current) || other.current == current));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    deviceType,
    deviceLabel,
    deviceModel,
    ipAddress,
    location,
    signedInAt,
    lastActiveAt,
    current,
  );

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionModelImplCopyWith<_$SessionModelImpl> get copyWith =>
      __$$SessionModelImplCopyWithImpl<_$SessionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionModelImplToJson(this);
  }
}

abstract class _SessionModel implements SessionModel {
  const factory _SessionModel({
    @JsonKey(fromJson: _idFromJson) required final String id,
    @JsonKey(unknownEnumValue: DeviceType.unknown) final DeviceType deviceType,
    final String? deviceLabel,
    final String? deviceModel,
    final String? ipAddress,
    final String? location,
    required final DateTime signedInAt,
    required final DateTime lastActiveAt,
    final bool current,
  }) = _$SessionModelImpl;

  factory _SessionModel.fromJson(Map<String, dynamic> json) =
      _$SessionModelImpl.fromJson;

  @override
  @JsonKey(fromJson: _idFromJson)
  String get id;
  @override
  @JsonKey(unknownEnumValue: DeviceType.unknown)
  DeviceType get deviceType; // "Chrome on Windows 11", "Nowa app on Android 14 · Samsung SM-A525F"
  @override
  String? get deviceLabel;
  @override
  String? get deviceModel;
  @override
  String? get ipAddress; // "Bien Hoa, Dong Nai, Vietnam" — approximate, from the sign-in address
  @override
  String? get location;
  @override
  DateTime get signedInAt;
  @override
  DateTime get lastActiveAt;
  @override
  bool get current;

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionModelImplCopyWith<_$SessionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
