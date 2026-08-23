import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

/// One `/feed` page. Cursor pagination: [nextCursor] is an opaque server
/// string — pass it back verbatim, never parse or display it. `null` means the
/// feed is exhausted; that is the only stop condition (video doc 3.2).
class VideoPage {
  const VideoPage({required this.items, this.nextCursor});

  final List<VideoModel> items;
  final String? nextCursor;
}

/// video-service (`/api/v1/videos`). GETs are public, but sending the token
/// anyway matters: without it the server treats the caller as a guest and
/// hides their own PRIVATE/PROCESSING videos with no error at all (video doc
/// 3.3/3.4). The ApiClient interceptor attaches it whenever one is stored.
class FeedRemoteDatasource {
  FeedRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// PUBLISHED + PUBLIC videos only, newest first. Ordering is fixed
  /// server-side, so there is no `sort` parameter to pass. Unlike
  /// [getUserVideos] this is cursor-paginated: no `page`/`totalPages`.
  Future<VideoPage> fetchFeed({String? cursor, int size = 20}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/feed',
      queryParameters: {'cursor': ?cursor, 'size': size},
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return VideoPage(items: items, nextCursor: body['nextCursor'] as String?);
  }

  /// One ranked page from recommendation-service, as ids only: it is not
  /// allowed to read video-service's data, so it never returns anything
  /// showable (recommendation doc 4). **The order is the ranking** — keep it.
  ///
  /// There is no cursor. The server remembers what it just handed this user
  /// for 30 minutes and leaves it out of the next answer, so asking again *is*
  /// the next page. Ask for what will actually be shown: anything returned
  /// counts as spent even if the viewer never saw it (doc 7).
  ///
  /// An empty list is a normal answer — a cold system, or a user who has been
  /// served everything the window holds — not an error.
  Future<List<String>> fetchRankedIds({int limit = 10}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/recommendations/feed',
      queryParameters: {'limit': limit},
    );
    return (response.data!['data'] as List)
        .map((e) => (e as Map<String, dynamic>)['videoId'].toString())
        .toList();
  }

  /// Hydrates a whole ranked page in one request, answering in the order
  /// asked. Twenty single `/videos/{id}` calls would spend the gateway's
  /// entire 20 req/s per-IP budget on one scroll — and that budget is shared
  /// with every other call the app makes.
  ///
  /// Ids that no longer resolve are simply absent from the result: a video
  /// deleted between ranking and hydration is the normal case, so the list
  /// coming back shorter is not an error (video doc 3.4b).
  Future<List<VideoModel>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/batch',
      queryParameters: {'ids': ids.join(',')},
    );
    return (response.data!['data'] as List)
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Every non-deleted video when [userId] is the caller's own — PROCESSING,
  /// PRIVATE, FAILED and TAKEN_DOWN included; only PUBLISHED + PUBLIC for
  /// anyone else. An unknown userId yields an empty page, not a 404.
  Future<PageResponse<VideoModel>> getUserVideos(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/users/$userId',
      queryParameters: {'page': page, 'size': size},
    );
    return _unwrapPage(response.data!);
  }

  Future<VideoModel> getVideo(String videoId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/videos/$videoId');
    final envelope = ApiResponse<VideoModel>.fromJson(
      response.data!,
      (json) => VideoModel.fromJson(json as Map<String, dynamic>),
    );
    return envelope.data!;
  }

  Future<void> deleteVideo(String videoId) {
    return _apiClient.delete<void>('/videos/$videoId');
  }

  PageResponse<VideoModel> _unwrapPage(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(data, VideoModel.fromJson);
  }
}
