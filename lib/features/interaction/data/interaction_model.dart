import 'package:freezed_annotation/freezed_annotation.dart';

part 'interaction_model.freezed.dart';
part 'interaction_model.g.dart';

/// interaction-service sends every id as a JSON number, while video-service
/// sends the same video's id as a string (interaction doc 2). Keep the string
/// form so a row coming back from here can be matched against a [VideoModel].
String _idFromJson(Object? value) => value.toString();

/// The answer to `POST /like`, `DELETE /like` and `GET /like-status` alike.
///
/// Signed out, `liked` is always `false` and no error says so — an empty heart
/// after a restart is a missing token before it is missing data (doc 3.3).
@freezed
class LikeStatus with _$LikeStatus {
  const factory LikeStatus({
    @JsonKey(fromJson: _idFromJson) required String videoId,
    required bool liked,
    required int likeCount,
  }) = _LikeStatus;

  factory LikeStatus.fromJson(Map<String, dynamic> json) =>
      _$LikeStatusFromJson(json);
}

/// `InteractionCountResponse` — the source of truth for the four counters.
///
/// The same numbers on `VideoResponse` reach video-service over Kafka, so they
/// lag a like or a comment that just happened (interaction doc 3.10). A video
/// nobody has touched answers all zeros, not 404.
@freezed
class InteractionCounts with _$InteractionCounts {
  const factory InteractionCounts({
    @JsonKey(fromJson: _idFromJson) required String videoId,
    required int likeCount,
    required int commentCount,
    required int shareCount,
    required int viewCount,
  }) = _InteractionCounts;

  factory InteractionCounts.fromJson(Map<String, dynamic> json) =>
      _$InteractionCountsFromJson(json);
}

/// The answer to `POST /save`, `DELETE /save` and `GET /save-status`.
///
/// No count alongside it, unlike [LikeStatus]: a save is private to the user
/// and there is no `save_count` column to read one from. Authenticated only —
/// there is no anonymous answer to give (interaction doc 3.11).
@freezed
class SaveStatus with _$SaveStatus {
  const factory SaveStatus({
    @JsonKey(fromJson: _idFromJson) required String videoId,
    required bool saved,
  }) = _SaveStatus;

  factory SaveStatus.fromJson(Map<String, dynamic> json) =>
      _$SaveStatusFromJson(json);
}

/// One page of `GET /interactions/users/me/likes` or `.../saves`: video ids and
/// nothing else.
///
/// interaction-service stores no video metadata, so the caller hydrates these
/// through `GET /videos/batch` — which is also why ids that no longer resolve
/// simply come back missing from the hydration rather than failing it.
class VideoIdPage {
  const VideoIdPage({
    required this.videoIds,
    required this.hasMore,
    this.nextCursor,
  });

  final List<String> videoIds;
  final bool hasMore;
  final String? nextCursor;
}
