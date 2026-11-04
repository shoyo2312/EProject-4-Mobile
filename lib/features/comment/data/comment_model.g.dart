// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentStickerImpl _$$CommentStickerImplFromJson(Map<String, dynamic> json) =>
    _$CommentStickerImpl(
      stickerId: json['stickerId'] as String,
      url: json['url'] as String,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$CommentStickerImplToJson(
  _$CommentStickerImpl instance,
) => <String, dynamic>{
  'stickerId': instance.stickerId,
  'url': instance.url,
  'width': instance.width,
  'height': instance.height,
};

_$CommentModelImpl _$$CommentModelImplFromJson(Map<String, dynamic> json) =>
    _$CommentModelImpl(
      id: _idFromJson(json['commentId']),
      videoId: _idFromJson(json['videoId']),
      userId: _idFromJson(json['userId']),
      text: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      parentId: _idOrNullFromJson(json['parentId']),
      replyToUserId: _idOrNullFromJson(json['replyToUserId']),
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      sticker: json['sticker'] == null
          ? null
          : CommentSticker.fromJson(json['sticker'] as Map<String, dynamic>),
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      status:
          $enumDecodeNullable(
            _$CommentStatusEnumMap,
            json['status'],
            unknownValue: CommentStatus.unknown,
          ) ??
          CommentStatus.visible,
    );

Map<String, dynamic> _$$CommentModelImplToJson(_$CommentModelImpl instance) =>
    <String, dynamic>{
      'commentId': instance.id,
      'videoId': instance.videoId,
      'userId': instance.userId,
      'content': instance.text,
      'createdAt': instance.createdAt.toIso8601String(),
      'parentId': instance.parentId,
      'replyToUserId': instance.replyToUserId,
      'replyCount': instance.replyCount,
      'sticker': instance.sticker,
      'editedAt': instance.editedAt?.toIso8601String(),
      'likeCount': instance.likeCount,
      'likedByMe': instance.likedByMe,
      'status': _$CommentStatusEnumMap[instance.status]!,
    };

const _$CommentStatusEnumMap = {
  CommentStatus.visible: 'VISIBLE',
  CommentStatus.held: 'HELD',
  CommentStatus.unknown: 'unknown',
};
