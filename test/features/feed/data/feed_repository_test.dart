import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class MockFeedRemoteDatasource extends Mock implements FeedRemoteDatasource {}

VideoModel makeVideo(String id) => VideoModel(
      id: id,
      userId: '123',
      title: 'title $id',
      hlsUrl: 'https://cdn.test/$id.m3u8',
      status: VideoStatus.published,
      visibility: VideoVisibility.public,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime(2026, 8, 12),
    );

void main() {
  late MockFeedRemoteDatasource remoteDatasource;
  late FeedRepository repository;

  setUp(() {
    remoteDatasource = MockFeedRemoteDatasource();
    repository = FeedRepository(remoteDatasource);
  });

  test('fetchFeed passes the page through from the datasource', () async {
    final page = PageResponse<VideoModel>(
      content: [makeVideo('v1')],
      size: 20,
      number: 0,
      totalElements: 1,
      totalPages: 1,
    );
    when(() => remoteDatasource.fetchFeed(page: 0, size: 20))
        .thenAnswer((_) async => page);

    final result = await repository.fetchFeed();

    expect(result.content.map((v) => v.id), ['v1']);
    expect(result.last, isTrue);
  });

  test('fetchFeed converts a DioException into an AppException', () async {
    when(() => remoteDatasource.fetchFeed(page: 0, size: 20)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/videos/feed'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repository.fetchFeed(), throwsA(isA<NetworkException>()));
  });

  test('deleteVideo surfaces NOT_VIDEO_OWNER as a ServerException', () async {
    when(() => remoteDatasource.deleteVideo('v1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/videos/v1'),
        response: Response(
          requestOptions: RequestOptions(path: '/videos/v1'),
          statusCode: 403,
          data: {'success': false, 'code': 'NOT_VIDEO_OWNER', 'message': 'nope'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.deleteVideo('v1'),
      throwsA(
        isA<ServerException>().having((e) => e.code, 'code', 'NOT_VIDEO_OWNER'),
      ),
    );
  });
}
