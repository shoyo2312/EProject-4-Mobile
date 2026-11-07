// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      commentAudience:
          $enumDecodeNullable(
            _$SettingsAudienceEnumMap,
            json['commentAudience'],
            unknownValue: SettingsAudience.unknown,
          ) ??
          SettingsAudience.everyone,
      dmAudience:
          $enumDecodeNullable(
            _$SettingsAudienceEnumMap,
            json['dmAudience'],
            unknownValue: SettingsAudience.unknown,
          ) ??
          SettingsAudience.everyone,
      screenTimeLimitMinutes: (json['screenTimeLimitMinutes'] as num?)?.toInt(),
      screenTimeLimitsByDay: (json['screenTimeLimitsByDay'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      hasScreenTimePasscode: json['hasScreenTimePasscode'] as bool? ?? false,
      sleepHoursStart: json['sleepHoursStart'] as String?,
      sleepHoursEnd: json['sleepHoursEnd'] as String?,
      weeklyScreenTimeDigest: json['weeklyScreenTimeDigest'] as bool? ?? true,
      privateAccount: json['privateAccount'] as bool? ?? false,
      timeZone: json['timeZone'] as String?,
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'commentAudience': _$SettingsAudienceEnumMap[instance.commentAudience]!,
      'dmAudience': _$SettingsAudienceEnumMap[instance.dmAudience]!,
      'screenTimeLimitMinutes': instance.screenTimeLimitMinutes,
      'screenTimeLimitsByDay': instance.screenTimeLimitsByDay,
      'hasScreenTimePasscode': instance.hasScreenTimePasscode,
      'sleepHoursStart': instance.sleepHoursStart,
      'sleepHoursEnd': instance.sleepHoursEnd,
      'weeklyScreenTimeDigest': instance.weeklyScreenTimeDigest,
      'privateAccount': instance.privateAccount,
      'timeZone': instance.timeZone,
    };

const _$SettingsAudienceEnumMap = {
  SettingsAudience.everyone: 'EVERYONE',
  SettingsAudience.friends: 'FRIENDS',
  SettingsAudience.noOne: 'NO_ONE',
  SettingsAudience.unknown: 'unknown',
};

_$KeywordFilterImpl _$$KeywordFilterImplFromJson(Map<String, dynamic> json) =>
    _$KeywordFilterImpl(
      id: _idFromJson(json['id']),
      keyword: json['keyword'] as String,
      forYou: json['forYou'] as bool? ?? true,
      following: json['following'] as bool? ?? true,
      friends: json['friends'] as bool? ?? true,
    );

Map<String, dynamic> _$$KeywordFilterImplToJson(_$KeywordFilterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'keyword': instance.keyword,
      'forYou': instance.forYou,
      'following': instance.following,
      'friends': instance.friends,
    };

_$ScreenTimeDayImpl _$$ScreenTimeDayImplFromJson(Map<String, dynamic> json) =>
    _$ScreenTimeDayImpl(
      date: json['date'] as String,
      daySeconds: (json['daySeconds'] as num?)?.toInt() ?? 0,
      nightSeconds: (json['nightSeconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ScreenTimeDayImplToJson(_$ScreenTimeDayImpl instance) =>
    <String, dynamic>{
      'date': instance.date,
      'daySeconds': instance.daySeconds,
      'nightSeconds': instance.nightSeconds,
    };

_$ScreenTimeWeekImpl _$$ScreenTimeWeekImplFromJson(Map<String, dynamic> json) =>
    _$ScreenTimeWeekImpl(
      weekStart: json['weekStart'] as String,
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => ScreenTimeDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ScreenTimeDay>[],
    );

Map<String, dynamic> _$$ScreenTimeWeekImplToJson(
  _$ScreenTimeWeekImpl instance,
) => <String, dynamic>{'weekStart': instance.weekStart, 'days': instance.days};
