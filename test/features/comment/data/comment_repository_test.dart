import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';

class MockCommentRemoteDatasource extends Mock implements CommentRemoteDatasource {}

void main() {
  late MockCommentRemoteDatasource remoteDatasource;
  late CommentRepository repository;

  final comment = CommentModel(
    id: 'c1',
    videoId: 'v1',
    userId: 'u1',
    username: 'jane',
    text: 'nice video!',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    remoteDatasource = MockCommentRemoteDatasource();
    repository = CommentRepository(remoteDatasource);
  });

  test('fetchComments returns items and cursor', () async {
    when(() => remoteDatasource.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [comment], nextCursor: null),
    );

    final result = await repository.fetchComments('v1');

    expect(result.items, [comment]);
  });

  test('postComment converts a DioException into an AppException', () async {
    when(() => remoteDatasource.postComment('v1', '')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/videos/v1/comments'),
        response: Response(
          requestOptions: RequestOptions(path: '/videos/v1/comments'),
          statusCode: 500,
          data: {'error': {'message': 'empty comment'}},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(() => repository.postComment('v1', ''), throwsA(isA<ServerException>()));
  });
}
