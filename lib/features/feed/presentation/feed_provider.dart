import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

part 'feed_provider.g.dart';

@Riverpod(keepAlive: true)
FeedRepository feedRepository(Ref ref) =>
    FeedRepository(FeedRemoteDatasource(ref.watch(apiClientProvider)));

/// Appends [next] to [current], dropping ids already on screen.
///
/// `/videos/users/{userId}` is offset-paginated over a list that grows at the
/// front, so a video uploaded between two page loads pushes older rows down
/// and they come back a second time on the following page (video doc 2).
List<VideoModel> _appendDistinct(List<VideoModel> current, List<VideoModel> next) {
  final seen = current.map((v) => v.id).toSet();
  return [...current, ...next.where((v) => seen.add(v.id))];
}

/// How many rows a page asks for. Deliberately small on the ranked side: the
/// server treats everything it returns as served for the next 30 minutes, so
/// asking for more than will be scrolled through burns content nobody saw.
const _pageSize = 10;

@riverpod
class FeedNotifier extends _$FeedNotifier {
  String? _cursor;

  /// Set once recommendation-service has nothing left to give — it ran dry,
  /// or it is unreachable. One-way: the feed does not go back to asking.
  bool _rankingSpent = false;
  bool _chronologicalSpent = false;

  final _more = LoadMoreGuard();

  @override
  FutureOr<List<VideoModel>> build() async {
    // Ranking is per-account and 401s without a token, so a signed-out viewer
    // has only the chronological feed. Awaiting the session (rather than
    // reading whatever it holds right now) keeps a signed-in viewer off the
    // fallback just because `/me` had not answered yet.
    _rankingSpent = await ref.watch(authStateProvider.future) == null;
    _cursor = null;
    _chronologicalSpent = false;
    return _loadPage();
  }

  /// Resolves the authors of [videos] in one batched request before the page
  /// is handed to the UI, so each row finds its name and picture in the shared
  /// cache instead of firing its own `GET /users/{id}`.
  ///
  /// A failure here is swallowed on purpose: a feed that plays with placeholder
  /// avatars beats a feed that shows an error page.
  Future<List<VideoModel>> _withAuthors(List<VideoModel> videos) async {
    try {
      await ref
          .read(profileCacheProvider.notifier)
          .loadMissing(videos.map((v) => v.userId));
    } on AppException {
      // ignore — see above
    }
    return videos;
  }

  /// Ranked while there is a ranking, chronological after that. Both sources
  /// answering empty leaves the feed at its end rather than erroring.
  Future<List<VideoModel>> _loadPage() async {
    if (!_rankingSpent) {
      try {
        final ranked = await ref
            .read(feedRepositoryProvider)
            .fetchRankedFeed(limit: _pageSize);
        if (ranked.isNotEmpty) return _withAuthors(ranked);
      } on AppException {
        // recommendation-service being down must not take the feed with it.
      }
      _rankingSpent = true;
    }

    if (_chronologicalSpent) return [];
    final page = await ref
        .read(feedRepositoryProvider)
        .fetchFeed(cursor: _cursor, size: _pageSize);
    _cursor = page.nextCursor;
    _chronologicalSpent = page.nextCursor == null;
    return _withAuthors(page.items);
  }

  Future<void> loadMore() => _more.run(() async {
        var videos = state.value ?? [];

        // A page that adds no rows stalls the feed for good: the PageView does
        // not grow, so it never reaches the load trigger again. Both cases are
        // real — a ranked page whose ids all hydrate to videos already on
        // screen, and a chronological page of the same. Try a couple more
        // times before giving up on this scroll.
        for (var attempt = 0; attempt < 3; attempt++) {
          final before = videos.length;
          videos = _appendDistinct(videos, await _loadPage());
          _more.done = _rankingSpent && _chronologicalSpent;
          if (videos.length > before || _more.done) break;
        }

        state = AsyncData(videos);
      });
}

/// One user's videos. For the caller's own id the server also returns
/// PROCESSING, PRIVATE, FAILED and TAKEN_DOWN items — this backs "My videos".
@riverpod
class UserVideosNotifier extends _$UserVideosNotifier {
  int _page = 0;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<VideoModel>> build(String userId) async {
    final page = await ref.read(feedRepositoryProvider).getUserVideos(userId);
    _page = 0;
    _more.done = page.last;
    return page.content;
  }

  Future<void> loadMore() => _more.run(() async {
        final nextPage = _page + 1;
        final page = await ref
            .read(feedRepositoryProvider)
            .getUserVideos(userId, page: nextPage);
        _page = nextPage;
        _more.done = page.last;
        state = AsyncData(_appendDistinct(state.value ?? [], page.content));
      });

  /// Soft-delete, one-way: the video vanishes from every read endpoint at
  /// once and there is no restore API.
  Future<void> delete(String videoId) async {
    await ref.read(feedRepositoryProvider).deleteVideo(videoId);
    final current = state.value ?? [];
    state = AsyncData([
      for (final video in current)
        if (video.id != videoId) video,
    ]);
  }
}
