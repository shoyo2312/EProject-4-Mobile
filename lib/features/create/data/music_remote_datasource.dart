import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/features/create/data/music_track.dart';

/// The editor's music catalogue (video doc 3.10). The catalogue itself is a
/// third party's; video-service holds its credentials and filters it to the
/// tracks a video may use, so the app only ever talks to our own API.
class MusicRemoteDatasource {
  MusicRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// [query] empty for the most popular tracks.
  Future<List<MusicTrack>> search({String query = '', int page = 0, int size = 20}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/music',
      queryParameters: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        'page': page,
        'size': size,
      },
    );
    return ApiResponse<List<MusicTrack>>.fromJson(
      response.data!,
      (json) => [
        for (final item in json as List) MusicTrack.fromJson(item as Map<String, dynamic>),
      ],
    ).data!;
  }
}
