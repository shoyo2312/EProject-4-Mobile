// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_filter_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentFilterSettingsImpl _$$CommentFilterSettingsImplFromJson(
  Map<String, dynamic> json,
) => _$CommentFilterSettingsImpl(
  filterSpamOffensive: json['filterSpamOffensive'] as bool? ?? true,
  filterAllComments: json['filterAllComments'] as bool? ?? false,
  commentKeywords:
      (json['commentKeywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$$CommentFilterSettingsImplToJson(
  _$CommentFilterSettingsImpl instance,
) => <String, dynamic>{
  'filterSpamOffensive': instance.filterSpamOffensive,
  'filterAllComments': instance.filterAllComments,
  'commentKeywords': instance.commentKeywords,
};
