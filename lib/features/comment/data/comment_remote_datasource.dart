import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';

/// One page of `GET /interactions/videos/{videoId}/comments`.
///
/// [hasMore] is the only end-of-list signal: a page can come back empty while
/// there is still more, because deleted rows are filtered after Cassandra has
/// already cut the page (interaction doc 3.5).
class CommentPage {
  const CommentPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<CommentModel> items;
  final bool hasMore;
  final String? nextCursor;
}

/// The answer to `POST` and `DELETE` on a comment's `/like`: the new state plus
/// the tally interaction-service now holds.
class CommentLikeResult {
  const CommentLikeResult({required this.liked, required this.likeCount});

  final bool liked;
  final int likeCount;
}

/// Comments live in interaction-service, not video-service: the gateway routes
/// `/videos/**` to video-service, which has no comment endpoint at all.
class CommentRemoteDatasource {
  CommentRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// Top-level comments only, most interaction (likes + replies) first
  /// (interaction doc 3.5, `sort=top`). The cursor only works with the same
  /// `sort`, which is why it is fixed here.
  Future<CommentPage> fetchComments(String videoId, {String? cursor}) => _page(
        '/interactions/videos/$videoId/comments',
        cursor: cursor,
        size: 20,
        sort: 'top',
      );

  /// One thread's replies, oldest first. Needs a token (interaction doc 3.5b).
  Future<CommentPage> fetchReplies(
    String videoId,
    String parentId, {
    String? cursor,
    int size = 10,
  }) =>
      _page(
        '/interactions/videos/$videoId/comments/$parentId/replies',
        cursor: cursor,
        size: size,
      );

  Future<CommentPage> _page(
    String path, {
    String? cursor,
    required int size,
    String? sort,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path,
      queryParameters: {
        'cursor': ?cursor,
        'size': size,
        'sort': ?sort,
      },
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CommentPage(
      items: items,
      hasMore: body['hasMore'] as bool? ?? false,
      nextCursor: body['nextCursor'] as String?,
    );
  }

  /// Not deduplicated server-side — send it once per tap and never retry, or
  /// the comment lands twice (interaction doc 3.4).
  ///
  /// [parentId] makes it a reply to that comment (top-level or a reply — the
  /// server flattens it onto the thread). [stickerId] attaches a sticker; with
  /// one, [text] may be empty.
  Future<CommentModel> postComment(
    String videoId,
    String text, {
    String? parentId,
    String? stickerId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/interactions/videos/$videoId/comments',
      data: {
        if (text.isNotEmpty) 'content': text,
        // Snowflake ids go up as numbers, the way the server sends them.
        if (parentId != null) 'parentId': int.tryParse(parentId) ?? parentId,
        'stickerId': ?stickerId,
      },
    );
    return CommentModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// The author's own comment only. Answers the updated comment, `editedAt`
  /// set. The new text is screened like a new comment: text the filters would
  /// hold is refused with `COMMENT_EDIT_NEEDS_REVIEW` and nothing changes.
  Future<CommentModel> editComment(
    String videoId,
    String commentId,
    String text,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/interactions/videos/$videoId/comments/$commentId',
      data: {'content': text},
    );
    return CommentModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// The sticker catalog chat-service serves; comments use the same stickers.
  Future<List<StickerPack>> listStickerPacks() async {
    final response =
        await _apiClient.get<Map<String, dynamic>>('/conversations/stickers');
    return (response.data!['data'] as List)
        .map((e) => StickerPack.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Idempotent, like a video like: liking twice leaves the tally alone.
  Future<CommentLikeResult> likeComment(String videoId, String commentId) =>
      _toggleLike('POST', videoId, commentId);

  Future<CommentLikeResult> unlikeComment(String videoId, String commentId) =>
      _toggleLike('DELETE', videoId, commentId);

  Future<CommentLikeResult> _toggleLike(
    String method,
    String videoId,
    String commentId,
  ) async {
    final path = '/interactions/videos/$videoId/comments/$commentId/like';
    final response = method == 'POST'
        ? await _apiClient.post<Map<String, dynamic>>(path)
        : await _apiClient.delete<Map<String, dynamic>>(path);
    final body = response.data!['data'] as Map<String, dynamic>;
    return CommentLikeResult(
      liked: body['liked'] as bool,
      likeCount: body['likeCount'] as int,
    );
  }

  /// The author's own comment, or any comment on a video the caller owns —
  /// anything else answers `NOT_COMMENT_OWNER`. `videoId` is part of the key,
  /// not decoration — a mismatched pair answers `COMMENT_NOT_FOUND`
  /// (interaction doc 3.6).
  Future<void> deleteComment(String videoId, String commentId) {
    return _apiClient
        .delete<void>('/interactions/videos/$videoId/comments/$commentId');
  }

  /// Admin only (ROLE_ADMIN, else 403). Goes through admin-service so the
  /// removal is audited with its [reason] and counted as a strike against the
  /// author; interaction-service deletes the comment when the event arrives.
  Future<void> removeCommentAsAdmin(
    String videoId,
    String commentId,
    String reason,
  ) {
    return _apiClient.post<void>(
      '/admin/comments/$videoId/$commentId/remove',
      data: {'reason': reason},
    );
  }

  /// Open to any signed-in user. A comment is identified by the
  /// `videoId:commentId` pair — the comment id alone reaches nothing. Reporting
  /// the same comment again while the first report is pending answers with that
  /// report rather than an error.
  Future<void> reportComment(String videoId, String commentId, String reason) {
    return _apiClient.post<void>(
      '/admin/reports',
      data: {
        'targetType': 'COMMENT',
        'targetId': '$videoId:$commentId',
        'reason': reason,
      },
    );
  }
}
