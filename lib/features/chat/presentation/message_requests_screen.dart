import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/conversation_row.dart';

/// Message requests: the threads people the caller does not follow back
/// opened, each with the one message they were allowed. Opening a row reads
/// it; it stays here until it is accepted, which moves it to the inbox, or
/// deleted, which removes it from here.
class MessageRequestsScreen extends ConsumerWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final requests = ref.watch(messageRequestsProvider);

    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: const NowaAppBar(title: 'Message requests'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(messageRequestsProvider.future),
        child: requests.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: 'Couldn\'t load message requests',
            onRetry: () => ref.invalidate(messageRequestsProvider),
          ),
          data: (rows) => rows.isEmpty || me == null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [_Empty()],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => ConversationRow(
                    conversation: rows[i],
                    me: me.id,
                    request: true,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('message_requests_empty'),
      padding: const EdgeInsets.fromLTRB(32, 72, 32, 32),
      child: Column(
        children: [
          Icon(
            Icons.mark_chat_unread_outlined,
            size: 40,
            color: NowaColors.text.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 14),
          Text('No message requests', style: sora(size: 15)),
          const SizedBox(height: 6),
          Text(
            'When someone you don\'t follow back messages you, it will show up here.',
            textAlign: TextAlign.center,
            style: work(
              size: 13,
              height: 1.45,
              color: NowaColors.text.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
