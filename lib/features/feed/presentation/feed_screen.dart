import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/action_rail.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_sheet.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/feed/presentation/share_sheet.dart';
import 'package:tiktok_mobile/features/feed/presentation/video_player_widget.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';
import 'package:video_player/video_player.dart' show VideoPlayerController;

/// Full-screen vertical feed: PageView, glass action rail, double-tap to like.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, this.visible = true, this.onOpenDiscover});

  /// False while another tab of the shell is on screen. The feed stays mounted
  /// inside the IndexedStack, so nothing else would stop playback.
  final bool visible;

  /// Set by the shell so the magnifier in the top bar switches tabs. Null when
  /// the feed is pushed on its own (tests, deep links).
  final VoidCallback? onOpenDiscover;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageController = PageController();
  int _activeIndex = 0;
  String _tab = 'For You';

  // Local-only: interaction-service exposes no like/save endpoint yet, so
  // these live in the widget and reset with the screen. Swap the two setters
  // for repository calls once the API lands.
  final _liked = <String>{};
  final _saved = <String>{};

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

    return Stack(
      children: [
        feedState.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(feedNotifierProvider),
          ),
          data: (videos) {
            if (videos.isEmpty) return const ErrorView(message: 'No videos yet');
            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              onPageChanged: (index) => _onPageChanged(index, videos),
              itemBuilder: (context, index) {
                final video = videos[index];
                return FeedVideoPanel(
                  video: video,
                  isActive: index == _activeIndex && widget.visible,
                  liked: _liked.contains(video.id),
                  saved: _saved.contains(video.id),
                  onLike: () => setState(() => _liked.contains(video.id)
                      ? _liked.remove(video.id)
                      : _liked.add(video.id)),
                  onSave: () => setState(() => _saved.contains(video.id)
                      ? _saved.remove(video.id)
                      : _saved.add(video.id)),
                );
              },
            );
          },
        ),
        Positioned(
          left: 14,
          right: 14,
          top: MediaQuery.of(context).padding.top + 10,
          child: _TopBar(
            tab: _tab,
            onTab: (t) => setState(() => _tab = t),
            onSearch: widget.onOpenDiscover,
          ),
        ),
      ],
    );
  }
}

/// LIVE badge, source chips, search. There is a single feed endpoint, so the
/// chips mark the intent rather than switching data sources.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.tab, required this.onTab, this.onSearch});

  final String tab;
  final ValueChanged<String> onTab;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: NowaColors.accent.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('LIVE', style: sora(size: 11.5, spacing: 0.6, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in ['Friends', 'Following', 'For You'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip2(label: t, active: t == tab, onTap: () => onTab(t)),
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onSearch,
          child: Glass(
            radius: 11,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.search, size: 17, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// One full-screen clip: player, caption, seek bar and action rail. Shared by
/// the feed and by the viewer opened from a profile grid.
class FeedVideoPanel extends ConsumerStatefulWidget {
  const FeedVideoPanel({
    super.key,
    required this.video,
    required this.isActive,
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
  });

  final VideoModel video;
  final bool isActive;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;

  @override
  ConsumerState<FeedVideoPanel> createState() => _FeedVideoPanelState();
}

class _FeedVideoPanelState extends ConsumerState<FeedVideoPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  bool _paused = false;

  /// Filled in by the player once its controller is ready, so the seek bar can
  /// live in this column instead of on top of the video.
  final _controllerSink = ValueNotifier<VideoPlayerController?>(null);

  @override
  void dispose() {
    _controllerSink.dispose();
    _burst.dispose();
    super.dispose();
  }

  // onTap and onDoubleTap share one detector: the single tap is held back
  // until the double-tap window closes, so liking never pauses on the way.
  void _doubleTap() {
    if (!widget.liked) widget.onLike();
    _burst.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant FeedVideoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scrolling a paused clip out of view and back should not keep it frozen.
    if (!widget.isActive && _paused) _paused = false;
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    return GestureDetector(
      onTap: () => setState(() => _paused = !_paused),
      onDoubleTap: _doubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // /feed only ever returns PUBLISHED videos, so hlsUrl is populated;
          // the striped frame is the fallback for anything else.
          if (video.hlsUrl != null)
            VideoPlayerWidget(
              url: video.hlsUrl!,
              isActive: widget.isActive,
              paused: _paused,
              controllerSink: _controllerSink,
            )
          else
            // Not playable: PROCESSING/FAILED clips never reach /feed, but a
            // deep-linked one would land here.
            const StripedPlaceholder(label: 'video unavailable', fontSize: 12),
          const _Scrims(),
          _pauseBadge(),
          _burstHeart(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 86 + MediaQuery.of(context).padding.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Caption(video: video),
                const SizedBox(height: 12),
                // Above the rail, so the counters never sit on top of it.
                ValueListenableBuilder<VideoPlayerController?>(
                  valueListenable: _controllerSink,
                  builder: (context, controller, _) => controller == null
                      ? const SizedBox(height: 22)
                      : FeedSeekBar(controller: controller, showKnob: _paused),
                ),
                const SizedBox(height: 10),
                _Rail(
                  video: video,
                  liked: widget.liked,
                  saved: widget.saved,
                  onLike: widget.onLike,
                  onSave: widget.onSave,
                  onShare: () => showShareSheet(context, video: video),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Only drawn while paused — playing back is the quiet state, so nothing
  /// sits on top of the video then.
  Widget _pauseBadge() {
    return IgnorePointer(
      child: Center(
        child: AnimatedScale(
          scale: _paused ? 1 : 0.6,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _paused ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            child: Container(
              key: const Key('feed_pause_badge'),
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.34),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 46,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _burstHeart() {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.12),
        child: AnimatedBuilder(
          animation: _burst,
          builder: (_, _) {
            final t = _burst.value;
            if (t == 0 || t == 1) return const SizedBox.shrink();
            final scale = t < 0.3 ? 0.35 + (t / 0.3) * 0.83 : 1.18 - (t - 0.3) * 0.26;
            final opacity = t < 0.3 ? t / 0.3 : 1 - (t - 0.3) / 0.7;
            return Opacity(
              opacity: opacity.clamp(0, 1),
              child: Transform.scale(
                scale: scale,
                child: const Icon(Icons.favorite, size: 130, color: NowaColors.accent),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Scrims extends StatelessWidget {
  const _Scrims();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xB8060508), Color(0x00060508)],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 400,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xDB060508), Color(0x59060508), Color(0x00060508)],
                    stops: [0.12, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends ConsumerWidget {
  const _Caption({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider(video.userId)).valueOrNull;
    final author = profileState?.profile;
    final me = ref.watch(authStateProvider).valueOrNull;
    final isMe = me?.id == video.userId;
    final following = profileState?.isFollowing == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/profile/${video.userId}'),
              child: NowaAvatar(url: author?.avatarUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/profile/${video.userId}'),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author?.displayName ?? '…',
                      style: sora(size: 15, spacing: -0.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${timeAgo(video.createdAt)} · ${compact(video.viewCount)} views',
                      style: work(size: 12, height: 1.2, color: NowaColors.dim),
                    ),
                  ],
                ),
              ),
            ),
            // Hidden on your own videos — there is nobody to follow there.
            if (!isMe && profileState != null)
              GestureDetector(
                key: Key('feed_follow_button_${video.id}'),
                onTap: () => ref
                    .read(profileNotifierProvider(video.userId).notifier)
                    .toggleFollow(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: following ? Colors.transparent : NowaColors.accent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: following
                          ? Colors.white.withValues(alpha: 0.3)
                          : NowaColors.accent,
                    ),
                  ),
                  child: Text(
                    following ? 'Following' : 'Follow',
                    style: sora(
                      size: 12.5,
                      color: following
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(video.title, style: sora(size: 14, spacing: -0.1)),
        if (video.description != null && video.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            video.description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: work(
              size: 13.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
        if (video.durationSeconds != null) ...[
          const SizedBox(height: 12),
          _DurationPill(seconds: video.durationSeconds!),
        ],
      ],
    );
  }
}

/// The design's sound pill. The API carries no audio track, so the slot shows
/// the one piece of clip metadata it does return.
class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final label = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: NowaColors.support.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: NowaColors.support.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_outline, size: 13, color: NowaColors.supportInk),
            const SizedBox(width: 7),
            Text(
              label,
              style: sora(
                size: 11.5,
                weight: FontWeight.w500,
                color: const Color(0xFF9FE6F2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Like and save are visual-only for now: interaction-service has no endpoint
/// behind them, so the counters stay at the server value and only the icon
/// reacts. Comment and the view counter are real.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.video,
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
    required this.onShare,
  });

  final VideoModel video;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return ActionRail(
      actions: [
        RailAction(
          itemKey: Key('feed_like_count_${video.id}'),
          icon: liked ? Icons.favorite : Icons.favorite_border,
          color: liked ? NowaColors.accent : Colors.white,
          label: compact(video.likeCount + (liked ? 1 : 0)),
          onTap: onLike,
        ),
        RailAction(
          itemKey: Key('feed_comment_count_${video.id}'),
          icon: Icons.mode_comment_outlined,
          label: compact(video.commentCount),
          onTap: () => showCommentSheet(
            context,
            videoId: video.id,
            totalCount: video.commentCount,
          ),
        ),
        RailAction(
          itemKey: Key('feed_save_button_${video.id}'),
          icon: saved ? Icons.bookmark : Icons.bookmark_border,
          color: saved ? NowaColors.supportInk : Colors.white,
          // No saveCount from the API means no number to show — fall back to
          // the verb so the slot never reads "0".
          label: video.saveCount == 0
              ? (saved ? 'Saved' : 'Save')
              : compact(video.saveCount + (saved ? 1 : 0)),
          onTap: onSave,
        ),
        RailAction(
          itemKey: Key('feed_share_button_${video.id}'),
          icon: Icons.reply_rounded,
          label: video.shareCount == 0 ? 'Share' : compact(video.shareCount),
          onTap: onShare,
        ),
      ],
    );
  }
}
