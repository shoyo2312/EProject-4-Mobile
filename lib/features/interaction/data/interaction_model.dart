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
