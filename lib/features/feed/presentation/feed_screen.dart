import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_sheet.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/feed/presentation/video_player_widget.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageController = PageController();
  int _activeIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, List<VideoModel> videos) {
    setState(() => _activeIndex = index);
    if (index >= videos.length - 2) {
      ref.read(feedNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          feedState.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(feedNotifierProvider),
            ),
            data: (videos) {
              if (videos.isEmpty) {
                return const ErrorView(message: 'No videos yet');
              }
              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: videos.length,
                onPageChanged: (index) => _onPageChanged(index, videos),
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoPlayerWidget(
                        url: video.url,
                        isActive: index == _activeIndex,
                      ),
                      Positioned(
                        left: 12,
                        right: 80,
                        bottom: 24,
                        child: Text(
                          video.caption,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 24,
                        child: _ActionRail(video: video),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton(
                key: const Key('feed_profile_button'),
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () => context.push('/profile'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRail extends ConsumerWidget {
  const _ActionRail({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        IconButton(
          key: Key('feed_like_button_${video.id}'),
          icon: Icon(
            video.isLiked ? Icons.favorite : Icons.favorite_border,
            color: video.isLiked ? Colors.red : Colors.white,
          ),
          onPressed: () => ref.read(feedNotifierProvider.notifier).toggleLike(video.id),
        ),
        Text('${video.likeCount}', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        IconButton(
          key: Key('feed_comment_button_${video.id}'),
          icon: const Icon(Icons.comment, color: Colors.white),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => CommentSheet(videoId: video.id),
          ),
        ),
        Text('${video.commentCount}', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        IconButton(
          key: Key('feed_share_button_${video.id}'),
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {}, // share intent wiring is out of scope for this plan
        ),
        Text('${video.shareCount}', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        IconButton(
          key: Key('feed_save_button_${video.id}'),
          icon: Icon(
            video.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
          onPressed: () => ref.read(feedNotifierProvider.notifier).toggleSave(video.id),
        ),
      ],
    );
  }
}
