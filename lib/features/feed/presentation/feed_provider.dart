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

/// Appends [next] to [current], dropping ids already on screen.
///
/// The feed is offset-paginated over a list that grows at the front, so a
/// video uploaded between two page loads pushes older rows down and they come
/// back a second time on the following page. There is no cursor API yet
/// (video doc section 2), so de-duplication has to happen here.
List<VideoModel> _appendDistinct(List<VideoModel> current, List<VideoModel> next) {
  final seen = current.map((v) => v.id).toSet();
  return [...current, ...next.where((v) => seen.add(v.id))];
}

@riverpod
class FeedNotifier extends _$FeedNotifier {
  int _page = 0;
  bool _last = false;

  @override
  FutureOr<List<VideoModel>> build() async {
    final page = await ref.read(feedRepositoryProvider).fetchFeed();
    _page = 0;
    _last = page.last;
    return page.content;
  }

  Future<void> loadMore() async {
    if (_last) return;
    final nextPage = _page + 1;
    final page = await ref.read(feedRepositoryProvider).fetchFeed(page: nextPage);
    _page = nextPage;
    _last = page.last;
    state = AsyncData(_appendDistinct(state.value ?? [], page.content));
  }
}

/// One user's videos. For the caller's own id the server also returns
/// PROCESSING, PRIVATE, FAILED and TAKEN_DOWN items — this backs "My videos".
@riverpod
class UserVideosNotifier extends _$UserVideosNotifier {
  int _page = 0;
  bool _last = false;

  @override
  FutureOr<List<VideoModel>> build(String userId) async {
    final page = await ref.read(feedRepositoryProvider).getUserVideos(userId);
    _page = 0;
    _last = page.last;
    return page.content;
  }

  Future<void> loadMore() async {
    if (_last) return;
    final nextPage = _page + 1;
    final page = await ref
        .read(feedRepositoryProvider)
        .getUserVideos(userId, page: nextPage);
    _page = nextPage;
    _last = page.last;
    state = AsyncData(_appendDistinct(state.value ?? [], page.content));
  }

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
