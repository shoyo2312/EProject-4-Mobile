import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// What the row is about. The server may add cases, so anything unknown lands
/// on [system] rather than failing the whole inbox.
@JsonEnum(alwaysCreate: true)
enum NotificationKind {
  @JsonValue('LIKE')
  like,
  @JsonValue('COMMENT')
  comment,
  @JsonValue('SHARE')
  share,
  @JsonValue('NEW_FOLLOWER')
  newFollower,
  @JsonValue('SYSTEM')
  system,
}

NotificationKind _kindFromJson(Object? value) =>
    $enumDecodeNullable(_$NotificationKindEnumMap, value) ??
    NotificationKind.system;

/// One row of `GET /notifications`.
///
/// [referenceId] is whatever the type points at — a videoId, a commentId, the
/// follower's userId — and is opaque to notification-service, so only the
/// client knows where it leads. It is null for [NotificationKind.system].
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    @JsonKey(fromJson: _kindFromJson) required NotificationKind type,
    required String title,
    required String body,
    String? referenceId,
    required bool read,
    required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
