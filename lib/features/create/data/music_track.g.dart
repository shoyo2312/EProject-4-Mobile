// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MusicTrackImpl _$$MusicTrackImplFromJson(Map<String, dynamic> json) =>
    _$MusicTrackImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      audioUrl: json['audioUrl'] as String,
      imageUrl: json['imageUrl'] as String?,
      licenseUrl: json['licenseUrl'] as String?,
      shareUrl: json['shareUrl'] as String?,
    );

Map<String, dynamic> _$$MusicTrackImplToJson(_$MusicTrackImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'durationSeconds': instance.durationSeconds,
      'audioUrl': instance.audioUrl,
      'imageUrl': instance.imageUrl,
      'licenseUrl': instance.licenseUrl,
      'shareUrl': instance.shareUrl,
    };
