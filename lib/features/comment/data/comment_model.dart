import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

// commentId, videoId and userId all arrive as JSON numbers (interaction doc 2);
// keep them as strings so a 19-digit Snowflake is never round-tripped through
// a double, and so videoId matches the string form video-service sends.
String _idFromJson(Object? value) => value.toString();

/// `CommentResponse` from interaction-service.
///
/// The service holds no user data, so a comment carries only `userId` — the
/// name and picture come from user-service, resolved through the shared
/// profile cache (interaction doc 3.4).
@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    @JsonKey(name: 'commentId', fromJson: _idFromJson) required String id,
    @JsonKey(fromJson: _idFromJson) required String videoId,
    @JsonKey(fromJson: _idFromJson) required String userId,
    @JsonKey(name: 'content') required String text,
    required DateTime createdAt,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}
