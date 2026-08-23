import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

part 'comment_provider.g.dart';

@Riverpod(keepAlive: true)
CommentRepository commentRepository(Ref ref) =>
    CommentRepository(CommentRemoteDatasource(ref.watch(apiClientProvider)));

@riverpod
class CommentNotifier extends _$CommentNotifier {
  String? _nextCursor;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<CommentModel>> build(String videoId) async {
    final page = await _fetch();
    return page.items;
  }

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
    try {
      await ref
          .read(profileCacheProvider.notifier)
          .loadMissing(page.items.map((c) => c.userId));
    } on AppException {
      // Names and pictures are decoration; the comments still read fine
      // without them.
    }
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
  Future<void> postComment(String text) async {
    final created = await ref.read(commentRepositoryProvider).postComment(videoId, text);
    final current = state.value ?? [];
    state = AsyncData([created, ...current]);
  }

  /// Own comments only — anything else answers `NOT_COMMENT_OWNER`.
  Future<void> deleteComment(String commentId) async {
    await ref.read(commentRepositoryProvider).deleteComment(videoId, commentId);
    state = AsyncData([
      for (final comment in state.value ?? <CommentModel>[])
        if (comment.id != commentId) comment,
    ]);
  }
}
