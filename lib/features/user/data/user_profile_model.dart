import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

// Snowflake ID arrives as a JSON number; keep it as String on the Dart side
// so it never gets round-tripped through a double and loses precision.
String _idFromJson(Object? value) => value.toString();

@freezed
class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    @JsonKey(fromJson: _idFromJson) required String userId,
    required String displayName,
    String? bio,
    String? avatarUrl,
    required int followerCount,
    required int followingCount,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}
