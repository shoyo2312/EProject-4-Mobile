import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Ideas for the next post: what is trending on Nowa now, and the videos the
/// creator saved. TikTok's third tab, Recommended, has no backend yet.
class StudioInspirationScreen extends StatelessWidget {
  const StudioInspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: NowaColors.bg,
        appBar: const NowaAppBar(title: 'Inspiration'),
        body: Column(
          children: [
            TabBar(
              indicatorColor: NowaColors.accent,
              labelColor: NowaColors.text,
              unselectedLabelColor: NowaColors.dim,
              labelStyle: sora(size: 13),
              dividerColor: NowaColors.hairline,
              tabs: const [Tab(text: 'Trending'), Tab(text: 'My inspiration')],
            ),
            const Expanded(
              child: TabBarView(children: [_TrendingTab(), _SavedTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingTab extends ConsumerWidget {
  const _TrendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(studioTrendingProvider);
    return RefreshIndicator(
      color: NowaColors.accent,
      onRefresh: () => studioRefresh(ref.refresh(studioTrendingProvider.future)),
      child: videos.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(studioTrendingProvider),
        ),
        data: (list) => _VideoGrid(
          videos: list,
          empty: 'Nothing is trending right now. Check back soon.',
          ranked: true,
        ),
      ),
    );
  }
}

class _SavedTab extends ConsumerWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(studioSavedVideosProvider);
    return RefreshIndicator(
      color: NowaColors.accent,
      onRefresh: () =>
          studioRefresh(ref.refresh(studioSavedVideosProvider.future)),
      child: videos.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(studioSavedVideosProvider),
        ),
        data: (list) => _VideoGrid(
          videos: list,
          empty: 'Save videos you like from the feed and they show up here.',
          onNearEnd: () =>
              ref.read(studioSavedVideosProvider.notifier).loadMore(),
        ),
      ),
    );
  }
}

class _VideoGrid extends ConsumerWidget {
  const _VideoGrid({
    required this.videos,
    required this.empty,
    this.ranked = false,
    this.onNearEnd,
  });

  final List<VideoModel> videos;
  final String empty;
  final bool ranked;
  final VoidCallback? onNearEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (videos.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(empty,
                textAlign: TextAlign.center,
                style: work(size: 13, color: NowaColors.dim)),
          ),
        ],
      );
    }
    final authors = ref.watch(profileCacheProvider);
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (onNearEnd != null && n.metrics.extentAfter < 400) onNearEnd!();
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
          childAspectRatio: 0.56,
        ),
        itemCount: videos.length,
        itemBuilder: (context, i) {
          final v = videos[i];
          return GestureDetector(
            key: Key('studio_inspiration_${v.id}'),
            onTap: () => context.push('/video/${v.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RemoteImage(url: v.thumbnailUrl, radius: 10, band: 6),
                      if (ranked)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: StudioBadge('#${i + 1}', color: Colors.white),
                        ),
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Row(
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                size: 14, color: Colors.white),
                            Text(compact(v.viewCount),
                                style: sora(size: 11, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  v.title,
                  style: work(size: 11.5, height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  authors[v.userId]?.displayName ?? '',
                  style: work(size: 10.5, color: NowaColors.dim, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
