// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationModelImpl _$$ConversationModelImplFromJson(
  Map<String, dynamic> json,
) => _$ConversationModelImpl(
  id: json['id'] as String,
  participantIds: _idsFromJson(json['participantIds']),
  lastMessageContent: json['lastMessageContent'] as String?,
  lastMessageSenderId: _nullableIdFromJson(json['lastMessageSenderId']),
  lastMessageAt: json['lastMessageAt'] == null
      ? null
      : DateTime.parse(json['lastMessageAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  hasUnread: json['hasUnread'] as bool? ?? false,
);

Map<String, dynamic> _$$ConversationModelImplToJson(
  _$ConversationModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'participantIds': instance.participantIds,
  'lastMessageContent': instance.lastMessageContent,
  'lastMessageSenderId': instance.lastMessageSenderId,
  'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'hasUnread': instance.hasUnread,
};

_$StickerModelImpl _$$StickerModelImplFromJson(Map<String, dynamic> json) =>
    _$StickerModelImpl(
      stickerId: json['stickerId'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$StickerModelImplToJson(_$StickerModelImpl instance) =>
    <String, dynamic>{
      'stickerId': instance.stickerId,
      'name': instance.name,
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
    };

_$StickerPackImpl _$$StickerPackImplFromJson(Map<String, dynamic> json) =>
    _$StickerPackImpl(
      packId: json['packId'] as String,
      name: json['name'] as String,
      stickers:
          (json['stickers'] as List<dynamic>?)
              ?.map((e) => StickerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$StickerPackImplToJson(_$StickerPackImpl instance) =>
    <String, dynamic>{
      'packId': instance.packId,
      'name': instance.name,
      'stickers': instance.stickers,
    };

_$ChatImageModelImpl _$$ChatImageModelImplFromJson(Map<String, dynamic> json) =>
    _$ChatImageModelImpl(
      imageId: json['imageId'] as String,
      url: json['url'] as String,
      mime: json['mime'] as String?,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ChatImageModelImplToJson(
  _$ChatImageModelImpl instance,
) => <String, dynamic>{
  'imageId': instance.imageId,
  'url': instance.url,
  'mime': instance.mime,
  'width': instance.width,
  'height': instance.height,
  'size': instance.size,
};

_$MessageModelImpl _$$MessageModelImplFromJson(Map<String, dynamic> json) =>
    _$MessageModelImpl(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: _idFromJson(json['senderId']),
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      type:
          $enumDecodeNullable(
            _$MessageTypeEnumMap,
            json['type'],
            unknownValue: MessageType.unknown,
          ) ??
          MessageType.text,
      sticker: json['sticker'] == null
          ? null
          : StickerModel.fromJson(json['sticker'] as Map<String, dynamic>),
      image: json['image'] == null
          ? null
          : ChatImageModel.fromJson(json['image'] as Map<String, dynamic>),
      recalledAt: json['recalledAt'] == null
          ? null
          : DateTime.parse(json['recalledAt'] as String),
    );

Map<String, dynamic> _$$MessageModelImplToJson(_$MessageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'content': instance.content,
      'sentAt': instance.sentAt.toIso8601String(),
      'type': _$MessageTypeEnumMap[instance.type]!,
      'sticker': instance.sticker,
      'image': instance.image,
      'recalledAt': instance.recalledAt?.toIso8601String(),
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'TEXT',
  MessageType.sticker: 'STICKER',
  MessageType.video: 'VIDEO',
  MessageType.storyReply: 'STORY_REPLY',
  MessageType.image: 'IMAGE',
  MessageType.unknown: 'unknown',
};
