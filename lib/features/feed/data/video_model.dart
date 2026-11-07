import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_model.freezed.dart';
part 'video_model.g.dart';

enum VideoStatus {
  /// Just uploaded, still transcoding: no [VideoModel.hlsUrl] yet, and absent
  /// from the feed.
  @JsonValue('PROCESSING')
  processing,

  /// Transcoded, waiting on the automatic content check. Owner only.
  @JsonValue('PENDING_MODERATION')
  pendingModeration,

  /// The automatic check was unsure; waiting on a moderator. Owner only.
  @JsonValue('PENDING_REVIEW')
  pendingReview,

  /// Playable, and the only status that appears on /feed.
  @JsonValue('PUBLISHED')
  published,

  /// Transcode failed. Visible to the owner only.
  @JsonValue('FAILED')
  failed,

  /// Refused by the automatic content check. Owner only.
  @JsonValue('REJECTED')
  rejected,

  /// Removed by moderation. Visible to the owner only.
  @JsonValue('TAKEN_DOWN')
  takenDown,
  unknown,
}

enum VideoVisibility {
  @JsonValue('PUBLIC')
  public,
  @JsonValue('FRIENDS')
  friends,
  @JsonValue('PRIVATE')
  private,
  unknown,
}

// userId is a Snowflake arriving as a JSON number; keep it as String so it is
// never round-tripped through a double. The video's own `id` is already sent
// as a string precisely because 19 digits overflow a JS number on web.
String _idFromJson(Object? value) => value.toString();

@freezed
class VideoModel with _$VideoModel {
  const factory VideoModel({
    required String id,
    @JsonKey(fromJson: _idFromJson) required String userId,
    required String title,
    String? description,
    // These three stay null until transcoding finishes.
    String? thumbnailUrl,
    String? hlsUrl,
    int? durationSeconds,
    @JsonKey(unknownEnumValue: VideoStatus.unknown) required VideoStatus status,
    @JsonKey(unknownEnumValue: VideoVisibility.unknown)
    required VideoVisibility visibility,

    /// Set by the owner. New comments are refused while it is true; the ones
    /// already posted stay readable.
    @Default(false) bool commentsDisabled,
    // Updated asynchronously via Kafka, so they lag behind a like/comment that
    // just happened — a value to sync against on reload, not an immediate
    // result (video doc 5).
    required int viewCount,
    required int likeCount,
    // Null from the server while comments are off — the video's own switch or
    // the owner's account setting (video doc 3.2) — and the total is not shown
    // then, so 0 stands in.
    @JsonKey(fromJson: _countOrZero) required int commentCount,
    // Shares have no counter on VideoResponse, so this stays 0 and the rail
    // falls back to a plain label. Saves have no counter anywhere — a save is
    // private — so there is no field for them at all.
    @Default(0) int shareCount,
    required DateTime createdAt,

    /// The song under the video and its credit; null without one.
    MusicCredit? music,

    /// When the owner pinned it to the top of their profile; null when not
    /// pinned. At most three are pinned at once.
    DateTime? pinnedAt,

    /// Why transcoding failed (FAILED) or why a moderator removed it
    /// (TAKEN_DOWN). Sent to the owner only.
    String? failureReason,
    String? takedownReason,
  }) = _VideoModel;

  factory VideoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoModelFromJson(json);
}

int _countOrZero(Object? json) => (json as num?)?.toInt() ?? 0;

/// Credit for the Creative Commons song under a video, as its licence asks:
/// title, artist, and links to the track and the licence.
@freezed
class MusicCredit with _$MusicCredit {
  const factory MusicCredit({
    required String title,
    required String artist,
    String? trackId,
    String? licenseUrl,
    String? shareUrl,
  }) = _MusicCredit;

  factory MusicCredit.fromJson(Map<String, dynamic> json) =>
      _$MusicCreditFromJson(json);
}
