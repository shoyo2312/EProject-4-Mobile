import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

/// Search + category chips + a "For You" grid.
///
/// There is no search or trending endpoint yet, so the page browses the feed
/// the app already loaded: the field filters those videos by title/description
/// on the client, and the chips are markers.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _cat = 'All';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 14,
        16,
        130,
      ),
      children: [
        Container(
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
                    onChanged: (value) => setState(() => _query = value.trim()),
                    style: work(size: 14, height: 1.2),
                    cursorColor: NowaColors.accent,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search videos in your feed',
                      hintStyle: work(
                        size: 14,
                        height: 1.2,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() {
                    _searchController.clear();
                    _query = '';
                  }),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in ['All', 'Cats', 'Food', 'Places', 'Build', 'Music'])
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
        const SectionLabel('MOST WATCHED'),
        const SizedBox(height: 11),
        feedState.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: LoadingView(),
          ),
          error: (error, _) => ErrorView(message: error.toString()),
          data: (videos) => _TopVideos(videos: _filter(videos)),
        ),
        const SizedBox(height: 20),
        const SectionLabel('FOR YOU'),
        const SizedBox(height: 11),
        feedState.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (videos) {
            final filtered = _filter(videos);
            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    _query.isEmpty ? 'Nothing to show yet' : 'No matches for "$_query"',
                    style: work(
                      size: 13,
                      color: NowaColors.text.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 9 / 13,
              ),
              itemBuilder: (_, i) => _Tile(video: filtered[i]),
            );
          },
        ),
      ],
    );
  }

  List<VideoModel> _filter(List<VideoModel> videos) {
    if (_query.isEmpty) return videos;
    final q = _query.toLowerCase();
    return [
      for (final v in videos)
        if (v.title.toLowerCase().contains(q) ||
            (v.description?.toLowerCase().contains(q) ?? false))
          v,
    ];
  }
}

/// Stands in for the design's "rising sounds" list — same row shape, filled
/// with the three most-watched clips the feed returned.
class _TopVideos extends StatelessWidget {
  const _TopVideos({required this.videos});

  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    final top = [...videos]..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    if (top.isEmpty) {
      return Text(
        'Nothing to show yet',
        style: work(size: 13, color: NowaColors.text.withValues(alpha: 0.45)),
      );
    }
    return Column(
      children: [
        for (final video in top.take(3)) ...[
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
  const _Tile({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('discover_video_${video.id}'),
      onTap: () => context.push('/profile/${video.userId}'),
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
