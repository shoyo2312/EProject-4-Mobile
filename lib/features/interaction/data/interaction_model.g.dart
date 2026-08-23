// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LikeStatusImpl _$$LikeStatusImplFromJson(Map<String, dynamic> json) =>
    _$LikeStatusImpl(
      videoId: _idFromJson(json['videoId']),
      liked: json['liked'] as bool,
      likeCount: (json['likeCount'] as num).toInt(),
    );

Map<String, dynamic> _$$LikeStatusImplToJson(_$LikeStatusImpl instance) =>
    <String, dynamic>{
      'videoId': instance.videoId,
      'liked': instance.liked,
      'likeCount': instance.likeCount,
    };

_$InteractionCountsImpl _$$InteractionCountsImplFromJson(
  Map<String, dynamic> json,
) => _$InteractionCountsImpl(
  videoId: _idFromJson(json['videoId']),
  likeCount: (json['likeCount'] as num).toInt(),
  commentCount: (json['commentCount'] as num).toInt(),
  shareCount: (json['shareCount'] as num).toInt(),
  viewCount: (json['viewCount'] as num).toInt(),
);

Map<String, dynamic> _$$InteractionCountsImplToJson(
  _$InteractionCountsImpl instance,
) => <String, dynamic>{
  'videoId': instance.videoId,
  'likeCount': instance.likeCount,
  'commentCount': instance.commentCount,
  'shareCount': instance.shareCount,
  'viewCount': instance.viewCount,
};
