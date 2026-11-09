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
    // When the display name may change again (once every 7 days). Only sent
    // to the owner, and null when it may change now.
    DateTime? displayNameChangeableAt,
    // `yyyy-MM-dd`, only sent to the owner. Null until it is set, and it can
    // be set only once (user doc 3.2).
    DateTime? birthDate,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}
