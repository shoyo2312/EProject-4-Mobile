import 'package:tiktok_mobile/core/network/api_client.dart';
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

  Future<CommentPage> fetchComments(String videoId, {String? cursor}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/interactions/videos/$videoId/comments',
      queryParameters: {
        'cursor': ?cursor,
        'size': 20,
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
  Future<CommentModel> postComment(String videoId, String text) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/interactions/videos/$videoId/comments',
      data: {'content': text},
    );
    return CommentModel.fromJson(response.data!['data'] as Map<String, dynamic>);
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

  /// Own comments only; the video owner cannot remove other people's.
  /// `videoId` is part of the key, not decoration — a mismatched pair answers
  /// `COMMENT_NOT_FOUND` (interaction doc 3.6).
  Future<void> deleteComment(String videoId, String commentId) {
    return _apiClient
        .delete<void>('/interactions/videos/$videoId/comments/$commentId');
  }
}
