import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';

/// Nowa Studio: the signed-in creator's own numbers and content. None of these
/// takes a user id — they always answer about the caller — so all need the
/// token (backend `docs/tiktok-studio-api.md`).
///
/// `days` is the window Studio's picker offers (7, 28, 60, 365): calendar days
/// in Vietnam's zone ending today, today included. The server takes 1–365.
class StudioRemoteDatasource {
  StudioRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<CreatorOverview> getOverview(int days) async {
    final data = await _get('/analytics/creator/overview', {'days': days});
    return CreatorOverview.fromJson(data as Map<String, dynamic>);
  }

  /// Only videos with activity in the window, ranked by [sort].
  Future<List<CreatorVideoStats>> getTopVideos(
    int days,
    CreatorVideoSort sort, {
    int limit = 10,
  }) async {
    final data = await _get('/analytics/creator/videos/top', {
      'days': days,
      'sort': sort.wire,
      'limit': limit,
    });
    return (data as List)
        .map((e) => CreatorVideoStats.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `VIDEO_NOT_FOUND` (404) for anyone else's video, on purpose: a 403 would
  /// confirm the id exists.
  Future<CreatorVideoDetail> getVideoDetail(String videoId, int days) async {
    final data =
        await _get('/analytics/creator/videos/$videoId', {'days': days});
    return CreatorVideoDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<CreatorViewers> getViewers(int days) async {
    final data = await _get('/analytics/creator/viewers', {'days': days});
    return CreatorViewers.fromJson(data as Map<String, dynamic>);
  }

  /// The Posts list: the caller's own videos in every status but deleted,
  /// offset paged. List filters go up comma-separated, which Spring binds to a
  /// list parameter.
  Future<PageResponse<VideoModel>> listMyVideos(
    StudioPostQuery query, {
    int page = 0,
    int size = 20,
  }) async {
    final q = query.q.trim();
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/me',
      queryParameters: {
        'status': ?_csv(query.statuses),
        'visibility': ?_csv(query.visibilities),
        'views': ?_csv([for (final r in query.views) r.wire]),
        'q': ?(q.isEmpty ? null : q),
        'sort': query.sort.wire,
        'order': query.descending ? 'DESC' : 'ASC',
        'page': page,
        'size': size,
      },
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(data, VideoModel.fromJson);
  }

  /// Owner only. The text is screened like a new upload's: 422
  /// `VIDEO_*_REJECTED` or `VIDEO_CAPTION_HELD` when refused.
  Future<VideoModel> updateCaption(
    String videoId, {
    required String title,
    String? description,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/videos/$videoId/caption',
      data: {'title': title, 'description': description ?? ''},
    );
    return VideoModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Owner only. 409 `PIN_LIMIT_REACHED` past three pinned videos.
  Future<VideoModel> setPinned(String videoId, bool pinned) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/videos/$videoId/pin',
      data: {'pinned': pinned},
    );
    return VideoModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// What others said on any of the caller's videos, newest first by default.
  ///
  /// A filtered page can come back short, or empty, with `hasMore` still true:
  /// keep following the cursor.
  Future<CommentPage> listInbox(
    InboxQuery query, {
    String? cursor,
    int size = 20,
  }) async {
    final q = query.q.trim();
    final byVideo = query.videoId != null;
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/interactions/users/me/comments',
      queryParameters: {
        'videoId': ?query.videoId,
        'status': ?(query.heldOnly ? 'HELD' : null),
        'q': ?(q.isEmpty ? null : q),
        // The server only ranks or filters by reply within one video.
        if (byVideo && query.sort != InboxSort.newest) 'sort': query.sort.wire,
        if (byVideo) 'replied': ?query.replied,
        'cursor': ?cursor,
        'size': size,
      },
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    return CommentPage(
      items: (body['items'] as List)
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: body['hasMore'] as bool? ?? false,
      nextCursor: body['nextCursor'] as String?,
    );
  }

  /// Publishes a comment the filters held back. Owner of the video only.
  Future<void> approveComment(String videoId, String commentId) {
    return _apiClient.post<void>(
      '/interactions/videos/$videoId/comments/$commentId/approve',
    );
  }

  Future<Object?> _get(String path, Map<String, dynamic> query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return response.data!['data'];
  }

  static String? _csv(List<String> values) =>
      values.isEmpty ? null : values.join(',');
}
