import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/video_viewer_screen.dart';
import 'package:tiktok_mobile/features/search/presentation/search_provider.dart';

/// Search + hashtag chips + a grid.
///
/// Two sources, never both: with nothing typed and no chip picked the page is
/// the public trending leaderboard; anything else is a real
/// `GET /search/videos` (relevance-ordered, hashtag-filtered, paged).
///
/// The chips are hashtags, not categories — search-service matches a tag
/// exactly, so `Cats` finds videos tagged `cats` and nothing tagged `cat`.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

const _chips = ['All', 'Cats', 'Food', 'Places', 'Build', 'Music'];

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _cat = 'All';

  /// What the provider is keyed on. Only updated once typing pauses: every
  /// distinct value is a new family entry, so keying it on each keystroke
  /// would fire a request per letter and spend the gateway's per-IP budget on
  /// answers nobody waits for.
  String _query = '';
  Timer? _debounce;

  String get _hashtag => _cat == 'All' ? '' : _cat.toLowerCase();

  bool get _searching => _query.isNotEmpty || _hashtag.isNotEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final next = value.trim();
    if (next == _query) return;
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => setState(() => _query = next),
    );
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final results = _searching
        ? ref.watch(searchResultsProvider(_query, _hashtag))
        : ref.watch(trendingVideosProvider);

    return NotificationListener<ScrollNotification>(
      // Paging exists on the search side only — trending is one fixed-size
      // leaderboard with no page after it.
      onNotification: (notification) {
        if (_searching &&
            notification.metrics.extentAfter < 400 &&
            notification is ScrollUpdateNotification) {
          ref
              .read(searchResultsProvider(_query, _hashtag).notifier)
              .loadMore();
        }
        return false;
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 14,
          16,
          130,
        ),
        children: [
          _searchField(),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in _chips)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip2(
                      label: c,
                      active: c == _cat,
                      onTap: () => setState(() => _cat = c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          results.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: LoadingView(),
            ),
            error: (error, _) => ErrorView(message: error.toString()),
            data: (videos) => _results(videos),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF17151C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 17,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: TextField(
                key: const Key('discover_search_field'),
                controller: _searchController,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                style: work(size: 14, height: 1.2),
                cursorColor: NowaColors.accent,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search videos and hashtags',
                  hintStyle: work(
                    size: 14,
                    height: 1.2,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              key: const Key('discover_search_clear'),
              onTap: _clearQuery,
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _results(List<VideoModel> videos) {
    if (videos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            _searching
                ? 'No results for "${_query.isEmpty ? '#$_hashtag' : _query}"'
                : 'Nothing trending yet',
            style: work(size: 13, color: NowaColors.text.withValues(alpha: 0.45)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_searching) ...[
          const SectionLabel('TRENDING NOW'),
          const SizedBox(height: 11),
          _TopVideos(videos: videos),
          const SizedBox(height: 20),
        ],
        SectionLabel(_searching ? 'RESULTS' : 'FOR YOU'),
        const SizedBox(height: 11),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: videos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 9 / 13,
          ),
          itemBuilder: (_, i) => _Tile(
            video: videos[i],
            onTap: () => _openViewer(videos, videos[i]),
          ),
        ),
      ],
    );
  }

  /// Opens the tapped clip full-screen over the rest of the grid. Only
  /// PUBLISHED videos carry an hlsUrl and search only ever returns those, but
  /// trending is hydrated from ids that may have gone stale — one with nothing
  /// to play is skipped rather than swiped into.
  void _openViewer(List<VideoModel> videos, VideoModel tapped) {
    final playable = videos.where((v) => v.hlsUrl != null).toList();
    final index = playable.indexWhere((v) => v.id == tapped.id);
    if (index == -1) return;
    VideoViewerScreen.open(context, videos: playable, initialIndex: index);
  }
}

/// The three best rows of the leaderboard, in ranking order — not re-sorted by
/// view count: trending scores recency far above raw views, so the order the
/// server sent is the answer.
class _TopVideos extends StatelessWidget {
  const _TopVideos({required this.videos});

  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final video in videos.take(3)) ...[
          GestureDetector(
            onTap: () => context.push('/profile/${video.userId}'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NowaColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: RemoteImage(
                      url: video.thumbnailUrl,
                      radius: 14,
                      band: 5,
                      label: 'art',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sora(size: 13.5),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${compact(video.viewCount)} views',
                          style: work(
                            size: 11.5,
                            height: 1.2,
                            color: NowaColors.text.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    compact(video.likeCount),
                    style: sora(size: 11.5, color: NowaColors.supportInk),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.video, required this.onTap});

  final VideoModel video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('discover_video_${video.id}'),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RemoteImage(url: video.thumbnailUrl, label: video.title),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xB3060508), Color(0x00060508)],
                  stops: [0, 0.5],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      compact(video.viewCount),
                      style: sora(size: 11, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
