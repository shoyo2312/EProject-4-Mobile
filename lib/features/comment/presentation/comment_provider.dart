import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

part 'comment_provider.g.dart';

@Riverpod(keepAlive: true)
CommentRepository commentRepository(Ref ref) =>
    CommentRepository(CommentRemoteDatasource(ref.watch(apiClientProvider)));

/// The sticker catalog for the comment composer — chat-service's catalog,
/// fetched once per session.
@Riverpod(keepAlive: true)
Future<List<StickerPack>> commentStickerPacks(Ref ref) =>
    ref.read(commentRepositoryProvider).listStickerPacks();

/// Names and pictures are decoration: a comment reads fine without them.
/// So are story rings, which load alongside and never hold the page up.
Future<void> _loadAuthors(Ref ref, Iterable<CommentModel> comments) async {
  unawaited(_loadRings(ref, [for (final c in comments) c.userId]));
  try {
    await ref.read(profileCacheProvider.notifier).loadMissing([
      for (final c in comments) ...[c.userId, ?c.replyToUserId],
    ]);
  } on AppException {
    // Placeholders it is.
  }
}

Future<void> _loadRings(Ref ref, List<String> userIds) async {
  try {
    await ref.read(storyRingsProvider.notifier).loadMissing(userIds);
  } on AppException {
    // Plain avatars.
  }
}

/// The top-level comments of one video, newest first. Replies live in
/// [CommentReplies]; this notifier keeps the two in step (a reply posted or
/// deleted moves its thread's `replyCount` here).
@riverpod
class CommentNotifier extends _$CommentNotifier {
  String? _nextCursor;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<CommentModel>> build(String videoId) async {
    final page = await _fetch();
    return page.items;
  }

  CommentReplies get _replies =>
      ref.read(commentRepliesProvider(videoId).notifier);

  /// One page, with its authors resolved into the shared profile cache — the
  /// comment endpoint returns `userId` and nothing else about the person
  /// (interaction doc 3.4).
  Future<CommentPage> _fetch() async {
    final page = await ref
        .read(commentRepositoryProvider)
        .fetchComments(videoId, cursor: _nextCursor);
    _nextCursor = page.nextCursor;
    // `hasMore`, never the page being empty: deleted rows are filtered after
    // Cassandra cut the page, so an empty page in the middle is normal
    // (interaction doc 3.5).
    _more.done = !page.hasMore;
    await _loadAuthors(ref, page.items);
    return page;
  }

  Future<void> loadMore() => _more.run(() async {
        var comments = state.value ?? [];
        // A page can legitimately add nothing (see _fetch), and a page that
        // adds nothing never grows the list back to the scroll trigger. Try a
        // few before giving this scroll up.
        for (var attempt = 0; attempt < 3; attempt++) {
          comments = [...comments, ...(await _fetch()).items];
          if (comments.length > (state.value ?? []).length || _more.done) break;
        }
        state = AsyncData(comments);
      });

  /// Not retried on failure and the button stays disabled until this returns:
  /// the endpoint does not deduplicate, so a second send is a second comment
  /// (interaction doc 3.4).
  ///
  /// [parentId] makes it a reply to that comment; the answer's own `parentId`
  /// is the thread it landed in. A comment the server held back
  /// (`status: HELD`) is not added anywhere: nobody but its author can see it.
  /// The caller reads the returned status to tell the author.
  Future<CommentModel> postComment(
    String text, {
    String? parentId,
    String? stickerId,
  }) async {
    final created = await ref.read(commentRepositoryProvider).postComment(
          videoId,
          text,
          parentId: parentId,
          stickerId: stickerId,
        );
    if (created.status == CommentStatus.held) return created;
    unawaited(_loadAuthors(ref, [created]));
    final threadId = created.parentId;
    if (threadId == null) {
      state = AsyncData([created, ...state.value ?? <CommentModel>[]]);
      return created;
    }
    final thread = _topLevel(threadId);
    _replies.add(created, hadReplies: (thread?.replyCount ?? 0) > 0);
    if (thread != null) {
      _writeTopLevel(thread.copyWith(replyCount: thread.replyCount + 1));
    }
    return created;
  }

  /// The author's own comment. The row is replaced in place with what the
  /// server answered (`editedAt` set).
  Future<CommentModel> editComment(String commentId, String text) async {
    final updated = await ref
        .read(commentRepositoryProvider)
        .editComment(videoId, commentId, text);
    _write(updated);
    return updated;
  }

  /// Optimistic, and safe to tap again after a failure: like and unlike are
  /// both idempotent. The tally comes back from the server because someone else
  /// may have liked the same comment in between. Works on replies too.
  Future<void> toggleLike(String commentId) async {
    final comment = find(commentId);
    if (comment == null) return;

    final wantLiked = !comment.likedByMe;
    _write(comment.copyWith(
      likedByMe: wantLiked,
      likeCount: comment.likeCount + (wantLiked ? 1 : -1),
    ));

    final repository = ref.read(commentRepositoryProvider);
    try {
      final result = wantLiked
          ? await repository.likeComment(videoId, commentId)
          : await repository.unlikeComment(videoId, commentId);
      final latest = find(commentId);
      if (latest == null) return;
      _write(latest.copyWith(
        likedByMe: result.liked,
        likeCount: result.likeCount,
      ));
    } on AppException {
      if (find(commentId) != null) _write(comment);
    }
  }

  /// The author's own comment, or any comment when the caller owns the video —
  /// anything else answers `NOT_COMMENT_OWNER`.
  Future<void> deleteComment(String commentId) async {
    await ref.read(commentRepositoryProvider).deleteComment(videoId, commentId);
    _drop(commentId);
  }

  /// Admin removal of someone else's comment. The server deletes it a moment
  /// later (through an event), so the row is dropped here as soon as the
  /// request is accepted rather than waiting for a refetch to agree.
  Future<void> removeAsAdmin(String commentId, String reason) async {
    await ref
        .read(commentRepositoryProvider)
        .removeCommentAsAdmin(videoId, commentId, reason);
    _drop(commentId);
  }

  /// Leaves the thread as it is: a reported comment stays up until an admin
  /// decides.
  Future<void> report(String commentId, String reason) => ref
      .read(commentRepositoryProvider)
      .reportComment(videoId, commentId, reason);

  /// A loaded comment, top-level or reply.
  CommentModel? find(String commentId) =>
      _topLevel(commentId) ?? _replies.find(commentId);

  CommentModel? _topLevel(String commentId) {
    for (final c in state.value ?? const <CommentModel>[]) {
      if (c.id == commentId) return c;
    }
    return null;
  }

  void _write(CommentModel comment) {
    if (comment.isReply) {
      _replies.replace(comment);
    } else {
      _writeTopLevel(comment);
    }
  }

  void _writeTopLevel(CommentModel comment) {
    final current = state.value;
    if (current == null) return;
    final at = current.indexWhere((c) => c.id == comment.id);
    // The list can have been re-paged under the call; a comment that is gone
    // has nothing left to update.
    if (at == -1) return;
    state = AsyncData([...current]..[at] = comment);
  }

  /// Takes a deleted comment off screen: a reply leaves its thread (one fewer
  /// on the thread's count), a top-level comment takes its replies with it.
  void _drop(String commentId) {
    final reply = _replies.find(commentId);
    if (reply != null) {
      _replies.remove(reply);
      final thread = _topLevel(reply.parentId!);
      if (thread != null && thread.replyCount > 0) {
        _writeTopLevel(thread.copyWith(replyCount: thread.replyCount - 1));
      }
      return;
    }
    _replies.close(commentId);
    state = AsyncData([
      for (final comment in state.value ?? <CommentModel>[])
        if (comment.id != commentId) comment,
    ]);
  }
}

/// One thread's replies as far as they have been read, oldest first, then
/// any the viewer posted here that no page has returned yet.
class ReplyThread {
  const ReplyThread({
    this.items = const [],
    this.hasMore = true,
    this.nextCursor,
    this.loading = false,
    this.error,
    this.localIds = const {},
  });

  final List<CommentModel> items;
  final bool hasMore;
  final String? nextCursor;
  final bool loading;
  final Object? error;

  /// Replies posted from this device, shown at the end until a page brings
  /// them back from the server in their own place.
  final Set<String> localIds;

  ReplyThread copyWith({
    List<CommentModel>? items,
    bool? hasMore,
    String? nextCursor,
    bool? loading,
    Object? error,
    Set<String>? localIds,
  }) =>
      ReplyThread(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        nextCursor: nextCursor ?? this.nextCursor,
        loading: loading ?? this.loading,
        error: error,
        localIds: localIds ?? this.localIds,
      );
}

/// The open reply threads of one video, keyed by top-level comment id. A
/// thread absent from the map is collapsed.
@riverpod
class CommentReplies extends _$CommentReplies {
  @override
  Map<String, ReplyThread> build(String videoId) => const {};

  /// Expands a thread and reads its first page. Needs a token
  /// (interaction doc 3.5b).
  Future<void> open(String parentId) async {
    if (state.containsKey(parentId)) return;
    state = {...state, parentId: const ReplyThread(loading: true)};
    await _load(parentId);
  }

  /// The next page, or a retry after a failed one.
  Future<void> loadMore(String parentId) async {
    final thread = state[parentId];
    if (thread == null || thread.loading || !thread.hasMore) return;
    state = {...state, parentId: thread.copyWith(loading: true)};
    await _load(parentId);
  }

  Future<void> _load(String parentId) async {
    final cursor = state[parentId]?.nextCursor;
    try {
      final page = await ref
          .read(commentRepositoryProvider)
          .fetchReplies(videoId, parentId, cursor: cursor);
      await _loadAuthors(ref, page.items);
      final current = state[parentId];
      if (current == null) return; // collapsed meanwhile
      final pageIds = {for (final c in page.items) c.id};
      final read = [
        for (final c in current.items)
          if (!current.localIds.contains(c.id)) c,
      ];
      final readIds = {for (final c in read) c.id};
      final locals = [
        for (final c in current.items)
          if (current.localIds.contains(c.id) && !pageIds.contains(c.id)) c,
      ];
      state = {
        ...state,
        parentId: ReplyThread(
          items: [
            ...read,
            for (final c in page.items)
              if (!readIds.contains(c.id)) c,
            ...locals,
          ],
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
          localIds: {for (final c in locals) c.id},
        ),
      };
    } catch (e) {
      final current = state[parentId];
      if (current == null) return;
      state = {...state, parentId: current.copyWith(loading: false, error: e)};
    }
  }

  void close(String parentId) {
    if (!state.containsKey(parentId)) return;
    state = {...state}..remove(parentId);
  }

  /// A reply just posted. Opens its thread if it was collapsed; when the
  /// thread already had replies nobody has read here, "more" stays offered.
  void add(CommentModel reply, {required bool hadReplies}) {
    final parentId = reply.parentId!;
    final thread = state[parentId] ?? ReplyThread(hasMore: hadReplies);
    if (thread.items.any((c) => c.id == reply.id)) return;
    state = {
      ...state,
      parentId: thread.copyWith(
        items: [...thread.items, reply],
        localIds: {...thread.localIds, reply.id},
      ),
    };
  }

  void replace(CommentModel reply) {
    final parentId = reply.parentId;
    final thread = parentId == null ? null : state[parentId];
    if (thread == null) return;
    state = {
      ...state,
      parentId!: thread.copyWith(items: [
        for (final c in thread.items) c.id == reply.id ? reply : c,
      ]),
    };
  }

  void remove(CommentModel reply) {
    final parentId = reply.parentId;
    final thread = parentId == null ? null : state[parentId];
    if (thread == null) return;
    state = {
      ...state,
      parentId!: thread.copyWith(
        items: [for (final c in thread.items) if (c.id != reply.id) c],
        localIds: {...thread.localIds}..remove(reply.id),
      ),
    };
  }

  CommentModel? find(String commentId) {
    for (final thread in state.values) {
      for (final c in thread.items) {
        if (c.id == commentId) return c;
      }
    }
    return null;
  }
}
