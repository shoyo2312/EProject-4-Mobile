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

  /// Top-level comments whose replies are currently unfolded.
  final _expanded = <String>{};

  /// The comment the composer is currently answering, if any.
  CommentModel? _replyingTo;

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
      // Cheap to call repeatedly: loadMore() returns immediately once the
      // last page has been read.
      ref.read(commentNotifierProvider(widget.videoId).notifier).loadMore();
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // The API takes a flat comment — a reply is posted as ordinary text
    // addressed to the person being answered until /comments accepts a
    // parentId.
    final body = _replyingTo == null ? text : '${_replyingTo!.username} $text';
    ref.read(commentNotifierProvider(widget.videoId).notifier).postComment(body);
    _controller.clear();
    setState(() => _replyingTo = null);
  }

  void _startReply(CommentModel comment, {String? threadId}) {
    setState(() {
      _replyingTo = comment;
      if (threadId != null) _expanded.add(threadId);
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentNotifierProvider(widget.videoId));
    final isLoggedIn = ref.watch(authStateProvider).valueOrNull != null;
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
                  itemBuilder: (_, index) => _Thread(
                    comment: comments[index],
                    expanded: _expanded.contains(comments[index].id),
                    onToggle: () => setState(() {
                      final id = comments[index].id;
                      _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
                    }),
                    onReply: _startReply,
                  ),
                );
              },
            ),
          ),
          isLoggedIn
              ? _Composer(
                  controller: _controller,
                  focusNode: _focusNode,
                  replyingTo: _replyingTo?.username,
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

/// A top-level comment plus its flat replies — one level deep, no nesting.
class _Thread extends StatelessWidget {
  const _Thread({
    required this.comment,
    required this.expanded,
    required this.onToggle,
    required this.onReply,
  });

  final CommentModel comment;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(CommentModel comment, {String? threadId}) onReply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(comment: comment, onReply: () => onReply(comment)),
        if (comment.replyCount > 0) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 47),
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 24, height: 1, color: NowaColors.hairline),
                  const SizedBox(width: 8),
                  Text(
                    expanded
                        ? 'Hide replies'
                        : 'View ${comment.replyCount} '
                            '${comment.replyCount == 1 ? 'reply' : 'replies'}',
                    style: work(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: NowaColors.text.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 47, top: 14),
              child: Column(
                children: [
                  for (final reply in comment.replies) ...[
                    _Row(
                      comment: reply,
                      isReply: true,
                      onReply: () => onReply(reply, threadId: comment.id),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.comment, required this.onReply, this.isReply = false});

  final CommentModel comment;
  final VoidCallback onReply;

  /// Replies sit indented and one size smaller than their parent.
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isReply ? 28.0 : 36.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: RemoteImage(
            url: comment.avatarUrl,
            radius: avatarSize / 2,
            band: 5,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.username,
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
                    onTap: onReply,
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
                ],
              ),
            ],
          ),
        ),
        // Read-only: liking a comment needs interaction-service.
        Column(
          children: [
            Icon(
              Icons.favorite_border,
              size: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              compact(comment.likeCount),
              style: sora(
                size: 10.5,
                weight: FontWeight.w500,
                color: NowaColors.text.withValues(alpha: 0.45),
              ),
            ),
          ],
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
