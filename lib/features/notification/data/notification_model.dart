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

  /// Someone liked one of this user's comments; referenceId is the video the
  /// comment sits under.
  @JsonValue('COMMENT_LIKE')
  commentLike,
  @JsonValue('SHARE')
  share,

  /// Someone reposted this user's video; referenceId is that video.
  @JsonValue('REPOST')
  repost,
  @JsonValue('NEW_FOLLOWER')
  newFollower,

  /// Someone you follow posted a story. [NotificationModel.referenceId] is
  /// the story owner's id, not the story's.
  @JsonValue('STORY')
  story,

  /// Someone asked to follow this private account. [NotificationModel.referenceId]
  /// is the requester's id; the request itself may since have been answered,
  /// so the requests list is where it leads.
  @JsonValue('FOLLOW_REQUEST')
  followRequest,

  /// A private account approved this user's request; referenceId is theirs.
  @JsonValue('FOLLOW_REQUEST_ACCEPTED')
  followRequestAccepted,

  /// Last week's screen time; referenceId is that week's Monday.
  @JsonValue('SCREEN_TIME')
  screenTime,
  @JsonValue('SYSTEM')
  system,
}

NotificationKind _kindFromJson(Object? value) =>
    $enumDecodeNullable(
      _$NotificationKindEnumMap,
      value,
      unknownValue: NotificationKind.system,
    ) ??
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
