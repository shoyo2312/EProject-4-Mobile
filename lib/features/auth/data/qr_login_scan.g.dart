// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_login_scan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QrLoginScanImpl _$$QrLoginScanImplFromJson(Map<String, dynamic> json) =>
    _$QrLoginScanImpl(
      deviceLabel: json['deviceLabel'] as String?,
      location: json['location'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$$QrLoginScanImplToJson(_$QrLoginScanImpl instance) =>
    <String, dynamic>{
      'deviceLabel': instance.deviceLabel,
      'location': instance.location,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
