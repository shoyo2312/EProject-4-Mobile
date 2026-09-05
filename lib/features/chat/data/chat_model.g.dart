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

_$MessageModelImpl _$$MessageModelImplFromJson(Map<String, dynamic> json) =>
    _$MessageModelImpl(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: _idFromJson(json['senderId']),
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );

Map<String, dynamic> _$$MessageModelImplToJson(_$MessageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'content': instance.content,
      'sentAt': instance.sentAt.toIso8601String(),
    };
