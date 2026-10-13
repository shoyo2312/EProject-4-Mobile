// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationModelImpl(
  id: json['id'] as String,
  type: _kindFromJson(json['type']),
  title: json['title'] as String,
  body: json['body'] as String,
  referenceId: json['referenceId'] as String?,
  read: json['read'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$NotificationModelImplToJson(
  _$NotificationModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': _$NotificationKindEnumMap[instance.type]!,
  'title': instance.title,
  'body': instance.body,
  'referenceId': instance.referenceId,
  'read': instance.read,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$NotificationKindEnumMap = {
  NotificationKind.like: 'LIKE',
  NotificationKind.comment: 'COMMENT',
  NotificationKind.share: 'SHARE',
  NotificationKind.newFollower: 'NEW_FOLLOWER',
  NotificationKind.system: 'SYSTEM',
};
