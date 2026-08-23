import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Opens the sheet over whatever is on screen. Every video has comments, so
/// this is the single entry point — callers pass a video id and, if they know
/// it, the server-side total for the header.
Future<void> showCommentSheet(
  BuildContext context, {
  required String videoId,
  int? totalCount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x80040306),
    builder: (_) => CommentSheet(videoId: videoId, totalCount: totalCount),
  );
}

class CommentSheet extends ConsumerStatefulWidget {
  const CommentSheet({super.key, required this.videoId, this.totalCount});

  final String videoId;

  /// From `VideoModel.commentCount`; only the loaded page is counted when
  /// this is null.
  final int? totalCount;

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  /// The display name the composer is currently answering, if any. A reply is
  /// ordinary text addressed to that person — the API has no `parentId`.
  String? _replyingTo;

  @override
  void initState() {
    super.initState();
    // Send button turns accent-coloured only once there is something to send.
    _controller.addListener(() => setState(() {}));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      // Cheap to call repeatedly: LoadMoreGuard drops the call once the last
      // page has been read or while a fetch is already in flight.
      ref.read(commentNotifierProvider(widget.videoId).notifier).loadMore();
    }
  }

  /// Locked while the post is in flight: `POST /comments` does not
  /// deduplicate, so a second tap posts a second comment (interaction doc 3.4).
  bool _sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final body = _replyingTo == null ? text : '$_replyingTo $text';
    setState(() => _sending = true);
    _controller.clear();
    try {
      await ref
          .read(commentNotifierProvider(widget.videoId).notifier)
          .postComment(body);
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _replyingTo = null;
        });
      }
    }
  }

  void _startReply(String authorName) {
    setState(() => _replyingTo = authorName);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentNotifierProvider(widget.videoId));
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    final isLoggedIn = myId != null;
    final count = widget.totalCount ?? commentsState.valueOrNull?.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.73,
      decoration: const BoxDecoration(
        color: NowaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: NowaColors.hairline)),
      ),
      child: Column(
        children: [
          _Header(count: count, onClose: () => Navigator.of(context).pop()),
          const Divider(height: 1, color: NowaColors.hairline),
          Expanded(
            child: commentsState.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet',
                      style: work(color: NowaColors.text.withValues(alpha: 0.5)),
                    ),
                  );
                }
                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 18),
                  itemBuilder: (_, index) {
                    final comment = comments[index];
                    return _Row(
                      comment: comment,
                      onReply: _startReply,
                      onDelete: comment.userId == myId
                          ? () => ref
                              .read(commentNotifierProvider(widget.videoId).notifier)
                              .deleteComment(comment.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          isLoggedIn
              ? _Composer(
                  controller: _controller,
                  focusNode: _focusNode,
                  replyingTo: _replyingTo,
                  onCancelReply: () => setState(() => _replyingTo = null),
                  onSend: _send,
                )
              : _SignInPrompt(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/login');
                  },
                ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onClose});

  final int? count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                count == null ? 'Comments' : '${compact(count!)} comments',
                style: sora(size: 15),
              ),
              const Spacer(),
              GestureDetector(
                key: const Key('comment_close_button'),
                onTap: onClose,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One comment. Flat — interaction-service has no replies and no comment
/// likes, so there is no thread to unfold and no heart to fill.
///
/// The name and picture come from the shared profile cache, which the notifier
/// fills in one request per page; an author the cache has no entry for (id
/// gone, or a block relation hiding it) shows the placeholder rather than
/// blocking the row.
class _Row extends ConsumerWidget {
  const _Row({required this.comment, required this.onReply, this.onDelete});

  final CommentModel comment;
  final void Function(String authorName) onReply;

  /// Null for other people's comments — only the author may delete one
  /// (interaction doc 3.6).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = ref.watch(profileCacheProvider)[comment.userId];
    final name = author?.displayName ?? 'user';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: RemoteImage(url: author?.avatarUrl, radius: 18, band: 5),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: sora(size: 12, color: NowaColors.text.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 4),
              Text(comment.text, style: work()),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    timeAgo(comment.createdAt),
                    style: work(
                      size: 11.5,
                      height: 1,
                      color: NowaColors.text.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => onReply(name),
                    child: Text(
                      'Reply',
                      style: work(
                        size: 11.5,
                        weight: FontWeight.w500,
                        height: 1,
                        color: NowaColors.text.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 14),
                    GestureDetector(
                      key: Key('comment_delete_${comment.id}'),
                      onTap: onDelete,
                      child: Text(
                        'Delete',
                        style: work(
                          size: 11.5,
                          weight: FontWeight.w500,
                          height: 1,
                          color: NowaColors.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onCancelReply,
    this.replyingTo,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onCancelReply;
  final String? replyingTo;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        26 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: NowaColors.surface,
        border: Border(top: BorderSide(color: NowaColors.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyingTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Replying to $replyingTo',
                    style: work(
                      size: 12,
                      color: NowaColors.text.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: NowaColors.text.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: NowaColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: TextField(
                      key: const Key('comment_input_field'),
                      controller: controller,
                      focusNode: focusNode,
                      onSubmitted: (_) => onSend(),
                      cursorColor: NowaColors.accent,
                      style: work(size: 13.5, height: 1.2),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText:
                            replyingTo != null ? 'Add a reply' : 'Add a comment',
                        hintStyle: work(
                          size: 13.5,
                          height: 1.2,
                          color: NowaColors.text.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                key: const Key('comment_send_button'),
                onTap: onSend,
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasText
                        ? NowaColors.accent
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NowaColors.surface,
        border: Border(top: BorderSide(color: NowaColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        18,
        16,
        30 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GestureDetector(
        key: const Key('comment_login_prompt'),
        onTap: onTap,
        child: Text(
          'Log in to leave a comment',
          textAlign: TextAlign.center,
          style: sora(size: 13.5, color: NowaColors.accent),
        ),
      ),
    );
  }
}
