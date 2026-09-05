import 'package:tiktok_mobile/core/network/api_client.dart';

/// One `/search/videos` page, as ids only.
///
/// A search hit carries no `hlsUrl`, so nothing here is playable on its own
/// (search doc 4): the caller hydrates these ids through
/// `GET /videos/batch` and shows the result **in the order given here**, which
/// is Elasticsearch's relevance order.
class SearchIdPage {
  const SearchIdPage({required this.ids, required this.last});

  final List<String> ids;

  /// The only valid stop condition for infinite scroll — a page can come back
  /// shorter than asked without being the last one.
  final bool last;
}

/// search-service (`/api/v1/search`). Every endpoint is public; sending a
/// token changes nothing, and the service cannot tell who is calling, so a
/// caller's own PRIVATE videos never appear here (search doc 3.1).
class SearchRemoteDatasource {
  SearchRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// PUBLISHED videos matching [query] (title, description **and** tags) and
  /// [hashtag] (exact tag, server-normalised). The two are ANDed; passing
  /// neither returns the whole catalogue, which is rarely what a caller wants.
  ///
  /// Offset-paginated in Spring's raw `Page` shape — `content`/`number`/
  /// `totalPages` sit at the top level, not under a `page` object like
  /// user-service and video-service (search doc 2), so [PageResponse] does not
  /// fit and the two fields that matter are read directly.
  Future<SearchIdPage> searchVideos({
    String? query,
    String? hashtag,
    int page = 0,
    int size = 24,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/search/videos',
      queryParameters: {
        'q': ?query,
        'hashtag': ?hashtag,
        'page': page,
        'size': size,
      },
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    // Snowflake ids stay strings: 19 digits overflow a JS double on Flutter
    // Web, silently (search doc 4).
    final ids = [
      for (final hit in body['content'] as List)
        (hit as Map<String, dynamic>)['id'].toString(),
    ];
    final number = body['number'] as int;
    final totalPages = body['totalPages'] as int;
    return SearchIdPage(ids: ids, last: number + 1 >= totalPages);
  }
}
