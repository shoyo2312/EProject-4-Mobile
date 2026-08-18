import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum UserRole {
  @JsonValue('USER')
  user,
  @JsonValue('ADMIN')
  admin,
  unknown,
}

enum UserStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('LOCKED')
  locked,
  unknown,
}

// Snowflake ID arrives as a JSON number; keep it as String on the Dart side
// so it never gets round-tripped through a double and loses precision.
String _idFromJson(Object? value) => value.toString();

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    @JsonKey(fromJson: _idFromJson) required String id,
    required String username,
    // Null for accounts created through a social provider that never asserted
    // one — Facebook without the `email` grant. The session works; the client
    // collects an address via /auth/email (see SocialLoginResponse.requiresEmail).
    String? email,
    @JsonKey(unknownEnumValue: UserRole.unknown) required UserRole role,
    @JsonKey(unknownEnumValue: UserStatus.unknown) required UserStatus status,
    // Always false right after /register; /login keeps returning
    // 403 EMAIL_NOT_VERIFIED until the OTP is confirmed (auth doc 3.1/3.2).
    required bool emailVerified,
    required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
