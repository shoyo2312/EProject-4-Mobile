// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileModelImpl _$$UserProfileModelImplFromJson(
  Map<String, dynamic> json,
) => _$UserProfileModelImpl(
  userId: _idFromJson(json['userId']),
  displayName: json['displayName'] as String,
  bio: json['bio'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  followerCount: (json['followerCount'] as num).toInt(),
  followingCount: (json['followingCount'] as num).toInt(),
);

Map<String, dynamic> _$$UserProfileModelImplToJson(
  _$UserProfileModelImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'displayName': instance.displayName,
  'bio': instance.bio,
  'avatarUrl': instance.avatarUrl,
  'followerCount': instance.followerCount,
  'followingCount': instance.followingCount,
};
