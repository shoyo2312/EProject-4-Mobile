// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: _idFromJson(json['id']),
      username: json['username'] as String,
      email: json['email'] as String,
      role: $enumDecode(
        _$UserRoleEnumMap,
        json['role'],
        unknownValue: UserRole.unknown,
      ),
      status: $enumDecode(
        _$UserStatusEnumMap,
        json['status'],
        unknownValue: UserStatus.unknown,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'role': _$UserRoleEnumMap[instance.role]!,
      'status': _$UserStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.user: 'USER',
  UserRole.admin: 'ADMIN',
  UserRole.unknown: 'unknown',
};

const _$UserStatusEnumMap = {
  UserStatus.active: 'ACTIVE',
  UserStatus.locked: 'LOCKED',
  UserStatus.unknown: 'unknown',
};
