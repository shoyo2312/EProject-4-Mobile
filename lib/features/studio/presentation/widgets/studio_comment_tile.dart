import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_provider.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// A comment on one of the creator's videos: who said it, what, on which
/// video, and — when [onLike] and friends are given — what can be done.
class StudioCommentTile extends ConsumerWidget {
  const StudioCommentTile({
    super.key,
    required this.comment,
    this.onTap,
    this.onLike,
    this.onReply,
    this.onApprove,
    this.onDelete,
  });

  final CommentModel comment;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onApprove;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = ref.watch(
      profileCacheProvider.select((cache) => cache[comment.userId]),
    );
    final video = ref.watch(
      studioVideoCacheProvider.select((cache) => cache[comment.videoId]),
    );
    final held = comment.status == CommentStatus.held;
    final hasActions = onLike != null || onReply != null || onDelete != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NowaAvatar(url: author?.avatarUrl, size: 34, radius: 12, border: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          author?.displayName ?? 'Nowa user',
                          style: sora(size: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeAgo(comment.createdAt),
                        style: work(size: 11.5, color: NowaColors.dim),
                      ),
                      if (held) ...[
                        const SizedBox(width: 6),
                        const StudioBadge('Held', color: NowaColors.danger),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    comment.text.isEmpty
                        ? (comment.sticker != null ? '[Sticker]' : '')
                        : comment.text,
                    style: work(size: 13.5, height: 1.35),
                    maxLines: hasActions ? 6 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasActions) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (onApprove != null && held)
                          _Action(
                            key: Key('studio_comment_approve_${comment.id}'),
                            icon: Icons.check_circle_outline,
                            label: 'Approve',
                            color: NowaColors.supportInk,
                            onTap: onApprove!,
                          ),
                        if (onLike != null && !held)
                          _Action(
                            icon: comment.likedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: compact(comment.likeCount),
                            color: comment.likedByMe
                                ? NowaColors.accent
                                : NowaColors.dim,
                            onTap: onLike!,
                          ),
                        if (onReply != null && !held)
                          _Action(
                            icon: Icons.reply_rounded,
                            label: comment.replyCount > 0
                                ? 'Reply · ${comment.replyCount}'
                                : 'Reply',
                            onTap: onReply!,
                          ),
                        if (onDelete != null)
                          _Action(
                            key: Key('studio_comment_delete_${comment.id}'),
                            icon: Icons.delete_outline,
                            label: held ? 'Reject' : 'Delete',
                            onTap: onDelete!,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            StudioThumb(url: video?.thumbnailUrl, width: 36),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = NowaColors.dim,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label, style: work(size: 12, color: color, height: 1.2)),
          ],
        ),
      ),
    );
  }
}
