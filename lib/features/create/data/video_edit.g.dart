// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_edit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoEditImpl _$$VideoEditImplFromJson(Map<String, dynamic> json) =>
    _$VideoEditImpl(
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map((e) => EditSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      filter: json['filter'] == null
          ? null
          : EditFilter.fromJson(json['filter'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VideoEditImplToJson(_$VideoEditImpl instance) =>
    <String, dynamic>{'segments': instance.segments, 'filter': instance.filter};

_$EditFilterImpl _$$EditFilterImplFromJson(Map<String, dynamic> json) =>
    _$EditFilterImpl(
      id: json['id'] as String,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$$EditFilterImplToJson(_$EditFilterImpl instance) =>
    <String, dynamic>{'id': instance.id, 'intensity': instance.intensity};

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
