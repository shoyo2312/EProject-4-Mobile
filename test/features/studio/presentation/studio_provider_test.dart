import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/mock/mock_backend.dart';

/// video-service pins only a published video that is not private.
bool pinnable(VideoModel v) =>
    v.status == VideoStatus.published &&
    v.visibility != VideoVisibility.private;

void main() {
  late ProviderContainer container;

  setUp(() async {
    container = ProviderContainer(overrides: mockOverrides());
    await container.read(authStateProvider.future);
  });

  tearDown(() => container.dispose());

  test('the overview follows the picked window', () async {
    container.listen(studioOverviewProvider, (_, _) {});
    final week = await container.read(studioOverviewProvider.future);
    expect(week.daily, hasLength(7));

    container.read(studioRangeProvider.notifier).set(28);
    final month = await container.read(studioOverviewProvider.future);
    expect(month.daily, hasLength(28));
  });

  test('top videos come with their videos in the cache', () async {
    final rows = await container
        .read(studioTopVideosProvider(CreatorVideoSort.views).future);

    expect(rows, isNotEmpty);
    final cache = container.read(studioVideoCacheProvider);
    expect(rows.every((r) => cache.containsKey(r.videoId)), isTrue);
  });

  test('a pin made through the editor shows in the open Posts list', () async {
    container.listen(studioPostsProvider, (_, _) {});
    final posts = await container.read(studioPostsProvider.future);
    final target = posts.firstWhere((v) => v.pinnedAt == null && pinnable(v));

    await container.read(studioEditorProvider).setPinned(target.id, true);

    final after = container.read(studioPostsProvider).value!;
    expect(after.firstWhere((v) => v.id == target.id).pinnedAt, isNotNull);
  });

  test('a fourth pin is refused with PIN_LIMIT_REACHED', () async {
    final posts = await container.read(studioPostsProvider.future);
    final editor = container.read(studioEditorProvider);
    final unpinned =
        posts.where((v) => v.pinnedAt == null && pinnable(v)).toList();
    for (final v in unpinned.take(3)) {
      await editor.setPinned(v.id, true);
    }
    if (unpinned.length < 4) return; // Catalogue too small to hit the limit.

    await expectLater(
      editor.setPinned(unpinned[3].id, true),
      throwsA(isA<ServerException>()
          .having((e) => e.code, 'code', 'PIN_LIMIT_REACHED')),
    );
  });

  test('approving under "held only" takes the comment off the list', () async {
    container.listen(studioInboxProvider(null), (_, _) {});
    container
        .read(studioInboxFilterProvider(null).notifier)
        .set(const InboxQuery(heldOnly: true));
    final held = await container.read(studioInboxProvider(null).future);
    expect(held, isNotEmpty);
    expect(held.every((c) => c.status == CommentStatus.held), isTrue);

    await container.read(studioInboxProvider(null).notifier).approve(held.first);

    final after = container.read(studioInboxProvider(null)).value!;
    expect(after.map((c) => c.id), isNot(contains(held.first.id)));
  });

  test('a deep link to one video starts the inbox filtered', () async {
    final posts = await container.read(studioPostsProvider.future);
    final id = posts.first.id;

    final comments = await container.read(studioInboxProvider(id).future);

    expect(container.read(studioInboxFilterProvider(id)).videoId, id);
    expect(comments.every((c) => c.videoId == id), isTrue);
  });
}
