// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoModelImpl _$$VideoModelImplFromJson(Map<String, dynamic> json) =>
    _$VideoModelImpl(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      caption: json['caption'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      likeCount: (json['likeCount'] as num).toInt(),
      commentCount: (json['commentCount'] as num).toInt(),
      shareCount: (json['shareCount'] as num).toInt(),
      isLiked: json['isLiked'] as bool,
      isSaved: json['isSaved'] as bool,
    );

Map<String, dynamic> _$$VideoModelImplToJson(_$VideoModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'thumbnailUrl': instance.thumbnailUrl,
      'caption': instance.caption,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'likeCount': instance.likeCount,
      'commentCount': instance.commentCount,
      'shareCount': instance.shareCount,
      'isLiked': instance.isLiked,
      'isSaved': instance.isSaved,
    };
