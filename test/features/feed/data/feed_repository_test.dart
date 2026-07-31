import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class MockFeedRemoteDatasource extends Mock implements FeedRemoteDatasource {}

void main() {
  late MockFeedRemoteDatasource remoteDatasource;
  late FeedRepository repository;

  const video = VideoModel(
    id: 'v1',
    url: 'https://example.com/v1.mp4',
    thumbnailUrl: 'https://example.com/v1.jpg',
    caption: 'hello',
    username: 'jane',
    likeCount: 10,
    commentCount: 2,
    shareCount: 1,
    isLiked: false,
    isSaved: false,
  );

  setUp(() {
    remoteDatasource = MockFeedRemoteDatasource();
    repository = FeedRepository(remoteDatasource);
  });

  test('fetchFeed returns items and cursor from the datasource', () async {
    when(() => remoteDatasource.fetchFeed(cursor: null)).thenAnswer(
      (_) async => const FeedPage(items: [video], nextCursor: 'cursor2'),
    );

    final result = await repository.fetchFeed();

    expect(result.items, [video]);
    expect(result.nextCursor, 'cursor2');
  });

  test('fetchFeed converts a DioException into an AppException', () async {
    when(() => remoteDatasource.fetchFeed(cursor: null)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/feed'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repository.fetchFeed(), throwsA(isA<NetworkException>()));
  });

  test('toggleLike returns the updated video', () async {
    final liked = video.copyWith(isLiked: true, likeCount: 11);
    when(() => remoteDatasource.toggleLike('v1')).thenAnswer((_) async => liked);

    final result = await repository.toggleLike('v1');

    expect(result, liked);
  });
}
