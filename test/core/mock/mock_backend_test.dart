import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/mock/mock_backend.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: mockOverrides());
    addTearDown(container.dispose);
  });

  test('the feed serves thirteen playable videos', () async {
    final page = await container.read(feedRepositoryProvider).fetchFeed();
    expect(page.content, hasLength(13));
    expect(page.content.every((v) => v.hlsUrl != null), isTrue);
    // Every video is worth opening the comment sheet on.
    expect(
      page.content.every((v) => v.commentCount >= 200 && v.commentCount <= 10000),
      isTrue,
    );
    // The rail shows a number rather than a bare verb for save and share.
    expect(page.content.every((v) => v.saveCount > 0 && v.shareCount > 0), isTrue);
  });

  test('comments page by cursor up to the video total, with reply threads',
      () async {
    final repository = container.read(commentRepositoryProvider);
    final videos =
        (await container.read(feedRepositoryProvider).fetchFeed()).content;
    final video = videos.first;

    final first = await repository.fetchComments(video.id);
    expect(first.items, hasLength(20));
    expect(first.nextCursor, '20');
    expect(first.items.where((c) => c.replyCount > 0), isNotEmpty);
    // Threads are one level deep and only partially loaded.
    for (final comment in first.items.where((c) => c.replyCount > 0)) {
      expect(comment.replies.length, lessThanOrEqualTo(comment.replyCount));
      expect(comment.replies.every((r) => r.replies.isEmpty), isTrue);
    }

    // The same cursor yields the same page — paging back is stable.
    final again = await repository.fetchComments(video.id);
    expect(again.items.map((c) => c.id), first.items.map((c) => c.id));

    // The last page stops instead of looping forever.
    final lastOffset = video.commentCount - video.commentCount % 20;
    final last = await repository.fetchComments(video.id, cursor: '$lastOffset');
    expect(last.nextCursor, isNull);
    expect(last.items, hasLength(video.commentCount - lastOffset));
  });
}
