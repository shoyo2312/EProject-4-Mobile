import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';

class CommentPage {
  const CommentPage({required this.items, this.nextCursor});

  final List<CommentModel> items;
  final String? nextCursor;
}

class CommentRemoteDatasource {
  CommentRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<CommentPage> fetchComments(String videoId, {String? cursor}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/$videoId/comments',
      queryParameters: {
        'cursor': ?cursor,
        'limit': 20,
      },
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CommentPage(items: items, nextCursor: body['nextCursor'] as String?);
  }

  Future<CommentModel> postComment(String videoId, String text) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/videos/$videoId/comments',
      data: {'text': text},
    );
    return CommentModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
