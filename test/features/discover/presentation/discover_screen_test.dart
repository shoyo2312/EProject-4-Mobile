import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/discover/presentation/discover_screen.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/search/data/search_remote_datasource.dart';
import 'package:tiktok_mobile/features/search/data/search_repository.dart';
import 'package:tiktok_mobile/features/search/presentation/search_provider.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

VideoModel makeVideo(String id, String title) => VideoModel(
      id: id,
      userId: '123',
      title: title,
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

  setUp(() {
    searchRepository = MockSearchRepository();
    feedRepository = MockFeedRepository();
    when(() => feedRepository.fetchTrending(limit: any(named: 'limit')))
        .thenAnswer((_) async => [makeVideo('t1', 'trending clip')]);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchRepositoryProvider.overrideWithValue(searchRepository),
          feedRepositoryProvider.overrideWithValue(feedRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: DiscoverScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the trending leaderboard before anything is typed',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('TRENDING NOW'), findsOneWidget);
    expect(find.text('trending clip'), findsWidgets);
    verifyNever(() => searchRepository.searchVideos(
          query: any(named: 'query'),
          hashtag: any(named: 'hashtag'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ));
  });

  testWidgets('typing searches once the keystrokes stop, not per letter',
      (tester) async {
    when(() => searchRepository.searchVideos(
          query: 'dance',
          hashtag: null,
          page: 0,
          size: any(named: 'size'),
        )).thenAnswer((_) async => const SearchIdPage(ids: ['v1'], last: true));
    when(() => feedRepository.fetchByIds(['v1']))
        .thenAnswer((_) async => [makeVideo('v1', 'dance result')]);

    await pumpScreen(tester);
    final field = find.byKey(const Key('discover_search_field'));
    await tester.enterText(field, 'dan');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(field, 'dance');
    // A pending Timer schedules no frame, so pumpAndSettle alone would return
    // before the debounce ever fires — the clock has to be pushed past it.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('RESULTS'), findsOneWidget);
    expect(find.text('dance result'), findsWidgets);
    // The half-typed word never left the device.
    verifyNever(() => searchRepository.searchVideos(
          query: 'dan',
          hashtag: any(named: 'hashtag'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ));
  });

  testWidgets('a chip searches by hashtag with no text typed', (tester) async {
    when(() => searchRepository.searchVideos(
          query: null,
          hashtag: 'cats',
          page: 0,
          size: any(named: 'size'),
        )).thenAnswer((_) async => const SearchIdPage(ids: ['v2'], last: true));
    when(() => feedRepository.fetchByIds(['v2']))
        .thenAnswer((_) async => [makeVideo('v2', 'cat result')]);

    await pumpScreen(tester);
    await tester.tap(find.text('Cats'));
    await tester.pumpAndSettle();

    expect(find.text('cat result'), findsWidgets);
    expect(find.text('TRENDING NOW'), findsNothing);
  });

  testWidgets('an empty result set says so instead of showing nothing',
      (tester) async {
    when(() => searchRepository.searchVideos(
          query: 'nope',
          hashtag: null,
          page: 0,
          size: any(named: 'size'),
        )).thenAnswer((_) async => const SearchIdPage(ids: [], last: true));
    when(() => feedRepository.fetchByIds(<String>[]))
        .thenAnswer((_) async => <VideoModel>[]);

    await pumpScreen(tester);
    await tester.enterText(
      find.byKey(const Key('discover_search_field')),
      'nope',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('No results for "nope"'), findsOneWidget);
  });
}
