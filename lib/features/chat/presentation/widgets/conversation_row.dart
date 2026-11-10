import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/conversation_actions.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// One thread in the Inbox list: the other person, the last message, when it
/// arrived and whether it is still unread. Tapping opens the thread; a long
/// press offers pin, mute, report, block, delete and the profile.
class ConversationRow extends ConsumerWidget {
  const ConversationRow({
    super.key,
    required this.conversation,
    required this.me,
    this.request = false,
  });

  final ConversationModel conversation;
  final String me;

  /// A row in the message-request box: it is answered from inside the
  /// thread, so there is no long-press menu, and since a request holds one
  /// message its unread mark is the number 1 rather than a dot.
  final bool request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherId = conversation.otherParticipant(me);
    // Resolved in one batch when the list loaded; a row whose profile is
    // missing (deleted, or blocked either way) still shows the thread.
    final profile = ref.watch(profileCacheProvider)[otherId];
    final last = conversation.lastMessageContent;
    final muted = conversation.muted;

    return GestureDetector(
      key: Key('conversation_${conversation.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/messages/${conversation.id}'),
      onLongPress: request
          ? null
          : () {
              HapticFeedback.selectionClick();
              showConversationActions(
                context,
                ref,
                conversation: conversation,
                me: me,
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            NowaAvatar(url: profile?.avatarUrl, size: 46, radius: 23),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile?.displayName ?? 'user $otherId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sora(size: 13.5, height: 1.3),
                        ),
                      ),
                      if (conversation.pinned) ...[
                        const SizedBox(width: 5),
                        Icon(
                          Icons.push_pin,
                          key: Key('conversation_pinned_${conversation.id}'),
                          size: 13,
                          color: NowaColors.text.withValues(alpha: 0.45),
                        ),
                      ],
                      if (muted) ...[
                        const SizedBox(width: 5),
                        Icon(
                          Icons.notifications_off_outlined,
                          key: Key('conversation_muted_${conversation.id}'),
                          size: 13,
                          color: NowaColors.text.withValues(alpha: 0.45),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    last ?? 'Say hi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: work(
                      size: 12.5,
                      height: 1.4,
                      color: NowaColors.text.withValues(
                        alpha: conversation.hasUnread ? 0.9 : 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (conversation.lastMessageAt case final at?)
              Text(
                timeAgo(at),
                style: work(
                  size: 11,
                  height: 1,
                  color: NowaColors.text.withValues(alpha: 0.35),
                ),
              ),
            if (conversation.hasUnread && request) ...[
              const SizedBox(width: 10),
              Container(
                key: Key('conversation_unread_count_${conversation.id}'),
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: muted
                      ? NowaColors.text.withValues(alpha: 0.35)
                      : NowaColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '1',
                  style: work(size: 10.5, height: 1, color: Colors.white),
                ),
              ),
            ] else if (conversation.hasUnread) ...[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                // Muted: still unread, but not calling for attention.
                decoration: BoxDecoration(
                  color: muted
                      ? NowaColors.text.withValues(alpha: 0.35)
                      : NowaColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
