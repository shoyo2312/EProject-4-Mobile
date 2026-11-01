// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoryModelImpl _$$StoryModelImplFromJson(Map<String, dynamic> json) =>
    _$StoryModelImpl(
      id: json['id'] as String,
      userId: _idFromJson(json['userId']),
      mediaUrl: json['mediaUrl'] as String,
      mediaType: $enumDecode(
        _$StoryMediaTypeEnumMap,
        json['mediaType'],
        unknownValue: StoryMediaType.unknown,
      ),
      caption: json['caption'] as String?,
      visibility: $enumDecode(
        _$StoryVisibilityEnumMap,
        json['visibility'],
        unknownValue: StoryVisibility.unknown,
      ),
      status: $enumDecodeNullable(
        _$StoryStatusEnumMap,
        json['status'],
        unknownValue: StoryStatus.unknown,
      ),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      viewCount: (json['viewCount'] as num?)?.toInt(),
      viewedByMe: json['viewedByMe'] as bool? ?? false,
      myReaction: $enumDecodeNullable(
        _$StoryReactionEnumMap,
        json['myReaction'],
        unknownValue: StoryReaction.unknown,
      ),
      reactionCounts: _countsFromJson(json['reactionCounts']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$$StoryModelImplToJson(_$StoryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'mediaUrl': instance.mediaUrl,
      'mediaType': _$StoryMediaTypeEnumMap[instance.mediaType]!,
      'caption': instance.caption,
      'visibility': _$StoryVisibilityEnumMap[instance.visibility]!,
      'status': _$StoryStatusEnumMap[instance.status],
      'durationSeconds': instance.durationSeconds,
      'viewCount': instance.viewCount,
      'viewedByMe': instance.viewedByMe,
      'myReaction': _$StoryReactionEnumMap[instance.myReaction],
      'reactionCounts': _countsToJson(instance.reactionCounts),
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

const _$StoryMediaTypeEnumMap = {
  StoryMediaType.image: 'IMAGE',
  StoryMediaType.video: 'VIDEO',
  StoryMediaType.unknown: 'unknown',
};

const _$StoryVisibilityEnumMap = {
  StoryVisibility.public: 'PUBLIC',
  StoryVisibility.friends: 'FRIENDS',
  StoryVisibility.private: 'PRIVATE',
  StoryVisibility.unknown: 'unknown',
};

const _$StoryStatusEnumMap = {
  StoryStatus.pendingModeration: 'PENDING_MODERATION',
  StoryStatus.active: 'ACTIVE',
  StoryStatus.held: 'HELD',
  StoryStatus.rejected: 'REJECTED',
  StoryStatus.unknown: 'unknown',
};

const _$StoryReactionEnumMap = {
  StoryReaction.like: 'LIKE',
  StoryReaction.love: 'LOVE',
  StoryReaction.wow: 'WOW',
  StoryReaction.angry: 'ANGRY',
  StoryReaction.sad: 'SAD',
  StoryReaction.unknown: 'unknown',
};

_$StoryGroupImpl _$$StoryGroupImplFromJson(Map<String, dynamic> json) =>
    _$StoryGroupImpl(
      userId: _idFromJson(json['userId']),
      stories: (json['stories'] as List<dynamic>)
          .map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasUnseen: json['hasUnseen'] as bool? ?? false,
    );

Map<String, dynamic> _$$StoryGroupImplToJson(_$StoryGroupImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'stories': instance.stories,
      'hasUnseen': instance.hasUnseen,
    };

_$StoryRingImpl _$$StoryRingImplFromJson(Map<String, dynamic> json) =>
    _$StoryRingImpl(
      userId: _idFromJson(json['userId']),
      hasUnseen: json['hasUnseen'] as bool? ?? false,
    );

Map<String, dynamic> _$$StoryRingImplToJson(_$StoryRingImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'hasUnseen': instance.hasUnseen,
    };

_$StoryViewerImpl _$$StoryViewerImplFromJson(Map<String, dynamic> json) =>
    _$StoryViewerImpl(
      viewerId: _idFromJson(json['viewerId']),
      viewedAt: DateTime.parse(json['viewedAt'] as String),
      reaction: $enumDecodeNullable(
        _$StoryReactionEnumMap,
        json['reaction'],
        unknownValue: StoryReaction.unknown,
      ),
    );

Map<String, dynamic> _$$StoryViewerImplToJson(_$StoryViewerImpl instance) =>
    <String, dynamic>{
      'viewerId': instance.viewerId,
      'viewedAt': instance.viewedAt.toIso8601String(),
      'reaction': _$StoryReactionEnumMap[instance.reaction],
    };
