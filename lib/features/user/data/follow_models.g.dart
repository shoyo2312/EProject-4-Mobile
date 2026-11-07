// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FriendshipImpl _$$FriendshipImplFromJson(Map<String, dynamic> json) =>
    _$FriendshipImpl(
      userId: _idFromJson(json['userId']),
      friends: json['friends'] as bool? ?? false,
      following: json['following'] as bool? ?? false,
      requested: json['requested'] as bool? ?? false,
      privateAccount: json['privateAccount'] as bool? ?? false,
    );

Map<String, dynamic> _$$FriendshipImplToJson(_$FriendshipImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'friends': instance.friends,
      'following': instance.following,
      'requested': instance.requested,
      'privateAccount': instance.privateAccount,
    };
