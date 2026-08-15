import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_model.freezed.dart';
part 'video_model.g.dart';

enum VideoStatus {
  /// Just uploaded, still transcoding: no [VideoModel.hlsUrl] yet, and absent
  /// from the feed.
  @JsonValue('PROCESSING')
  processing,

  /// Playable, and the only status that appears on /feed.
  @JsonValue('PUBLISHED')
  published,

  /// Transcode failed. Visible to the owner only.
  @JsonValue('FAILED')
  failed,

  /// Removed by moderation. Visible to the owner only.
  @JsonValue('TAKEN_DOWN')
  takenDown,
  unknown,
}

enum VideoVisibility {
  @JsonValue('PUBLIC')
  public,
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
    // Updated asynchronously via Kafka, so they lag behind a like/comment that
    // just happened — a value to sync against on reload, not an immediate
    // result (video doc 5).
    required int viewCount,
    required int likeCount,
    required int commentCount,
    // Save/share have no counter in the API yet, so they default to 0 and the
    // rail falls back to a plain label — same arrangement as
    // CommentModel.replyCount.
    @Default(0) int saveCount,
    @Default(0) int shareCount,
    required DateTime createdAt,
  }) = _VideoModel;

  factory VideoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoModelFromJson(json);
}
