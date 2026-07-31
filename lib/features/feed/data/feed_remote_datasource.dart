import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class FeedPage {
  const FeedPage({required this.items, this.nextCursor});

  final List<VideoModel> items;
  final String? nextCursor;
}

class FeedRemoteDatasource {
  FeedRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<FeedPage> fetchFeed({String? cursor}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/feed',
      queryParameters: {
        'cursor': ?cursor,
        'limit': 10,
      },
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return FeedPage(items: items, nextCursor: body['nextCursor'] as String?);
  }

  Future<VideoModel> toggleLike(String videoId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/videos/$videoId/like',
    );
    return VideoModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<VideoModel> toggleSave(String videoId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/videos/$videoId/save',
    );
    return VideoModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
