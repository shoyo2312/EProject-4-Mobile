// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentModelImpl _$$CommentModelImplFromJson(Map<String, dynamic> json) =>
    _$CommentModelImpl(
      id: _idFromJson(json['commentId']),
      videoId: _idFromJson(json['videoId']),
      userId: _idFromJson(json['userId']),
      text: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
    );

Map<String, dynamic> _$$CommentModelImplToJson(_$CommentModelImpl instance) =>
    <String, dynamic>{
      'commentId': instance.id,
      'videoId': instance.videoId,
      'userId': instance.userId,
      'content': instance.text,
      'createdAt': instance.createdAt.toIso8601String(),
      'likeCount': instance.likeCount,
      'likedByMe': instance.likedByMe,
    };
