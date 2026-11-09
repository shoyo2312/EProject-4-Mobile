import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/interaction/presentation/interaction_provider.dart';
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
List<VideoModel> _appendDistinct(
  List<VideoModel> current,
  List<VideoModel> next,
) {
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

  /// Both the ranked feed and the batched like-status read need a token.
  bool _signedIn = false;

  final _more = LoadMoreGuard();

  @override
  FutureOr<List<VideoModel>> build() async {
    // Ranking is per-account and 401s without a token, so a signed-out viewer
    // has only the chronological feed. Awaiting the session (rather than
    // reading whatever it holds right now) keeps a signed-in viewer off the
    // fallback just because `/me` had not answered yet.
    _signedIn = await ref.watch(authStateProvider.future) != null;
    _rankingSpent = !_signedIn;
    _cursor = null;
    _chronologicalSpent = false;
    return _loadPage();
  }

  /// Resolves the authors and the caller's own hearts for [videos] in one
  /// batched request each before the page is handed to the UI, so a row finds
  /// both in a shared cache instead of firing its own `GET /users/{id}` and
  /// `GET /like-status`. Twenty cards' worth of those would spend the gateway's
  /// whole 20 req/s per-IP budget on one scroll.
  ///
  /// Failures here are swallowed on purpose: a feed that plays with placeholder
  /// avatars and unfilled hearts beats a feed that shows an error page. The
  /// per-video providers fall back to their own single-video reads.
  Future<List<VideoModel>> _hydrate(List<VideoModel> videos) async {
    try {
      await ref
          .read(profileCacheProvider.notifier)
          .loadMissing(videos.map((v) => v.userId));
    } on AppException {
      // ignore — see above
    }
    // Skipped entirely for a guest: the batch endpoint needs a token, and every
    // row would come back `liked: false` anyway.
    if (_signedIn) {
      try {
        await ref
            .read(likeStatusCacheProvider.notifier)
            .loadMissing(videos.map((v) => v.id));
      } on AppException {
        // ignore — see above
      }
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
        if (ranked.isNotEmpty) return _hydrate(ranked);
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
    return _hydrate(page.items);
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

  /// Drops a video that was deleted while the feed was open.
  void remove(String videoId) => state = AsyncData(_without(state, videoId));
}

List<VideoModel> _without(AsyncValue<List<VideoModel>> state, String id) => [
  for (final video in state.value ?? <VideoModel>[])
    if (video.id != id) video,
];

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

  /// Owner-only, and answered with the updated video — the row is replaced
  /// from the response rather than patched locally, so a field the server
  /// changed alongside the one asked for cannot drift.
  Future<void> setVisibility(String videoId, VideoVisibility visibility) =>
      _replace((repo) => repo.updateVisibility(videoId, visibility));

  Future<void> setCommentsDisabled(String videoId, bool disabled) =>
      _replace((repo) => repo.updateCommentsDisabled(videoId, disabled));

  /// A pin moves the row: the server lists pinned videos first, newest pin
  /// on top, then the rest newest first. The loaded rows are re-sorted the
  /// same way, so the grid matches what a reload would show.
  Future<void> setPinned(String videoId, bool pinned) =>
      _replace((repo) => repo.setPinned(videoId, pinned));

  Future<void> _replace(
    Future<VideoModel> Function(FeedRepository repo) edit,
  ) async => replace(await edit(ref.read(feedRepositoryProvider)));

  /// Swaps in a copy the server answered with, wherever the edit was made.
  /// Re-sorted with pinned rows first, so the grid matches a reload.
  void replace(VideoModel updated) {
    state = AsyncData(
      pinnedFirst([
        for (final video in state.value ?? <VideoModel>[])
          if (video.id == updated.id) updated else video,
      ]),
    );
  }

  /// A row deleted somewhere else, dropped without asking the server again.
  void remove(String videoId) => state = AsyncData(_without(state, videoId));

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

/// How many accounts the Following tab draws from. video-service has no follow
/// graph, so every id travels in the query string — this is the point past
/// which that string stops being reasonable, not a limit the server imposes.
const _followedIdLimit = 100;

/// Paging shared by the Following and Friends tabs. Both read
/// `/videos/feed/following`; only the author list differs.
///
/// Two services, one list — user-service knows who is followed, video-service
/// knows what they posted — so the author list is read once per session here
/// rather than on every page.
mixin _AuthorFeed on AutoDisposeAsyncNotifier<List<VideoModel>> {
  String? _cursor;
  List<String> _authorIds = const [];
  final _more = LoadMoreGuard();

  /// `FOLLOWING` or `FRIENDS` — picks the tab's keyword filters server-side.
  String get _feedKind;

  Future<List<String>> _resolveAuthors(String viewerId);

  Future<List<VideoModel>> _start() async {
    final me = await ref.watch(authStateProvider.future);
    // Signed out there is no follow graph to read, and the tab has nothing to
    // show rather than an error to raise.
    if (me == null) {
      _more.done = true;
      return [];
    }
    _cursor = null;
    _authorIds = await _resolveAuthors(me.id);
    if (_authorIds.isEmpty) {
      _more.done = true;
      return [];
    }
    return _loadPage();
  }

  Future<List<VideoModel>> _loadPage() async {
    final page = await ref
        .read(feedRepositoryProvider)
        .fetchFollowingFeed(
          followedUserIds: _authorIds,
          cursor: _cursor,
          size: _pageSize,
          feed: _feedKind,
        );
    _cursor = page.nextCursor;
    _more.done = page.nextCursor == null;
    return _hydrateAuthors(page.items);
  }

  /// Only the authors: the hearts are batched by [FeedNotifier] for its own
  /// pages, and this tab's rows go through the same cache, so a clip seen on
  /// both is already filled in.
  Future<List<VideoModel>> _hydrateAuthors(List<VideoModel> videos) async {
    try {
      await ref
          .read(profileCacheProvider.notifier)
          .loadMissing(videos.map((v) => v.userId));
    } on AppException {
      // Placeholder avatars beat an error page — same bargain as the main feed.
    }
    try {
      await ref
          .read(likeStatusCacheProvider.notifier)
          .loadMissing(videos.map((v) => v.id));
    } on AppException {
      // ignore — see above
    }
    return videos;
  }

  Future<void> loadMore() => _more.run(() async {
    state = AsyncData(_appendDistinct(state.value ?? [], await _loadPage()));
  });

  void remove(String videoId) => state = AsyncData(_without(state, videoId));
}

/// The Following tab: only the accounts the viewer follows, newest first.
@riverpod
class FollowingFeedNotifier extends _$FollowingFeedNotifier with _AuthorFeed {
  @override
  String get _feedKind => 'FOLLOWING';

  @override
  FutureOr<List<VideoModel>> build() => _start();

  @override
  Future<List<String>> _resolveAuthors(String viewerId) async =>
      (await ref
              .read(userRepositoryProvider)
              .getFollowing(viewerId, size: _followedIdLimit))
          .content
          .map((profile) => profile.userId)
          .toList();
}

/// How many followers the Friends tab reads to find who follows back. Wider
/// than [_followedIdLimit]: a popular account's followers far outnumber the
/// people it follows, and a mutual missed here is a friend missing from the tab.
const _followerScanLimit = 500;

/// The Friends tab: mutual follows — accounts the viewer follows that follow
/// back. user-service has no friends listing, so it is the intersection of the
/// viewer's following and followers, the same way the web computes it.
@riverpod
class FriendsFeedNotifier extends _$FriendsFeedNotifier with _AuthorFeed {
  @override
  String get _feedKind => 'FRIENDS';

  @override
  FutureOr<List<VideoModel>> build() => _start();

  @override
  Future<List<String>> _resolveAuthors(String viewerId) async {
    final users = ref.read(userRepositoryProvider);
    final following = (await users.getFollowing(
      viewerId,
      size: _followedIdLimit,
    )).content.map((profile) => profile.userId).toList();
    if (following.isEmpty) return const [];

    final followers = <String>{};
    for (var page = 0; followers.length < _followerScanLimit; page++) {
      final result = await users.getFollowers(viewerId, page: page, size: 50);
      followers.addAll(result.content.map((profile) => profile.userId));
      if (result.last || result.content.isEmpty) break;
    }
    return [
      for (final id in following)
        if (followers.contains(id)) id,
    ];
  }
}

/// One video by id, for a link that names nothing else — a notification
/// about a comment on it, say.
@riverpod
Future<VideoModel> videoById(Ref ref, String videoId) =>
    ref.read(feedRepositoryProvider).getVideo(videoId);

/// The latest copy of each video its owner edited this session. Screens that
/// hold their own snapshot of a video — a feed page, the viewer opened from a
/// grid — read through this so an edit shows at once.
@Riverpod(keepAlive: true)
class EditedVideos extends _$EditedVideos {
  @override
  Map<String, VideoModel> build() => const {};

  void put(VideoModel video) => state = {...state, video.id: video};
}

/// Every owner edit made outside Studio — from the profile grid or from the
/// player — goes through here, so each list showing the video follows.
@Riverpod(keepAlive: true)
VideoEditor videoEditor(Ref ref) => VideoEditor(ref);

class VideoEditor {
  VideoEditor(this._ref);

  final Ref _ref;

  FeedRepository get _repo => _ref.read(feedRepositoryProvider);

  Future<VideoModel> setVisibility(String videoId, VideoVisibility v) =>
      _apply(_repo.updateVisibility(videoId, v));

  Future<VideoModel> setCommentsDisabled(String videoId, bool disabled) =>
      _apply(_repo.updateCommentsDisabled(videoId, disabled));

  Future<VideoModel> setPinned(String videoId, bool pinned) =>
      _apply(_repo.setPinned(videoId, pinned));

  /// One-way: there is no restore API.
  Future<void> delete(VideoModel video) async {
    await _repo.deleteVideo(video.id);
    final grid = userVideosNotifierProvider(video.userId);
    if (_ref.exists(grid)) _ref.read(grid.notifier).remove(video.id);
    if (_ref.exists(feedNotifierProvider)) {
      _ref.read(feedNotifierProvider.notifier).remove(video.id);
    }
    if (_ref.exists(followingFeedNotifierProvider)) {
      _ref.read(followingFeedNotifierProvider.notifier).remove(video.id);
    }
    if (_ref.exists(friendsFeedNotifierProvider)) {
      _ref.read(friendsFeedNotifierProvider.notifier).remove(video.id);
    }
  }

  Future<VideoModel> _apply(Future<VideoModel> change) async {
    final updated = await change;
    _ref.read(editedVideosProvider.notifier).put(updated);
    final grid = userVideosNotifierProvider(updated.userId);
    if (_ref.exists(grid)) _ref.read(grid.notifier).replace(updated);
    return updated;
  }
}
