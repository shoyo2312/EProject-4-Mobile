import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/interaction/presentation/interaction_provider.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/data/studio_remote_datasource.dart';
import 'package:tiktok_mobile/features/studio/data/studio_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

part 'studio_provider.g.dart';

@Riverpod(keepAlive: true)
StudioRepository studioRepository(Ref ref) =>
    StudioRepository(StudioRemoteDatasource(ref.watch(apiClientProvider)));

/// The windows Studio's picker offers, in days.
const studioRanges = [7, 28, 60, 365];

/// The window every analytics screen reads, shared so a pick on one screen
/// holds on the next.
@Riverpod(keepAlive: true)
class StudioRange extends _$StudioRange {
  @override
  int build() => 7;

  void set(int days) => state = days;
}

/// Reloads [provider] only when something is showing it. A plain invalidate
/// would build a list nobody is looking at, at the cost of a request.
void _refreshIfShown(Ref ref, ProviderBase<Object?> provider) {
  if (ref.exists(provider)) ref.invalidate(provider);
}

/// Names and pictures are decoration: a row reads fine without them.
Future<void> _loadAuthors(Ref ref, Iterable<String> userIds) async {
  try {
    await ref.read(profileCacheProvider.notifier).loadMissing(userIds);
  } on AppException {
    // Placeholders it is.
  }
}

/// Videos Studio has seen by id — analytics and the comment inbox hand back
/// ids only, and the title and thumbnail come from `/videos/batch`.
@Riverpod(keepAlive: true)
class StudioVideoCache extends _$StudioVideoCache {
  @override
  Map<String, VideoModel> build() {
    // A different account must not see the last one's videos. Only a real
    // change of account clears it: auth going from loading to signed in is
    // the same person, and clearing then would drop rows just loaded.
    ref.listen(authStateProvider.select((s) => s.valueOrNull?.id), (
      previous,
      next,
    ) {
      if (previous != null && previous != next) state = const {};
    });
    return const {};
  }

  Future<void> loadMissing(Iterable<String> ids) async {
    final missing = [
      for (final id in ids.toSet())
        if (!state.containsKey(id)) id,
    ];
    if (missing.isEmpty) return;
    try {
      final videos = await ref.read(feedRepositoryProvider).fetchByIds(missing);
      state = {...state, for (final v in videos) v.id: v};
    } on AppException {
      // Rows fall back to a placeholder thumbnail.
    }
  }

  void put(VideoModel video) => state = {...state, video.id: video};

  void remove(String id) => state = {...state}..remove(id);
}

// ---------------------------------------------------------------------------
// Analytics
// ---------------------------------------------------------------------------

@riverpod
Future<CreatorOverview> studioOverview(Ref ref) => ref
    .read(studioRepositoryProvider)
    .getOverview(ref.watch(studioRangeProvider));

@riverpod
Future<CreatorViewers> studioViewers(Ref ref) => ref
    .read(studioRepositoryProvider)
    .getViewers(ref.watch(studioRangeProvider));

/// The analytics top list, its videos loaded into [StudioVideoCache].
@riverpod
Future<List<CreatorVideoStats>> studioTopVideos(
  Ref ref,
  CreatorVideoSort sort,
) async {
  final rows = await ref
      .read(studioRepositoryProvider)
      .getTopVideos(ref.watch(studioRangeProvider), sort);
  await ref
      .read(studioVideoCacheProvider.notifier)
      .loadMissing([for (final r in rows) r.videoId]);
  return rows;
}

/// One video's analytics, together with the video itself for its header.
class StudioVideoAnalytics {
  const StudioVideoAnalytics({required this.detail, required this.video});

  final CreatorVideoDetail detail;
  final VideoModel video;
}

@riverpod
Future<StudioVideoAnalytics> studioVideoAnalytics(
  Ref ref,
  String videoId,
) async {
  final days = ref.watch(studioRangeProvider);
  final detail =
      ref.read(studioRepositoryProvider).getVideoDetail(videoId, days);
  final video = ref.read(feedRepositoryProvider).getVideo(videoId);
  final result = StudioVideoAnalytics(detail: await detail, video: await video);
  ref.read(studioVideoCacheProvider.notifier).put(result.video);
  return result;
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

/// The newest few of the creator's videos, in any status.
@riverpod
Future<List<VideoModel>> studioRecentPosts(Ref ref) async {
  final page = await ref
      .read(studioRepositoryProvider)
      .listMyVideos(const StudioPostQuery(), size: 3);
  return page.content;
}

/// The newest few comments on any of the creator's videos.
@riverpod
Future<List<CommentModel>> studioRecentComments(Ref ref) async {
  final page = await ref
      .read(studioRepositoryProvider)
      .listInbox(const InboxQuery(), size: 3);
  await Future.wait([
    _loadAuthors(ref, [for (final c in page.items) c.userId]),
    ref
        .read(studioVideoCacheProvider.notifier)
        .loadMissing([for (final c in page.items) c.videoId]),
  ]);
  return page.items;
}

// ---------------------------------------------------------------------------
// Posts
// ---------------------------------------------------------------------------

@riverpod
class StudioPostFilter extends _$StudioPostFilter {
  @override
  StudioPostQuery build() => const StudioPostQuery();

  void set(StudioPostQuery query) => state = query;
}

/// The Posts list under the current [StudioPostFilter], offset paged.
@riverpod
class StudioPosts extends _$StudioPosts {
  int _page = 0;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<VideoModel>> build() async {
    final query = ref.watch(studioPostFilterProvider);
    final page = await ref.read(studioRepositoryProvider).listMyVideos(query);
    _page = 0;
    _more.done = page.last;
    return page.content;
  }

  Future<void> loadMore() => _more.run(() async {
        final next = _page + 1;
        final page = await ref
            .read(studioRepositoryProvider)
            .listMyVideos(ref.read(studioPostFilterProvider), page: next);
        _page = next;
        _more.done = page.last;
        final seen = {for (final v in state.value ?? <VideoModel>[]) v.id};
        state = AsyncData([
          ...state.value ?? <VideoModel>[],
          ...page.content.where((v) => !seen.contains(v.id)),
        ]);
      });

  void replace(VideoModel updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final v in current)
        if (v.id == updated.id) updated else v,
    ]);
  }

  void remove(String videoId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final v in current)
        if (v.id != videoId) v,
    ]);
  }
}

/// Every change Studio makes to a video goes through here, so the lists that
/// show it — Posts, Home, the profile grid — all follow.
@Riverpod(keepAlive: true)
StudioEditor studioEditor(Ref ref) => StudioEditor(ref);

class StudioEditor {
  StudioEditor(this._ref);

  final Ref _ref;

  Future<VideoModel> updateCaption(
    String videoId, {
    required String title,
    String? description,
  }) =>
      _apply(_ref.read(studioRepositoryProvider).updateCaption(
            videoId,
            title: title,
            description: description,
          ));

  Future<VideoModel> setPinned(String videoId, bool pinned) =>
      _apply(_ref.read(studioRepositoryProvider).setPinned(videoId, pinned));

  Future<VideoModel> setVisibility(String videoId, VideoVisibility v) =>
      _apply(_ref.read(feedRepositoryProvider).updateVisibility(videoId, v));

  Future<VideoModel> setCommentsDisabled(String videoId, bool disabled) =>
      _apply(_ref
          .read(feedRepositoryProvider)
          .updateCommentsDisabled(videoId, disabled));

  /// One-way: there is no restore API.
  Future<void> delete(String videoId) async {
    await _ref.read(feedRepositoryProvider).deleteVideo(videoId);
    if (_ref.exists(studioPostsProvider)) {
      _ref.read(studioPostsProvider.notifier).remove(videoId);
    }
    _ref.read(studioVideoCacheProvider.notifier).remove(videoId);
    _refreshElsewhere();
  }

  Future<VideoModel> _apply(Future<VideoModel> change) async {
    final updated = await change;
    if (_ref.exists(studioPostsProvider)) {
      _ref.read(studioPostsProvider.notifier).replace(updated);
    }
    _ref.read(studioVideoCacheProvider.notifier).put(updated);
    _refreshElsewhere();
    return updated;
  }

  void _refreshElsewhere() {
    _refreshIfShown(_ref, studioRecentPostsProvider);
    final me = _ref.read(authStateProvider).valueOrNull?.id;
    if (me != null) _refreshIfShown(_ref, userVideosNotifierProvider(me));
  }
}

/// One of the creator's videos as it stands now, for the edit page.
@riverpod
Future<VideoModel> studioVideo(Ref ref, String videoId) =>
    ref.read(feedRepositoryProvider).getVideo(videoId);

/// The creator's videos for the comment inbox's video picker.
@riverpod
Future<List<VideoModel>> studioPickableVideos(Ref ref) async {
  final page = await ref
      .read(studioRepositoryProvider)
      .listMyVideos(const StudioPostQuery(), size: 50);
  return page.content;
}

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

/// Keyed by the video the screen was opened on, so a deep link to one
/// video's comments starts filtered instead of loading everything first.
@riverpod
class StudioInboxFilter extends _$StudioInboxFilter {
  @override
  InboxQuery build(String? initialVideoId) =>
      InboxQuery(videoId: initialVideoId);

  void set(InboxQuery query) => state = query;
}

/// Comments on the creator's videos under the current [StudioInboxFilter],
/// cursor paged.
@riverpod
class StudioInbox extends _$StudioInbox {
  String? _cursor;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<CommentModel>> build(String? initialVideoId) async {
    ref.watch(studioInboxFilterProvider(initialVideoId));
    _cursor = null;
    _more.done = false;
    return (await _fetch()).items;
  }

  Future<CommentPage> _fetch() async {
    final page = await ref.read(studioRepositoryProvider).listInbox(
          ref.read(studioInboxFilterProvider(initialVideoId)),
          cursor: _cursor,
        );
    _cursor = page.nextCursor;
    // `hasMore`, never an empty page: a filtered page can be empty mid-list.
    _more.done = !page.hasMore;
    await Future.wait([
      _loadAuthors(ref, [for (final c in page.items) c.userId]),
      ref
          .read(studioVideoCacheProvider.notifier)
          .loadMissing([for (final c in page.items) c.videoId]),
    ]);
    return page;
  }

  Future<void> loadMore() => _more.run(() async {
        var comments = state.value ?? <CommentModel>[];
        // A page can add nothing; try a few before giving this scroll up.
        for (var attempt = 0; attempt < 3; attempt++) {
          final seen = {for (final c in comments) c.id};
          comments = [
            ...comments,
            ...(await _fetch()).items.where((c) => !seen.contains(c.id)),
          ];
          if (comments.length > (state.value ?? []).length || _more.done) {
            break;
          }
        }
        state = AsyncData(comments);
      });

  /// Publishes a held comment. Under the "held only" filter it leaves the list.
  Future<void> approve(CommentModel comment) async {
    await ref
        .read(studioRepositoryProvider)
        .approveComment(comment.videoId, comment.id);
    if (ref.read(studioInboxFilterProvider(initialVideoId)).heldOnly) {
      _remove(comment.id);
    } else {
      _write(comment.copyWith(status: CommentStatus.visible));
    }
    _refreshIfShown(ref, studioRecentCommentsProvider);
  }

  /// The owner may delete any comment on their own video; this is also how a
  /// held comment is rejected.
  Future<void> delete(CommentModel comment) async {
    await ref
        .read(commentRepositoryProvider)
        .deleteComment(comment.videoId, comment.id);
    _remove(comment.id);
    _refreshIfShown(ref, studioRecentCommentsProvider);
  }

  /// Not retried: the endpoint does not deduplicate. A reply to a reply lands
  /// in the same thread, as the server flattens it.
  Future<CommentModel> reply(CommentModel comment, String text) async {
    final created = await ref.read(commentRepositoryProvider).postComment(
          comment.videoId,
          text,
          parentId: comment.id,
        );
    _write(comment.copyWith(replyCount: comment.replyCount + 1));
    return created;
  }

  Future<void> toggleLike(CommentModel comment) async {
    final repo = ref.read(commentRepositoryProvider);
    final result = comment.likedByMe
        ? await repo.unlikeComment(comment.videoId, comment.id)
        : await repo.likeComment(comment.videoId, comment.id);
    _write(comment.copyWith(
      likedByMe: result.liked,
      likeCount: result.likeCount,
    ));
  }

  void _write(CommentModel updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final c in current)
        if (c.id == updated.id) updated else c,
    ]);
  }

  void _remove(String commentId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final c in current)
        if (c.id != commentId) c,
    ]);
  }
}

// ---------------------------------------------------------------------------
// Inspiration
// ---------------------------------------------------------------------------

/// What is trending across Nowa right now, with creators resolved.
@riverpod
Future<List<VideoModel>> studioTrending(Ref ref) async {
  final videos =
      await ref.read(feedRepositoryProvider).fetchTrending(limit: 30);
  await _loadAuthors(ref, [for (final v in videos) v.userId]);
  return videos;
}

/// "My inspiration": the videos the creator saved, newest save first.
@riverpod
class StudioSavedVideos extends _$StudioSavedVideos {
  String? _cursor;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<VideoModel>> build() async {
    _cursor = null;
    _more.done = false;
    return _fetch();
  }

  Future<List<VideoModel>> _fetch() async {
    final page = await ref
        .read(interactionRepositoryProvider)
        .getSavedVideoIds(cursor: _cursor);
    _cursor = page.nextCursor;
    _more.done = !page.hasMore;
    final videos =
        await ref.read(feedRepositoryProvider).fetchByIds(page.videoIds);
    await _loadAuthors(ref, [for (final v in videos) v.userId]);
    return videos;
  }

  Future<void> loadMore() => _more.run(() async {
        final seen = {for (final v in state.value ?? <VideoModel>[]) v.id};
        final next = await _fetch();
        state = AsyncData([
          ...state.value ?? <VideoModel>[],
          ...next.where((v) => !seen.contains(v.id)),
        ]);
      });
}
