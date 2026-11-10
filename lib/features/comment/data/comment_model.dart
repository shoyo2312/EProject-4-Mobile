import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

// commentId, videoId and userId all arrive as JSON numbers (interaction doc 2);
// keep them as strings so a 19-digit Snowflake is never round-tripped through
// a double, and so videoId matches the string form video-service sends.
String _idFromJson(Object? value) => value.toString();
String? _idOrNullFromJson(Object? value) => value?.toString();

/// The sticker on a comment, as interaction-service resolves it from the
/// shared sticker catalog. [url] is public, like a chat sticker's.
@freezed
class CommentSticker with _$CommentSticker {
  const factory CommentSticker({
    required String stickerId,
    required String url,
    @Default(0) int width,
    @Default(0) int height,
  }) = _CommentSticker;

  factory CommentSticker.fromJson(Map<String, dynamic> json) =>
      _$CommentStickerFromJson(json);
}

/// Whether anyone but the author can read the comment (interaction doc 3.4).
enum CommentStatus {
  @JsonValue('VISIBLE')
  visible,

  /// Stored, but flagged by the server's text filters (or the owner's own
  /// filters) and kept out of the thread. Only its author knows it exists.
  @JsonValue('HELD')
  held,
  unknown,
}

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

    /// Empty for a sticker-only comment.
    @JsonKey(name: 'content') @Default('') String text,
    required DateTime createdAt,

    /// Null for a top-level comment; the top-level comment's id for a reply
    /// (the thread is one level deep — the server flattens deeper replies).
    @JsonKey(fromJson: _idOrNullFromJson) String? parentId,

    /// Set only on a reply to another reply: whom it answers, for "A > B".
    @JsonKey(fromJson: _idOrNullFromJson) String? replyToUserId,

    /// Live replies under a top-level comment. Always 0 on a reply.
    @Default(0) int replyCount,
    CommentSticker? sticker,

    /// Set once the author has edited the text.
    DateTime? editedAt,

    /// Denormalised tally kept by interaction-service.
    @Default(0) int likeCount,

    /// Always false on an anonymous listing — a guest has no hearts to fill.
    @Default(false) bool likedByMe,

    /// Absent on rows written before moderation existed, which are visible.
    @JsonKey(unknownEnumValue: CommentStatus.unknown)
    @Default(CommentStatus.visible)
    CommentStatus status,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  const CommentModel._();

  bool get isReply => parentId != null;
}
