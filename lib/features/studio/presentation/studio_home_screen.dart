import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_format.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_comment_tile.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';

/// Nowa Studio's front page: the key numbers for the window, a way into each
/// tool, and the newest posts and comments. The web's sidebar becomes the
/// tool grid — a phone has no room for a sidebar.
class StudioHomeScreen extends ConsumerWidget {
  const StudioHomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(studioOverviewProvider)
      ..invalidate(studioRecentPostsProvider)
      ..invalidate(studioRecentCommentsProvider);
    try {
      await ref.read(studioOverviewProvider.future);
    } on AppException {
      // The section shows the error with its own retry.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Nowa Studio'),
      body: RefreshIndicator(
        color: NowaColors.accent,
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: const [
            _ToolGrid(),
            SizedBox(height: 16),
            _KeyMetrics(),
            SizedBox(height: 16),
            _RecentPosts(),
            SizedBox(height: 16),
            _RecentComments(),
          ],
        ),
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid();

  @override
  Widget build(BuildContext context) {
    final tools = [
      (Icons.add_box_outlined, 'Upload', () => context.go('/feed?tab=create')),
      (Icons.video_library_outlined, 'Posts', () => context.push('/studio/posts')),
      (Icons.insights_outlined, 'Analytics', () => context.push('/studio/analytics')),
      (Icons.chat_bubble_outline, 'Comments', () => context.push('/studio/comments')),
      (Icons.lightbulb_outline, 'Inspiration', () => context.push('/studio/inspiration')),
    ];
    return Row(
      children: [
        for (final (icon, label, onTap) in tools)
          Expanded(
            child: InkWell(
              key: Key('studio_tool_${label.toLowerCase()}'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: label == 'Upload'
                            ? NowaColors.accent
                            : NowaColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: work(size: 11.5, height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _KeyMetrics extends ConsumerWidget {
  const _KeyMetrics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(studioRangeProvider);
    final overview = ref.watch(studioOverviewProvider);
    return StudioSection(
      title: 'Key metrics',
      subtitle: rangeLabel(days),
      trailing: TextButton(
        onPressed: () => context.push('/studio/analytics'),
        child: Text('See all', style: sora(size: 12, color: NowaColors.accent)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudioRangeChips(),
          const SizedBox(height: 12),
          overview.when(
            loading: () => const SizedBox(height: 160, child: LoadingView()),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(studioOverviewProvider),
            ),
            data: (data) => MetricGrid(
              tiles: [
                for (final m in overviewMetrics(data))
                  MetricTile(
                    key: Key('studio_metric_${m.key}'),
                    label: m.label,
                    value: m.value,
                    previous: m.previous,
                    onTap: () => context.push('/studio/analytics?metric=${m.key}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPosts extends ConsumerWidget {
  const _RecentPosts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(studioRecentPostsProvider);
    return StudioSection(
      title: 'Recent posts',
      trailing: TextButton(
        onPressed: () => context.push('/studio/posts'),
        child: Text('See all', style: sora(size: 12, color: NowaColors.accent)),
      ),
      child: posts.when(
        loading: () => const SizedBox(height: 120, child: LoadingView()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(studioRecentPostsProvider),
        ),
        data: (videos) => videos.isEmpty
            ? _Empty(
                'No posts yet. Upload your first video to see it here.',
                action: ('Upload', () => context.go('/feed?tab=create')),
              )
            : Column(
                children: [
                  for (final v in videos)
                    StudioPostTile(
                      video: v,
                      onTap: () => context.push('/studio/analytics/${v.id}'),
                    ),
                ],
              ),
      ),
    );
  }
}

class _RecentComments extends ConsumerWidget {
  const _RecentComments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(studioRecentCommentsProvider);
    return StudioSection(
      title: 'Latest comments',
      trailing: TextButton(
        onPressed: () => context.push('/studio/comments'),
        child: Text('See all', style: sora(size: 12, color: NowaColors.accent)),
      ),
      child: comments.when(
        loading: () => const SizedBox(height: 120, child: LoadingView()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(studioRecentCommentsProvider),
        ),
        data: (items) => items.isEmpty
            ? const _Empty('No comments on your videos yet.')
            : Column(
                children: [
                  for (final c in items)
                    StudioCommentTile(
                      comment: c,
                      onTap: () => context.push('/studio/comments'),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message, {this.action});

  final String message;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: work(size: 12.5, color: NowaColors.dim)),
          if (action != null)
            TextButton(
              onPressed: action!.$2,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                action!.$1,
                style: sora(size: 12.5, color: NowaColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}
