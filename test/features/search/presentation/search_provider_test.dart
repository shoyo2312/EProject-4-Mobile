import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/search/data/search_remote_datasource.dart';
import 'package:tiktok_mobile/features/search/data/search_repository.dart';
import 'package:tiktok_mobile/features/search/presentation/search_provider.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

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

void main() {
  late MockSearchRepository searchRepository;
  late MockFeedRepository feedRepository;
  late ProviderContainer container;

  setUp(() {
    searchRepository = MockSearchRepository();
    feedRepository = MockFeedRepository();
    container = ProviderContainer(overrides: [
      searchRepositoryProvider.overrideWithValue(searchRepository),
      feedRepositoryProvider.overrideWithValue(feedRepository),
    ]);
    addTearDown(container.dispose);
  });

  test('hydrates search hits through video-service, keeping relevance order',
      () async {
    when(() => searchRepository.searchVideos(
          query: 'dance',
          hashtag: null,
          page: 0,
          size: any(named: 'size'),
        )).thenAnswer((_) async => const SearchIdPage(
          ids: ['v9', 'v2'],
          last: true,
        ));
    // Hydration answers in the order asked, and that order is the ranking.
    when(() => feedRepository.fetchByIds(['v9', 'v2']))
        .thenAnswer((_) async => [makeVideo('v9'), makeVideo('v2')]);

    final videos =
        await container.read(searchResultsProvider('dance', '').future);

    expect(videos.map((v) => v.id), ['v9', 'v2']);
  });

  test('a hashtag chip searches without a free-text query', () async {
    when(() => searchRepository.searchVideos(
          query: null,
          hashtag: 'cats',
          page: 0,
          size: any(named: 'size'),
        )).thenAnswer((_) async => const SearchIdPage(ids: ['v1'], last: true));
    when(() => feedRepository.fetchByIds(['v1']))
        .thenAnswer((_) async => [makeVideo('v1')]);

    final videos =
        await container.read(searchResultsProvider('', 'cats').future);

    expect(videos.map((v) => v.id), ['v1']);
  });

  test('an empty query asks search-service nothing at all', () async {
    final videos = await container.read(searchResultsProvider('', '').future);

    expect(videos, isEmpty);
    verifyNever(() => searchRepository.searchVideos(
          query: any(named: 'query'),
          hashtag: any(named: 'hashtag'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ));
  });

  test('loadMore appends the next page and stops on the last one', () async {
    when(() => searchRepository.searchVideos(
          query: 'dance',
          hashtag: null,
          page: 0,
          size: any(named: 'size'),
        )).thenAnswer((_) async => const SearchIdPage(ids: ['v1'], last: false));
    when(() => searchRepository.searchVideos(
          query: 'dance',
          hashtag: null,
          page: 1,
          size: any(named: 'size'),
        )).thenAnswer((_) async => const SearchIdPage(ids: ['v2'], last: true));
    when(() => feedRepository.fetchByIds(['v1']))
        .thenAnswer((_) async => [makeVideo('v1')]);
    when(() => feedRepository.fetchByIds(['v2']))
        .thenAnswer((_) async => [makeVideo('v2')]);

    await container.read(searchResultsProvider('dance', '').future);
    final notifier =
        container.read(searchResultsProvider('dance', '').notifier);
    await notifier.loadMore();

    expect(container.read(searchResultsProvider('dance', '')).value!
        .map((v) => v.id), ['v1', 'v2']);

    // The last page closes the guard: scrolling on must not re-ask page 2.
    await notifier.loadMore();
    verifyNever(() => searchRepository.searchVideos(
          query: 'dance',
          hashtag: null,
          page: 2,
          size: any(named: 'size'),
        ));
  });

  test('a page whose ids all vanished is not the end of the results',
      () async {
    // Search hits can be deleted between indexing and hydration; video-service
    // drops them, so a page can come back holding nothing while pages remain.
    when(() => searchRepository.searchVideos(
          query: 'dance',
          hashtag: null,
          page: 0,
          size: any(named: 'size'),
        )).thenAnswer((_) async => const SearchIdPage(ids: ['gone'], last: false));
    when(() => searchRepository.searchVideos(
          query: 'dance',
          hashtag: null,
          page: 1,
          size: any(named: 'size'),
        )).thenAnswer((_) async => const SearchIdPage(ids: ['v2'], last: true));
    when(() => feedRepository.fetchByIds(['gone']))
        .thenAnswer((_) async => <VideoModel>[]);
    when(() => feedRepository.fetchByIds(['v2']))
        .thenAnswer((_) async => [makeVideo('v2')]);

    final first =
        await container.read(searchResultsProvider('dance', '').future);
    expect(first, isEmpty);

    await container.read(searchResultsProvider('dance', '').notifier).loadMore();

    expect(
      container.read(searchResultsProvider('dance', '')).value!.map((v) => v.id),
      ['v2'],
    );
  });

  test('trending is one hydrated leaderboard, best first', () async {
    when(() => feedRepository.fetchTrending(limit: any(named: 'limit')))
        .thenAnswer((_) async => [makeVideo('hot'), makeVideo('warm')]);

    final videos = await container.read(trendingVideosProvider.future);

    expect(videos.map((v) => v.id), ['hot', 'warm']);
  });
}
