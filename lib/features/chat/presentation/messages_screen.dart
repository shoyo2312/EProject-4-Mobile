import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Direct-message threads, most recently active first.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Messages'),
      body: me == null
          ? _empty('Sign in to see your messages')
          : conversations.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(conversationsProvider),
              ),
              data: (rows) => rows.isEmpty
                  ? _empty('No conversations yet')
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(conversationsProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: rows.length,
                        itemBuilder: (_, i) => _ConversationRow(
                          conversation: rows[i],
                          me: me.id,
                        ),
                      ),
                    ),
            ),
    );
  }

  Widget _empty(String message) => Center(
        child: Text(
          message,
          style: work(size: 13, color: NowaColors.text.withValues(alpha: 0.45)),
        ),
      );
}

class _ConversationRow extends ConsumerWidget {
  const _ConversationRow({required this.conversation, required this.me});

  final ConversationModel conversation;
  final String me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherId = conversation.otherParticipant(me);
    // Resolved in one batch when the list loaded; a row whose profile is
    // missing (deleted, or blocked either way) still shows the thread.
    final profile = ref.watch(profileCacheProvider)[otherId];
    final last = conversation.lastMessageContent;

    return GestureDetector(
      key: Key('conversation_${conversation.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/messages/${conversation.id}'),
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
                  Text(
                    profile?.displayName ?? 'user $otherId',
                    style: sora(size: 13.5, height: 1.3),
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
            if (conversation.hasUnread) ...[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: NowaColors.accent,
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
