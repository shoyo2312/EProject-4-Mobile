import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// "Who watched my story" — owner-only, newest first, with each viewer's
/// reaction.
Future<void> showStoryViewersSheet(
  BuildContext context, {
  required StoryModel story,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NowaColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.6,
      child: _ViewersSheet(story: story),
    ),
  );
}

class _ViewersSheet extends ConsumerWidget {
  const _ViewersSheet({required this.story});

  final StoryModel story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storyViewersProvider(story.id);
    final viewers = ref.watch(provider);
    final profiles = ref.watch(profileCacheProvider);

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: NowaColors.hairline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                '${story.viewCount ?? 0} ${story.viewCount == 1 ? 'view' : 'views'}',
                style: sora(size: 15),
              ),
            ],
          ),
        ),
        const Divider(color: NowaColors.hairline, height: 1),
        Expanded(
          child: viewers.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(provider),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return Center(
                  child: Text(
                    'No one has watched this story yet',
                    style: work(size: 13, color: NowaColors.dim),
                  ),
                );
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 200) {
                    ref.read(provider.notifier).loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final profile = profiles[row.viewerId];
                    return ListTile(
                      key: Key('story_viewer_${row.viewerId}'),
                      onTap: () {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        router.push('/profile/${row.viewerId}');
                      },
                      leading: NowaAvatar(
                        url: profile?.avatarUrl,
                        size: 40,
                        radius: 14,
                      ),
                      title: Text(
                        profile?.displayName ?? 'Nowa user',
                        style: sora(size: 13.5),
                      ),
                      subtitle: Text(
                        timeAgo(row.viewedAt),
                        style: work(size: 12, color: NowaColors.dim),
                      ),
                      trailing: row.reaction == null
                          ? null
                          : Text(
                              row.reaction!.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
