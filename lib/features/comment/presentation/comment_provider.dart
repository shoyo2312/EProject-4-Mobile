import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';

part 'comment_provider.g.dart';

@Riverpod(keepAlive: true)
CommentRepository commentRepository(Ref ref) =>
    CommentRepository(CommentRemoteDatasource(ref.watch(apiClientProvider)));

@riverpod
class CommentNotifier extends _$CommentNotifier {
  String? _nextCursor;

  @override
  FutureOr<List<CommentModel>> build(String videoId) async {
    final page = await ref.read(commentRepositoryProvider).fetchComments(videoId);
    _nextCursor = page.nextCursor;
    return page.items;
  }

  Future<void> loadMore() async {
    if (_nextCursor == null) return;
    final current = state.value ?? [];
    final page = await ref
        .read(commentRepositoryProvider)
        .fetchComments(videoId, cursor: _nextCursor);
    _nextCursor = page.nextCursor;
    state = AsyncData([...current, ...page.items]);
  }

  Future<void> postComment(String text) async {
    final created = await ref.read(commentRepositoryProvider).postComment(videoId, text);
    final current = state.value ?? [];
    state = AsyncData([created, ...current]);
  }
}
