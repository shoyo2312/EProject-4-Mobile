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
    required String email,
    @JsonKey(unknownEnumValue: UserRole.unknown) required UserRole role,
    @JsonKey(unknownEnumValue: UserStatus.unknown) required UserStatus status,
    required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
