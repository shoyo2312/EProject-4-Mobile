import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

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

VideoPage feedPage(List<String> ids, {String? nextCursor}) =>
    VideoPage(items: ids.map(makeVideo).toList(), nextCursor: nextCursor);

PageResponse<VideoModel> pageOf(
  List<String> ids, {
  required int number,
  required int totalPages,
}) =>
    PageResponse(
      content: ids.map(makeVideo).toList(),
      size: 20,
      number: number,
      totalElements: totalPages * 20,
      totalPages: totalPages,
    );

void main() {
  late MockFeedRepository feedRepository;
  late ProviderContainer container;

  setUp(() {
    feedRepository = MockFeedRepository();
    container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(feedRepository)],
    );
  });

  tearDown(() => container.dispose());

  test('build() loads the first page', () async {
    when(() => feedRepository.fetchFeed()).thenAnswer(
      (_) async => feedPage(['v1']),
    );

    final result = await container.read(feedNotifierProvider.future);

    expect(result.map((v) => v.id), ['v1']);
  });

  test('loadMore() drops videos already on screen', () async {
    // The cursor anchors on the last item, but a repeated id must still never
    // reach the list twice.
    when(() => feedRepository.fetchFeed()).thenAnswer(
      (_) async => feedPage(['v1', 'v2'], nextCursor: 'c1'),
    );
    when(() => feedRepository.fetchFeed(cursor: 'c1')).thenAnswer(
      (_) async => feedPage(['v2', 'v3']),
    );
    await container.read(feedNotifierProvider.future);

    await container.read(feedNotifierProvider.notifier).loadMore();

    final result = container.read(feedNotifierProvider).value!;
    expect(result.map((v) => v.id), ['v1', 'v2', 'v3']);
  });

  test('loadMore() stops once nextCursor comes back null', () async {
    when(() => feedRepository.fetchFeed()).thenAnswer(
      (_) async => feedPage(['v1']),
    );
    await container.read(feedNotifierProvider.future);

    await container.read(feedNotifierProvider.notifier).loadMore();

    // Only the initial load happened; loadMore made no second request.
    verify(() => feedRepository.fetchFeed()).called(1);
    verifyNoMoreInteractions(feedRepository);
  });

  test('deleting one of my videos removes it from the list', () async {
    when(() => feedRepository.getUserVideos('123')).thenAnswer(
      (_) async => pageOf(['v1', 'v2'], number: 0, totalPages: 1),
    );
    when(() => feedRepository.deleteVideo('v1')).thenAnswer((_) async {});
    await container.read(userVideosNotifierProvider('123').future);

    await container.read(userVideosNotifierProvider('123').notifier).delete('v1');

    final result = container.read(userVideosNotifierProvider('123')).value!;
    expect(result.map((v) => v.id), ['v2']);
  });
}
