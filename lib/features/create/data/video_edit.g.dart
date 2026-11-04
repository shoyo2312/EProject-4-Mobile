// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_edit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoEditImpl _$$VideoEditImplFromJson(Map<String, dynamic> json) =>
    _$VideoEditImpl(
      segments: (json['segments'] as List<dynamic>)
          .map((e) => EditSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$VideoEditImplToJson(_$VideoEditImpl instance) =>
    <String, dynamic>{'segments': instance.segments};

_$EditSegmentImpl _$$EditSegmentImplFromJson(Map<String, dynamic> json) =>
    _$EditSegmentImpl(
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$$EditSegmentImplToJson(_$EditSegmentImpl instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'speed': instance.speed,
    };
