import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/badge_count.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/conversation_row.dart';
import 'package:tiktok_mobile/features/notification/presentation/notification_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_tray.dart';

/// The Inbox tab: one "Activity" entry on top that opens the notification
/// list, a "Message requests" entry while any wait, then the direct-message
/// threads, most recently active first.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final top = MediaQuery.of(context).padding.top;

    final header = SliverPadding(
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 14),
      sliver: SliverToBoxAdapter(
        child: Text('Inbox', style: sora(size: 26, spacing: -0.6)),
      ),
    );

    if (me == null) {
      return CustomScrollView(
        slivers: [
          header,
          SliverToBoxAdapter(
            child: _Empty(
              message: 'Sign in to see your messages and activity',
              action: TextButton(
                onPressed: () => context.push('/login'),
                child: Text(
                  'Sign in',
                  style: work(size: 13, color: NowaColors.accent),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final conversations = ref.watch(conversationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(inboxProvider);
        ref.invalidate(conversationsProvider);
        ref.invalidate(messageRequestsProvider);
        ref.invalidate(storyTrayProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          header,
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            sliver: SliverToBoxAdapter(child: StoryTrayRow()),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _ActivityEntry()),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _RequestsEntry()),
          ),
          ...conversations.when(
            loading: () => const [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: LoadingView(),
                ),
              ),
            ],
            error: (error, _) => [
              SliverToBoxAdapter(
                child: ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
              ),
            ],
            data: (rows) => rows.isEmpty
                ? const [
                    SliverToBoxAdapter(
                      child: _Empty(message: 'No conversations yet'),
                    ),
                  ]
                : [
                    SliverPadding(
                      // Clears the floating nav bar.
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
                      sliver: SliverList.builder(
                        itemCount: rows.length,
                        itemBuilder: (_, i) =>
                            ConversationRow(conversation: rows[i], me: me.id),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

/// The single row standing in for every notification, like TikTok's
/// "Activity": the newest one as a preview and how many are still unread.
class _ActivityEntry extends ConsumerWidget {
  const _ActivityEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(inboxProvider).valueOrNull ?? const [];
    final unread = all.where((n) => !n.read).length;
    final latest = all.isEmpty ? null : all.first;

    return GestureDetector(
      key: const Key('inbox_open_activity'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/notifications'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: NowaColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity', style: sora(size: 13.5, height: 1.3)),
                  const SizedBox(height: 3),
                  Text(
                    latest == null
                        ? 'No activity yet'
                        : '${latest.title} · ${timeAgo(latest.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: work(
                      size: 12.5,
                      height: 1.4,
                      color: NowaColors.text.withValues(
                        alpha: unread > 0 ? 0.9 : 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (unread > 0)
              Container(
                key: const Key('inbox_activity_unread'),
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NowaColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount(unread),
                  style: work(size: 11, height: 1, color: Colors.white),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: NowaColors.text.withValues(alpha: 0.35),
              ),
          ],
        ),
      ),
    );
  }
}

/// The door to the message-request box, shown only while something waits in
/// it. The subtitle counts the requests; the badge, the ones not opened yet.
class _RequestsEntry extends ConsumerWidget {
  const _RequestsEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(requestCountsProvider);
    if (counts.pending == 0) return const SizedBox.shrink();

    return GestureDetector(
      key: const Key('inbox_open_requests'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/messages/requests'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: NowaColors.surfaceHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_chat_unread_outlined,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message requests',
                    style: sora(size: 13.5, height: 1.3),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'You have ${counts.pending} '
                    '${counts.pending == 1 ? 'request' : 'requests'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: work(
                      size: 12.5,
                      height: 1.4,
                      color: NowaColors.text.withValues(
                        alpha: counts.unread > 0 ? 0.9 : 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (counts.unread > 0)
              Container(
                key: const Key('inbox_requests_unread'),
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NowaColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount(counts.unread),
                  style: work(size: 11, height: 1, color: Colors.white),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: NowaColors.text.withValues(alpha: 0.35),
              ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Text(
            message,
            style: work(
              size: 13,
              color: NowaColors.text.withValues(alpha: 0.45),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
