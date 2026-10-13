import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_model.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_remote_datasource.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_repository.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

part 'interaction_provider.g.dart';

@Riverpod(keepAlive: true)
InteractionRepository interactionRepository(Ref ref) => InteractionRepository(
      InteractionRemoteDatasource(ref.watch(apiClientProvider)),
    );

/// Like state already fetched, keyed by `videoId`.
///
/// One place so a screen holding a page of videos resolves them in a single
/// `GET /like-status/batch` instead of one request per card: the gateway allows
/// 20 req/s per IP, and a feed page alone would spend the lot. Same arrangement
/// as `ProfileCache` (interaction doc 3.3b).
@Riverpod(keepAlive: true)
class LikeStatusCache extends _$LikeStatusCache {
  @override
  Map<String, LikeStatus> build() => const {};

  /// Fetches only the ids not held yet. The batch endpoint needs a token, so
  /// callers skip this entirely for a signed-out viewer rather than spending a
  /// request on a guaranteed 401.
  Future<void> loadMissing(Iterable<String> ids) async {
    final missing = [
      for (final id in ids.toSet())
        if (!state.containsKey(id)) id,
    ];
    if (missing.isEmpty) return;
    final rows =
        await ref.read(interactionRepositoryProvider).getLikeStatuses(missing);
    state = {
      ...state,
      for (final row in rows) row.videoId: row,
    };
  }

  void put(LikeStatus status) => state = {...state, status.videoId: status};
}

/// Like state for **one** video.
///
/// Seeded from [LikeStatusCache] when the feed has already batched this page
/// in; only a video nobody prefetched — a profile grid, a deep link — pays for
/// its own `GET /like-status` (interaction doc 3.3).
@riverpod
class LikeNotifier extends _$LikeNotifier {
  @override
  FutureOr<LikeStatus> build(String videoId) {
    // Read, not watch: `_publish` below writes to the cache, and watching it
    // here would rebuild this provider straight back over its own result.
    final cached = ref.read(likeStatusCacheProvider)[videoId];
    if (cached != null) return cached;
    return ref.read(interactionRepositoryProvider).getLikeStatus(videoId);
  }

  /// Every state change goes through here so the cache keeps the newest answer:
  /// scrolling a clip off screen disposes this notifier, and the next visit
  /// must not show the heart the way the server last saw it before the tap.
  void _publish(LikeStatus status) {
    state = AsyncData(status);
    ref.read(likeStatusCacheProvider.notifier).put(status);
  }

  /// Optimistic: the heart flips now and the server's own count replaces the
  /// guess when it answers. A failed write puts the previous state back —
  /// like/unlike are idempotent, so the next tap is safe to send again.
  Future<void> toggle() async {
    final current = state.valueOrNull;
    // Still loading: nothing to toggle away from, and guessing here would
    // fight the in-flight `like-status` answer.
    if (current == null) return;

    final wantLiked = !current.liked;
    _publish(current.copyWith(
      liked: wantLiked,
      likeCount: current.likeCount + (wantLiked ? 1 : -1),
    ));

    final repository = ref.read(interactionRepositoryProvider);
    try {
      _publish(
        wantLiked
            ? await repository.like(videoId)
            : await repository.unlike(videoId),
      );
      // The Liked tab on the profile lists exactly what this just changed.
      ref.invalidate(historyVideosNotifierProvider(VideoHistory.liked));
    } on AppException {
      _publish(current);
    }
  }

  /// Double-tap: likes, never un-likes.
  Future<void> like() async {
    if (state.valueOrNull?.liked ?? true) return;
    await toggle();
  }
}

/// The four counters of one video, straight from interaction-service.
///
/// Watched only for the clip on screen, like [LikeNotifier] and for the same
/// reason: there is no batch endpoint and the gateway's per-IP budget is
/// shared app-wide. Needs no token, so a signed-out viewer sees real numbers.
@riverpod
Future<InteractionCounts> videoCounts(Ref ref, String videoId) =>
    ref.read(interactionRepositoryProvider).getCounts(videoId);

/// Whether the calling user has this video in their favourites.
///
/// No cache and no batch endpoint behind it, unlike [LikeNotifier]: a save is
/// private, so there is nothing to prefetch for a page of videos and nothing to
/// show a signed-out viewer. The `save-status` read is answered locally for a
/// guest rather than spending a request on a guaranteed 401.
@riverpod
class SaveNotifier extends _$SaveNotifier {
  @override
  FutureOr<SaveStatus> build(String videoId) async {
    if (await ref.watch(authStateProvider.future) == null) {
      return SaveStatus(videoId: videoId, saved: false);
    }
    return ref.read(interactionRepositoryProvider).getSaveStatus(videoId);
  }

  /// Optimistic, like [LikeNotifier.toggle], and safe to tap again after a
  /// failure: save and unsave are both idempotent.
  Future<void> toggle() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final wantSaved = !current.saved;
    state = AsyncData(current.copyWith(saved: wantSaved));

    final repository = ref.read(interactionRepositoryProvider);
    try {
      state = AsyncData(
        wantSaved
            ? await repository.save(videoId)
            : await repository.unsave(videoId),
      );
      // The Saved tab on the profile lists exactly what this just changed.
      ref.invalidate(historyVideosNotifierProvider(VideoHistory.saved));
    } on AppException {
      state = AsyncData(current);
    }
  }
}

/// The two id-only histories interaction-service exposes about the caller.
enum VideoHistory { liked, saved }

/// The caller's own liked or saved videos, hydrated into playable rows.
///
/// Two hops on purpose: interaction-service holds no video metadata, so it
/// answers ids and video-service turns them into videos. Ids that no longer
/// resolve — deleted, or turned private since — are simply absent from the
/// hydration, so a page can come back shorter than the ids asked for, and
/// occasionally empty while there is still more (interaction doc 3.12).
@riverpod
class HistoryVideosNotifier extends _$HistoryVideosNotifier {
  String? _cursor;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<VideoModel>> build(VideoHistory history) async {
    _cursor = null;
    return _fetch();
  }

  Future<List<VideoModel>> _fetch() async {
    final repository = ref.read(interactionRepositoryProvider);
    final page = history == VideoHistory.liked
        ? await repository.getLikedVideoIds(cursor: _cursor)
        : await repository.getSavedVideoIds(cursor: _cursor);
    _cursor = page.nextCursor;
    // `hasMore`, never the page being empty: ids that hydrate to nothing are
    // dropped, so an empty page in the middle of the list is normal.
    _more.done = !page.hasMore;
    return ref.read(feedRepositoryProvider).fetchByIds(page.videoIds);
  }

  Future<void> loadMore() => _more.run(() async {
        var videos = state.value ?? [];
        // A page that adds nothing never grows the list back to the scroll
        // trigger; try a few before giving this scroll up.
        for (var attempt = 0; attempt < 3; attempt++) {
          final before = videos.length;
          videos = [...videos, ...await _fetch()];
          if (videos.length > before || _more.done) break;
        }
        state = AsyncData(videos);
      });
}
