// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionModelImpl _$$SessionModelImplFromJson(Map<String, dynamic> json) =>
    _$SessionModelImpl(
      id: _idFromJson(json['id']),
      deviceType:
          $enumDecodeNullable(
            _$DeviceTypeEnumMap,
            json['deviceType'],
            unknownValue: DeviceType.unknown,
          ) ??
          DeviceType.unknown,
      deviceLabel: json['deviceLabel'] as String?,
      deviceModel: json['deviceModel'] as String?,
      ipAddress: json['ipAddress'] as String?,
      location: json['location'] as String?,
      signedInAt: DateTime.parse(json['signedInAt'] as String),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      current: json['current'] as bool? ?? false,
    );

Map<String, dynamic> _$$SessionModelImplToJson(_$SessionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceType': _$DeviceTypeEnumMap[instance.deviceType]!,
      'deviceLabel': instance.deviceLabel,
      'deviceModel': instance.deviceModel,
      'ipAddress': instance.ipAddress,
      'location': instance.location,
      'signedInAt': instance.signedInAt.toIso8601String(),
      'lastActiveAt': instance.lastActiveAt.toIso8601String(),
      'current': instance.current,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.desktop: 'DESKTOP',
  DeviceType.mobile: 'MOBILE',
  DeviceType.unknown: 'unknown',
};
