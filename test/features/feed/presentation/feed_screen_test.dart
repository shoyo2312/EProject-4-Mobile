import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  testWidgets('renders caption and like count for the first video', (tester) async {
    final feedRepository = MockFeedRepository();
    const video = VideoModel(
      id: 'v1',
      url: 'https://example.com/v1.mp4',
      thumbnailUrl: 'https://example.com/v1.jpg',
      caption: 'hello world',
      username: 'jane',
      likeCount: 5,
      commentCount: 0,
      shareCount: 0,
      isLiked: false,
      isSaved: false,
    );
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => const FeedPage(items: [video], nextCursor: null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedRepositoryProvider.overrideWithValue(feedRepository)],
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('hello world'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('tapping like calls toggleLike on the repository', (tester) async {
    final feedRepository = MockFeedRepository();
    const video = VideoModel(
      id: 'v1',
      url: 'https://example.com/v1.mp4',
      thumbnailUrl: 'https://example.com/v1.jpg',
      caption: 'hello world',
      username: 'jane',
      likeCount: 5,
      commentCount: 0,
      shareCount: 0,
      isLiked: false,
      isSaved: false,
    );
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => const FeedPage(items: [video], nextCursor: null),
    );
    when(() => feedRepository.toggleLike('v1')).thenAnswer(
      (_) async => video.copyWith(isLiked: true, likeCount: 6),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedRepositoryProvider.overrideWithValue(feedRepository)],
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('feed_like_button_v1')));
    await tester.pump();

    verify(() => feedRepository.toggleLike('v1')).called(1);
  });
}
