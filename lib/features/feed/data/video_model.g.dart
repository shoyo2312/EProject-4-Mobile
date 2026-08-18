// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoModelImpl _$$VideoModelImplFromJson(Map<String, dynamic> json) =>
    _$VideoModelImpl(
      id: json['id'] as String,
      userId: _idFromJson(json['userId']),
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      status: $enumDecode(
        _$VideoStatusEnumMap,
        json['status'],
        unknownValue: VideoStatus.unknown,
      ),
      visibility: $enumDecode(
        _$VideoVisibilityEnumMap,
        json['visibility'],
        unknownValue: VideoVisibility.unknown,
      ),
      viewCount: (json['viewCount'] as num).toInt(),
      likeCount: (json['likeCount'] as num).toInt(),
      commentCount: (json['commentCount'] as num).toInt(),
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$VideoModelImplToJson(_$VideoModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'thumbnailUrl': instance.thumbnailUrl,
      'hlsUrl': instance.hlsUrl,
      'durationSeconds': instance.durationSeconds,
      'status': _$VideoStatusEnumMap[instance.status]!,
      'visibility': _$VideoVisibilityEnumMap[instance.visibility]!,
      'viewCount': instance.viewCount,
      'likeCount': instance.likeCount,
      'commentCount': instance.commentCount,
      'saveCount': instance.saveCount,
      'shareCount': instance.shareCount,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$VideoStatusEnumMap = {
  VideoStatus.processing: 'PROCESSING',
  VideoStatus.published: 'PUBLISHED',
  VideoStatus.failed: 'FAILED',
  VideoStatus.takenDown: 'TAKEN_DOWN',
  VideoStatus.unknown: 'unknown',
};

const _$VideoVisibilityEnumMap = {
  VideoVisibility.public: 'PUBLIC',
  VideoVisibility.private: 'PRIVATE',
  VideoVisibility.unknown: 'unknown',
};
