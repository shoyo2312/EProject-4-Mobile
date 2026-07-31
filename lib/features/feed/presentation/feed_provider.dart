import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

part 'feed_provider.g.dart';

@Riverpod(keepAlive: true)
FeedRepository feedRepository(Ref ref) =>
    FeedRepository(FeedRemoteDatasource(ref.watch(apiClientProvider)));

@riverpod
class FeedNotifier extends _$FeedNotifier {
  String? _nextCursor;

  @override
  FutureOr<List<VideoModel>> build() async {
    final page = await ref.read(feedRepositoryProvider).fetchFeed();
    _nextCursor = page.nextCursor;
    return page.items;
  }

  Future<void> loadMore() async {
    if (_nextCursor == null) return;
    final current = state.value ?? [];
    final page = await ref.read(feedRepositoryProvider).fetchFeed(cursor: _nextCursor);
    _nextCursor = page.nextCursor;
    state = AsyncData([...current, ...page.items]);
  }

  Future<void> toggleLike(String videoId) async {
    final updated = await ref.read(feedRepositoryProvider).toggleLike(videoId);
    _replace(updated);
  }

  Future<void> toggleSave(String videoId) async {
    final updated = await ref.read(feedRepositoryProvider).toggleSave(videoId);
    _replace(updated);
  }

  void _replace(VideoModel updated) {
    final current = state.value ?? [];
    state = AsyncData([
      for (final video in current)
        if (video.id == updated.id) updated else video,
    ]);
  }
}
