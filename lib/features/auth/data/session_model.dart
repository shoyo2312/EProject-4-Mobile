import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

/// The slot a device takes: an account holds one laptop/PC and one
/// phone/tablet at a time.
enum DeviceType {
  @JsonValue('DESKTOP')
  desktop,
  @JsonValue('MOBILE')
  mobile,
  unknown,
}

// Snowflake ID arrives as a JSON number; keep it as String on the Dart side
String _idFromJson(Object? value) => value.toString();

/// One device signed in to the account (`GET /auth/sessions`).
@freezed
class SessionModel with _$SessionModel {
  const factory SessionModel({
    @JsonKey(fromJson: _idFromJson) required String id,
    @JsonKey(unknownEnumValue: DeviceType.unknown)
    @Default(DeviceType.unknown)
    DeviceType deviceType,
    // "Chrome on Windows 11", "Nowa app on Android 14 · Samsung SM-A525F"
    String? deviceLabel,
    String? deviceModel,
    String? ipAddress,
    // "Bien Hoa, Dong Nai, Vietnam" — approximate, from the sign-in address
    String? location,
    required DateTime signedInAt,
    required DateTime lastActiveAt,
    @Default(false) bool current,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}
