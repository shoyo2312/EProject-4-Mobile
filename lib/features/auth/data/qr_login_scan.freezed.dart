// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_login_scan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

QrLoginScan _$QrLoginScanFromJson(Map<String, dynamic> json) {
  return _QrLoginScan.fromJson(json);
}

/// @nodoc
mixin _$QrLoginScan {
  /// Fixed words like "Chrome on Windows"; null when the browser is unknown.
  String? get deviceLabel => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this QrLoginScan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QrLoginScan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QrLoginScanCopyWith<QrLoginScan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QrLoginScanCopyWith<$Res> {
  factory $QrLoginScanCopyWith(
    QrLoginScan value,
    $Res Function(QrLoginScan) then,
  ) = _$QrLoginScanCopyWithImpl<$Res, QrLoginScan>;
  @useResult
  $Res call({String? deviceLabel, String? location, DateTime expiresAt});
}

/// @nodoc
class _$QrLoginScanCopyWithImpl<$Res, $Val extends QrLoginScan>
    implements $QrLoginScanCopyWith<$Res> {
  _$QrLoginScanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QrLoginScan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceLabel = freezed,
    Object? location = freezed,
    Object? expiresAt = null,
  }) {
    return _then(
      _value.copyWith(
            deviceLabel: freezed == deviceLabel
                ? _value.deviceLabel
                : deviceLabel // ignore: cast_nullable_to_non_nullable
                      as String?,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$QrLoginScanImplCopyWith<$Res>
    implements $QrLoginScanCopyWith<$Res> {
  factory _$$QrLoginScanImplCopyWith(
    _$QrLoginScanImpl value,
    $Res Function(_$QrLoginScanImpl) then,
  ) = __$$QrLoginScanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? deviceLabel, String? location, DateTime expiresAt});
}

/// @nodoc
class __$$QrLoginScanImplCopyWithImpl<$Res>
    extends _$QrLoginScanCopyWithImpl<$Res, _$QrLoginScanImpl>
    implements _$$QrLoginScanImplCopyWith<$Res> {
  __$$QrLoginScanImplCopyWithImpl(
    _$QrLoginScanImpl _value,
    $Res Function(_$QrLoginScanImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QrLoginScan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceLabel = freezed,
    Object? location = freezed,
    Object? expiresAt = null,
  }) {
    return _then(
      _$QrLoginScanImpl(
        deviceLabel: freezed == deviceLabel
            ? _value.deviceLabel
            : deviceLabel // ignore: cast_nullable_to_non_nullable
                  as String?,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$QrLoginScanImpl implements _QrLoginScan {
  const _$QrLoginScanImpl({
    this.deviceLabel,
    this.location,
    required this.expiresAt,
  });

  factory _$QrLoginScanImpl.fromJson(Map<String, dynamic> json) =>
      _$$QrLoginScanImplFromJson(json);

  /// Fixed words like "Chrome on Windows"; null when the browser is unknown.
  @override
  final String? deviceLabel;
  @override
  final String? location;
  @override
  final DateTime expiresAt;

  @override
  String toString() {
    return 'QrLoginScan(deviceLabel: $deviceLabel, location: $location, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QrLoginScanImpl &&
            (identical(other.deviceLabel, deviceLabel) ||
                other.deviceLabel == deviceLabel) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, deviceLabel, location, expiresAt);

  /// Create a copy of QrLoginScan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QrLoginScanImplCopyWith<_$QrLoginScanImpl> get copyWith =>
      __$$QrLoginScanImplCopyWithImpl<_$QrLoginScanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QrLoginScanImplToJson(this);
  }
}

abstract class _QrLoginScan implements QrLoginScan {
  const factory _QrLoginScan({
    final String? deviceLabel,
    final String? location,
    required final DateTime expiresAt,
  }) = _$QrLoginScanImpl;

  factory _QrLoginScan.fromJson(Map<String, dynamic> json) =
      _$QrLoginScanImpl.fromJson;

  /// Fixed words like "Chrome on Windows"; null when the browser is unknown.
  @override
  String? get deviceLabel;
  @override
  String? get location;
  @override
  DateTime get expiresAt;

  /// Create a copy of QrLoginScan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QrLoginScanImplCopyWith<_$QrLoginScanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
