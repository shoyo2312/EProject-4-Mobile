import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// One conversation: history above, composer below, live updates in between.
///
/// The list is reversed — index 0 is the newest message and sits at the
/// bottom, which is both how the server sorts a page and how a chat is read.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await ref
          .read(threadProvider(widget.conversationId).notifier)
          .send(text);
    } on AppException catch (e) {
      if (!mounted) return;
      // Put the text back rather than losing what was typed.
      _controller.text = text;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final thread = ref.watch(threadProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: NowaAppBar(title: _title(me?.id)),
      body: Column(
        children: [
          Expanded(
            child: thread.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(threadProvider(widget.conversationId)),
              ),
              data: (messages) => NotificationListener<ScrollNotification>(
                // Reversed list: "the end" is older history, at the top.
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                      notification.metrics.extentAfter < 400) {
                    ref
                        .read(threadProvider(widget.conversationId).notifier)
                        .loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _Bubble(
                    message: messages[i],
                    mine: messages[i].senderId == me?.id,
                  ),
                ),
              ),
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  /// The other participant's name, once the conversation and their profile are
  /// both known. Until then the header says "Messages" rather than flashing an
  /// id at the reader.
  String _title(String? me) {
    if (me == null) return 'Messages';
    final conversation = ref
        .watch(conversationsProvider)
        .valueOrNull
        ?.where((c) => c.id == widget.conversationId)
        .firstOrNull;
    if (conversation == null) return 'Messages';
    final otherId = conversation.otherParticipant(me);
    return ref.watch(profileCacheProvider)[otherId]?.displayName ?? 'Messages';
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: NowaColors.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('chat_composer_field'),
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                // The server caps a message at 2000 characters; stopping here
                // beats a 400 after the fact.
                maxLength: 2000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: work(size: 14, height: 1.3),
                cursorColor: NowaColors.accent,
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: 'Message',
                  hintStyle: work(
                    size: 14,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              key: const Key('chat_send_button'),
              behavior: HitTestBehavior.opaque,
              onTap: _send,
              child: Icon(
                Icons.arrow_upward,
                size: 20,
                color: _sending
                    ? NowaColors.accent.withValues(alpha: 0.4)
                    : NowaColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final MessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? NowaColors.accent : NowaColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.content, style: work(size: 13.5, height: 1.35)),
            const SizedBox(height: 3),
            Text(
              timeAgo(message.sentAt),
              style: work(
                size: 10,
                height: 1,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
