import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/search/data/search_remote_datasource.dart';
import 'package:tiktok_mobile/features/search/data/search_repository.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

part 'search_provider.g.dart';

@Riverpod(keepAlive: true)
SearchRepository searchRepository(Ref ref) =>
    SearchRepository(SearchRemoteDatasource(ref.watch(apiClientProvider)));

const _pageSize = 24;

/// The public leaderboard, hydrated into playable videos.
///
/// Kept out of [SearchResults] on purpose: it is the same list for everyone
/// and needs no token, so it survives the query changing under it and is
/// fetched once per visit rather than once per keystroke.
@riverpod
class TrendingVideos extends _$TrendingVideos {
  @override
  FutureOr<List<VideoModel>> build() {
    return ref.read(feedRepositoryProvider).fetchTrending(limit: _pageSize);
  }
}

/// One search, in relevance order, paged.
///
/// Keyed on both inputs so the results of a query survive switching to a
/// hashtag chip and back. [hashtag] is `''` rather than null so the family key
/// stays a plain pair of strings; the datasource drops empty values.
///
/// Search hits carry no `hlsUrl`, so every page is hydrated through
/// video-service before it is handed over (search doc 4). Ids that vanished
/// between indexing and now simply come back short — a page can therefore
/// hydrate to fewer rows than it named, or to none, without being the end.
@riverpod
class SearchResults extends _$SearchResults {
  var _page = 0;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<VideoModel>> build(String query, String hashtag) async {
    if (query.isEmpty && hashtag.isEmpty) {
      _more.done = true;
      return [];
    }
    _page = 0;
    return _loadPage();
  }

  Future<List<VideoModel>> _loadPage() async {
    final page = await ref.read(searchRepositoryProvider).searchVideos(
          query: query.isEmpty ? null : query,
          hashtag: hashtag.isEmpty ? null : hashtag,
          page: _page,
          size: _pageSize,
        );
    _more.done = page.last;
    return ref.read(feedRepositoryProvider).fetchByIds(page.ids);
  }

  Future<void> loadMore() => _more.run(() async {
        final current = state.value ?? [];
        _page++;
        final next = await _loadPage();
        final seen = current.map((v) => v.id).toSet();
        state = AsyncData([
          ...current,
          ...next.where((v) => seen.add(v.id)),
        ]);
      });
}

/// Accounts whose handle or display name contains [query], most-followed
/// first — user-service's `GET /users/search`, not search-service, which only
/// indexes videos. Needs a token; Discover is only reachable signed in.
///
/// Declared by hand rather than with `@riverpod`: build_runner currently
/// crashes against this Flutter SDK (its analyzer predates Dart 3.10 syntax),
/// so no new generated provider can be produced. Same shape the generator
/// would emit — an auto-disposed family keyed on the query.
final accountSearchResultsProvider = AsyncNotifierProvider.autoDispose
    .family<AccountSearchResults, List<UserProfileModel>, String>(
  AccountSearchResults.new,
);

class AccountSearchResults
    extends AutoDisposeFamilyAsyncNotifier<List<UserProfileModel>, String> {
  var _page = 0;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<UserProfileModel>> build(String query) async {
    if (query.isEmpty) {
      _more.done = true;
      return [];
    }
    _page = 0;
    return _loadPage();
  }

  Future<List<UserProfileModel>> _loadPage() async {
    final page = await ref
        .read(userRepositoryProvider)
        .searchUsers(arg, page: _page, size: _pageSize);
    _more.done = page.last;
    return page.content;
  }

  Future<void> loadMore() => _more.run(() async {
        final current = state.value ?? [];
        _page++;
        final next = await _loadPage();
        final seen = current.map((u) => u.userId).toSet();
        state = AsyncData([
          ...current,
          ...next.where((u) => seen.add(u.userId)),
        ]);
      });
}
