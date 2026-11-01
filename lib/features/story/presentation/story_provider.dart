import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_remote_datasource.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

part 'story_provider.g.dart';

@Riverpod(keepAlive: true)
StoryRepository storyRepository(Ref ref) =>
    StoryRepository(StoryRemoteDatasource(ref.watch(apiClientProvider)));

/// `/stories/feed` takes at most 500 followed ids (story doc §5).
const _followedIdCap = 500;
const _followingPageSize = 100;

/// The story tray: the viewer's own group first, then the people they follow
/// who have something to watch.
///
/// story-service holds no follow graph, so the ids come from user-service
/// first — the same two-step read the Following feed does.
@Riverpod(keepAlive: true)
class StoryTray extends _$StoryTray {
  DateTime? _loadedAt;

  /// Media URLs are signed for one hour (story doc §3). A tray older than
  /// this is read again before anything is played from it.
  static const _freshFor = Duration(minutes: 45);

  @override
  FutureOr<List<StoryGroup>> build() async {
    final me = await ref.watch(authStateProvider.future);
    _loadedAt = DateTime.now();
    if (me == null) return const [];

    final users = ref.read(userRepositoryProvider);
    final followed = <String>[];
    for (var page = 0; followed.length < _followedIdCap; page++) {
      final result =
          await users.getFollowing(me.id, page: page, size: _followingPageSize);
      followed.addAll(result.content.map((p) => p.userId));
      if (result.last || result.content.isEmpty) break;
    }

    final groups = await ref
        .read(storyRepositoryProvider)
        .feed(followed.take(_followedIdCap).toList());
    try {
      await ref
          .read(profileCacheProvider.notifier)
          .loadMissing([me.id, ...groups.map((g) => g.userId)]);
    } on AppException {
      // Placeholder avatars beat an empty tray.
    }
    return groups;
  }

  /// The groups, re-read first if their signed URLs may have run out.
  Future<List<StoryGroup>> fresh() async {
    final loadedAt = _loadedAt;
    if (loadedAt == null ||
        DateTime.now().difference(loadedAt) > _freshFor ||
        state.valueOrNull == null) {
      ref.invalidateSelf();
    }
    return future;
  }

  /// Applied locally once a story has been opened: the server agrees on the
  /// next read, and the ring should go grey now, not then.
  void markViewed(String storyId) => _update((groups) => [
        for (final g in groups)
          _withStories(g, [
            for (final s in g.stories)
              s.id == storyId ? s.copyWith(viewedByMe: true) : s,
          ]),
      ]);

  void setReaction(String storyId, StoryReaction? reaction) =>
      _update((groups) => [
            for (final g in groups)
              g.copyWith(stories: [
                for (final s in g.stories)
                  s.id == storyId
                      ? s.copyWith(myReaction: reaction, viewedByMe: true)
                      : s,
              ]),
          ]);

  void replace(StoryModel story) => _update((groups) => [
        for (final g in groups)
          g.copyWith(stories: [
            for (final s in g.stories) s.id == story.id ? story : s,
          ]),
      ]);

  /// Groups left empty are dropped; the tray draws "Your story" from the
  /// session either way.
  void remove(String storyId) => _update((groups) => [
        for (final g in groups)
          _withStories(g, [
            for (final s in g.stories)
              if (s.id != storyId) s,
          ]),
      ].where((g) => g.stories.isNotEmpty).toList());

  void _update(List<StoryGroup> Function(List<StoryGroup>) change) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(change(current));
  }

  /// [StoryGroup.hasUnseen] follows the stories: it is the ring's colour.
  static StoryGroup _withStories(StoryGroup group, List<StoryModel> stories) =>
      group.copyWith(
        stories: stories,
        hasUnseen: group.hasUnseen && stories.any((s) => !s.viewedByMe),
      );
}

/// The ring around one avatar (a profile header). Null when the account has
/// nothing the viewer may watch.
@riverpod
Future<StoryRing?> storyRing(Ref ref, String userId) async {
  // Re-read when the session changes: what is visible depends on who asks.
  await ref.watch(authStateProvider.future);
  final rings = await ref.read(storyRepositoryProvider).rings([userId]);
  for (final ring in rings) {
    if (ring.userId == userId) return ring;
  }
  return null;
}

/// One account's live stories, oldest first, as a group the viewer can play
/// — what a profile avatar opens.
Future<StoryGroup?> loadUserStoryGroup(Ref ref, String userId) async {
  final stories = await ref.read(storyRepositoryProvider).userStories(userId);
  if (stories.isEmpty) return null;
  try {
    await ref.read(profileCacheProvider.notifier).loadMissing([userId]);
  } on AppException {
    // A missing name is not worth failing the stories over.
  }
  return StoryGroup(
    userId: userId,
    stories: stories,
    hasUnseen: stories.any((s) => !s.viewedByMe),
  );
}

@riverpod
Future<StoryGroup?> userStoryGroup(Ref ref, String userId) =>
    loadUserStoryGroup(ref, userId);

/// "Who watched my story", newest first, paged by `viewedAt`.
@riverpod
class StoryViewers extends _$StoryViewers {
  var _done = false;
  var _busy = false;

  @override
  FutureOr<List<StoryViewer>> build(String storyId) async {
    _done = false;
    return _page(null);
  }

  bool get hasMore => !_done;

  Future<List<StoryViewer>> _page(DateTime? before) async {
    final rows = await ref
        .read(storyRepositoryProvider)
        .viewers(storyId, before: before);
    // The server's default page is 20; a short page is the last one.
    if (rows.length < 20) _done = true;
    try {
      await ref
          .read(profileCacheProvider.notifier)
          .loadMissing(rows.map((r) => r.viewerId));
    } on AppException {
      // Rows show a placeholder instead.
    }
    return rows;
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (_done || _busy || current == null || current.isEmpty) return;
    _busy = true;
    try {
      final next = await _page(current.last.viewedAt);
      state = AsyncData([...current, ...next]);
    } on AppException {
      // The rows on screen stay; the next scroll retries.
    } finally {
      _busy = false;
    }
  }
}

/// A picked photo or clip, ready for the composer.
class StoryDraft {
  const StoryDraft({required this.file, required this.contentType});

  final File file;
  final String contentType;

  bool get isVideo => isVideoContentType(contentType);
}

enum StoryUploadPhase { idle, uploading, creating, done, failed }

class StoryUploadState {
  const StoryUploadState({
    this.phase = StoryUploadPhase.idle,
    this.progress = 0,
    this.story,
    this.error,
  });

  final StoryUploadPhase phase;

  /// 0..1, or -1 when the size is unknown.
  final double progress;
  final StoryModel? story;
  final String? error;

  bool get busy =>
      phase == StoryUploadPhase.uploading || phase == StoryUploadPhase.creating;
}

/// Kept alive so a switch of tab does not cancel an upload mid-file.
@Riverpod(keepAlive: true)
class StoryUpload extends _$StoryUpload {
  CancelToken? _cancelToken;
  var _disposed = false;

  @override
  StoryUploadState build() {
    ref.onDispose(() {
      _disposed = true;
      _cancelToken?.cancel();
    });
    return const StoryUploadState();
  }

  Future<void> start({
    required StoryDraft draft,
    String? caption,
    required StoryVisibility visibility,
  }) async {
    if (state.busy) return;
    final cancelToken = _cancelToken = CancelToken();
    state = const StoryUploadState(phase: StoryUploadPhase.uploading);

    try {
      final story = await ref.read(storyRepositoryProvider).uploadAndCreate(
            file: draft.file,
            contentType: draft.contentType,
            caption: caption,
            visibility: visibility,
            cancelToken: cancelToken,
            onProgress: (sent, total) {
              if (_disposed || state.phase != StoryUploadPhase.uploading) {
                return;
              }
              state = total > 0 && sent >= total
                  ? const StoryUploadState(
                      phase: StoryUploadPhase.creating,
                      progress: 1,
                    )
                  : StoryUploadState(
                      phase: StoryUploadPhase.uploading,
                      progress: total > 0 ? sent / total : -1,
                    );
            },
          );
      if (_disposed) return;
      state = StoryUploadState(
        phase: StoryUploadPhase.done,
        progress: 1,
        story: story,
      );
      // The tray's first bubble and the profile ring both change now.
      ref.invalidate(storyTrayProvider);
      ref.invalidate(storyRingProvider(story.userId));
      ref.invalidate(userStoryGroupProvider(story.userId));
    } on AppException catch (e) {
      if (_disposed || cancelToken.isCancelled) return;
      state = StoryUploadState(
        phase: StoryUploadPhase.failed,
        error: storyErrorMessage(e),
      );
    } finally {
      _cancelToken = null;
    }
  }

  void cancel() {
    _cancelToken?.cancel();
    state = const StoryUploadState();
  }

  void reset() => state = const StoryUploadState();
}

/// What the poster or viewer is told for each story-service error code.
String storyErrorMessage(AppException e) {
  if (e is ServerException) {
    return switch (e.code) {
      'UNSUPPORTED_UPLOAD_TYPE' =>
        'Only JPEG, PNG, WebP photos and MP4, WebM videos can be posted',
      'UPLOAD_NOT_FOUND' => 'The upload did not finish. Try again.',
      'FOREIGN_UPLOAD' => 'This file was already used for another story',
      'STORY_CAPTION_REJECTED' =>
        'The caption contains words that are not allowed',
      'STORY_NOT_FOUND' => 'This story is no longer available',
      'NOT_STORY_OWNER' => 'Only the owner can do that',
      'UPLOAD_URL_UNAVAILABLE' => 'Storage is unavailable. Try again later.',
      'STORY_NOT_AVAILABLE' => 'This story is no longer available',
      _ => e.message,
    };
  }
  return e.message;
}
