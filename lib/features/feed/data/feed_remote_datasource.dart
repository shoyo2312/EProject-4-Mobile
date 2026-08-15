import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

/// video-service (`/api/v1/videos`). GETs are public, but sending the token
/// anyway matters: without it the server treats the caller as a guest and
/// hides their own PRIVATE/PROCESSING videos with no error at all (video doc
/// 3.3/3.4). The ApiClient interceptor attaches it whenever one is stored.
class FeedRemoteDatasource {
  FeedRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// PUBLISHED + PUBLIC videos only, newest first. Ordering is fixed
  /// server-side, so there is no `sort` parameter to pass.
  Future<PageResponse<VideoModel>> fetchFeed({int page = 0, int size = 20}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/feed',
      queryParameters: {'page': page, 'size': size},
    );
    return _unwrapPage(response.data!);
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
