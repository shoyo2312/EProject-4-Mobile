import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository feedRepository;
  late ProviderContainer container;

  VideoModel makeVideo(String id) => VideoModel(
        id: id,
        url: 'https://example.com/$id.mp4',
        thumbnailUrl: 'https://example.com/$id.jpg',
        caption: 'caption $id',
        username: 'jane',
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isLiked: false,
        isSaved: false,
      );

  setUp(() {
    feedRepository = MockFeedRepository();
    container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(feedRepository)],
    );
  });

  tearDown(() => container.dispose());

  test('build() loads the first page', () async {
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => FeedPage(items: [makeVideo('v1')], nextCursor: 'c2'),
    );

    final result = await container.read(feedNotifierProvider.future);

    expect(result.map((v) => v.id), ['v1']);
  });

  test('loadMore() appends the next page using the stored cursor', () async {
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => FeedPage(items: [makeVideo('v1')], nextCursor: 'c2'),
    );
    when(() => feedRepository.fetchFeed(cursor: 'c2')).thenAnswer(
      (_) async => FeedPage(items: [makeVideo('v2')], nextCursor: null),
    );
    await container.read(feedNotifierProvider.future);

    await container.read(feedNotifierProvider.notifier).loadMore();

    final result = container.read(feedNotifierProvider).value!;
    expect(result.map((v) => v.id), ['v1', 'v2']);
  });

  test('toggleLike() replaces the updated video in place', () async {
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => FeedPage(items: [makeVideo('v1')], nextCursor: null),
    );
    await container.read(feedNotifierProvider.future);
    final liked = makeVideo('v1').copyWith(isLiked: true, likeCount: 1);
    when(() => feedRepository.toggleLike('v1')).thenAnswer((_) async => liked);

    await container.read(feedNotifierProvider.notifier).toggleLike('v1');

    final result = container.read(feedNotifierProvider).value!;
    expect(result.single.isLiked, isTrue);
    expect(result.single.likeCount, 1);
  });
}
