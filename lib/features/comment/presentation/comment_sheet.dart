import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/media_url.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_mentions.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_report_reasons.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_sticker_sheet.dart';
import 'package:tiktok_mobile/features/comment/presentation/mention_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_flow.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_ring.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Opens the sheet over whatever is on screen. Every video has comments, so
/// this is the single entry point — callers pass a video id and, if they know
/// it, the server-side total for the header and who owns the video.
Future<void> showCommentSheet(
  BuildContext context, {
  required String videoId,
  String? videoOwnerId,
  int? totalCount,
  bool commentsDisabled = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x80040306),
    builder: (_) => CommentSheet(
      videoId: videoId,
      videoOwnerId: videoOwnerId,
      totalCount: totalCount,
      commentsDisabled: commentsDisabled,
    ),
  );
}

class CommentSheet extends ConsumerStatefulWidget {
  const CommentSheet({
    super.key,
    required this.videoId,
    this.videoOwnerId,
    this.totalCount,
    this.commentsDisabled = false,
  });

  final String videoId;

  /// `VideoModel.userId`. The owner may delete any comment on their video
  /// (interaction doc 3.6); null hides that, and the server would refuse a
  /// wrong guess with `NOT_COMMENT_OWNER` anyway.
  final String? videoOwnerId;

  /// From `VideoModel.commentCount`; only the loaded page is counted when
  /// this is null.
  final int? totalCount;

  /// From `VideoModel.commentsDisabled`. The owner switched new comments off;
  /// the ones already posted stay readable, so the sheet still opens.
  final bool commentsDisabled;

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

/// The comment the composer is answering.
typedef _ReplyTarget = ({String commentId, String name});

/// What the server's refusal means to the person who typed it, where the
/// server's own message is not the thing to show.
String _messageFor(AppException e) {
  if (e is ServerException) {
    switch (e.code) {
      case 'COMMENT_EDIT_NEEDS_REVIEW':
        return "This edit needs review and wasn't saved";
      case 'INVALID_STICKER':
        return "This sticker isn't available anymore";
    }
  }
  return e.message;
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  /// Set while the composer answers a comment: the reply goes up with that
  /// comment as its `parentId`.
  _ReplyTarget? _replyTo;

  /// Set while the composer edits one of the viewer's own comments.
  CommentModel? _editing;

  /// The video's comment total as the server last pushed it; null until the
  /// first push, when [CommentSheet.totalCount] stands in.
  int? _liveCount;
  late final List<StreamSubscription<Map<String, dynamic>>> _live;

  @override
  void initState() {
    super.initState();
    // Send button turns accent-coloured only once there is something to send.
    _controller.addListener(() => setState(() {}));
    _scrollController.addListener(_onScroll);
    // Live while open, as on web: new, deleted and liked comments, and the
    // total — a snapshot pushed on every change, so it never drifts.
    final socket = ref.read(chatSocketProvider);
    final topic = '/topic/videos.${widget.videoId}';
    _live = [
      socket
          .topic('$topic.comments')
          .listen((frame) => _notifier.applyRealtime(frame)),
      socket.topic(topic).listen((frame) {
        final count = frame['commentCount'];
        if (frame['type'] == 'counts' && count is int && mounted) {
          setState(() => _liveCount = count);
        }
      }),
    ];
  }

  @override
  void dispose() {
    for (final sub in _live) {
      sub.cancel();
    }
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  CommentNotifier get _notifier =>
      ref.read(commentNotifierProvider(widget.videoId).notifier);

  CommentReplies get _replies =>
      ref.read(commentRepliesProvider(widget.videoId).notifier);

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      // Cheap to call repeatedly: LoadMoreGuard drops the call once the last
      // page has been read or while a fetch is already in flight.
      _notifier.loadMore();
    }
  }

  /// Locked while the post is in flight: `POST /comments` does not
  /// deduplicate, so a second tap posts a second comment (interaction doc 3.4).
  bool _sending = false;

  /// Starts from the video the caller handed over, but the owner can switch
  /// comments off while this sheet is open — the server saying so is the only
  /// way to find out, so the answer to a rejected post updates it.
  late bool _disabled = widget.commentsDisabled;

  void _showError(AppException e) {
    NowaToast.of(context).error(_messageFor(e));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _disabled) return;
    final editing = _editing;
    if (!await _mentionsAllowed(text, original: editing?.text)) return;
    if (!mounted) return;
    if (editing != null) {
      await _saveEdit(editing, text);
    } else {
      await _post(text);
    }
  }

  /// A sticker goes up with whatever is typed as its caption (possibly
  /// nothing), as a reply when the composer is answering someone.
  Future<void> _pickSticker() async {
    if (_sending || _disabled || _editing != null) return;
    final sticker = await showCommentStickerSheet(context);
    if (sticker == null || !mounted) return;
    final caption = _controller.text.trim();
    if (!await _mentionsAllowed(caption) || !mounted) return;
    await _post(caption, stickerId: sticker.stickerId);
  }

  /// The `@word` the cursor is in, while one is being typed.
  ({int start, String query})? _mentionToken() {
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    return mentionTokenAt(_controller.text, selection.baseOffset);
  }

  /// A suggestion picked: the `@word` being typed becomes their handle.
  void _pickMention(UserProfileModel friend) {
    final token = _mentionToken();
    final handle = mentionHandle(friend);
    if (token == null || handle == null) return;
    final applied = applyMention(
      _controller.text,
      token.start,
      _controller.selection.baseOffset,
      handle,
    );
    _controller.value = TextEditingValue(
      text: applied.text,
      selection: TextSelection.collapsed(offset: applied.cursor),
    );
  }

  /// The @ button: starts a tag where the cursor is.
  void _startMention() {
    final value = _controller.value;
    final text = value.text;
    final at = value.selection.isValid
        ? value.selection.baseOffset
        : text.length;
    final needsSpace = at > 0 && !RegExp(r'\s').hasMatch(text[at - 1]);
    final insert = needsSpace ? ' @' : '@';
    _controller.value = TextEditingValue(
      text: text.replaceRange(
        at,
        value.selection.isValid ? value.selection.extentOffset : at,
        insert,
      ),
      selection: TextSelection.collapsed(offset: at + insert.length),
    );
    _focusNode.requestFocus();
  }

  /// Only friends — people the viewer follows who follow them back — can be
  /// tagged. The server reads any `@handle` as a tag, so the rule is kept
  /// here before the comment goes up. A tag already in a comment being
  /// edited is left alone. When the friend list cannot be read, the comment
  /// goes up as written rather than being held back by an outage.
  Future<bool> _mentionsAllowed(String text, {String? original}) async {
    final handles = mentionedHandles(text);
    if (handles.isEmpty) return true;
    final toast = NowaToast.of(context);
    if (handles.length > maxMentions) {
      toast.error('You can tag up to $maxMentions people in one comment');
      return false;
    }
    final kept = original == null
        ? const <String>{}
        : mentionedHandles(original).toSet();
    final List<UserProfileModel> friends;
    final keep = ref.listenManual(mentionFriendsProvider, (_, _) {});
    try {
      friends = await ref.read(mentionFriendsProvider.future);
    } catch (_) {
      return true;
    } finally {
      keep.close();
    }
    final allowed = {
      for (final f in friends)
        if (mentionHandle(f) case final handle?) handle.toLowerCase(),
    };
    final refused = [
      for (final h in handles)
        if (!allowed.contains(h) && !kept.contains(h)) h,
    ];
    if (refused.isEmpty) return true;
    toast.error(
      'You can only tag friends who follow you back. Remove @${refused.first}',
      key: const Key('comment_mention_refused'),
    );
    return false;
  }

  Future<void> _post(String text, {String? stickerId}) async {
    setState(() => _sending = true);
    _controller.clear();
    try {
      final created = await _notifier.postComment(
        text,
        parentId: _replyTo?.commentId,
        stickerId: stickerId,
      );
      if (!mounted) return;
      setState(() => _replyTo = null);
      if (created.status == CommentStatus.held) {
        // Accepted, but kept out of the thread by the filters — without this
        // the comment would just seem to vanish.
        NowaToast.of(context).info(
          "Your comment is under review and isn't visible yet",
          key: const Key('comment_held_notice'),
        );
      }
    } on AppException catch (e) {
      if (!mounted) return;
      // The text goes back in the field rather than being lost: the send
      // failed, and retyping it is not the user's mistake to pay for.
      _controller.text = text;
      setState(() {
        if (e is ServerException && e.code == 'COMMENTS_DISABLED') {
          _disabled = true;
        }
      });
      _showError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _saveEdit(CommentModel comment, String text) async {
    if (text == comment.text) {
      _cancelEdit();
      return;
    }
    setState(() => _sending = true);
    try {
      await _notifier.editComment(comment.id, text);
      if (!mounted) return;
      _controller.clear();
      setState(() => _editing = null);
    } on AppException catch (e) {
      // The edited text stays in the box: nothing was saved.
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startReply(CommentModel comment, String authorName) {
    setState(() {
      if (_editing != null) _controller.clear();
      _editing = null;
      _replyTo = (commentId: comment.id, name: authorName);
    });
    _focusNode.requestFocus();
  }

  void _startEdit(CommentModel comment) {
    setState(() {
      _replyTo = null;
      _editing = comment;
    });
    _controller.text = comment.text;
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    _controller.clear();
    setState(() => _editing = null);
  }

  /// Reading replies and liking need an account: signed out the call would
  /// 401, so the tap closes the sheet and opens the login screen instead of
  /// failing quietly — the same bargain the composer already makes.
  bool _requireSignIn() {
    if (ref.read(authStateProvider).valueOrNull != null) return true;
    Navigator.of(context).pop();
    context.push('/login');
    return false;
  }

  void _likeComment(String commentId) {
    if (!_requireSignIn()) return;
    _notifier.toggleLike(commentId);
  }

  /// The replies endpoint needs a token (interaction doc 3.5b).
  void _openReplies(String parentId) {
    if (!_requireSignIn()) return;
    _replies.open(parentId);
  }

  /// The author and the video's owner delete through interaction-service; an
  /// admin removing anyone else's comment goes through admin-service with a
  /// reason, so it is audited and counts against the author.
  Future<void> _delete(CommentModel comment, {required bool asAdmin}) async {
    final notifier = _notifier;
    String? reason;
    if (asAdmin) {
      reason = await _pickReason(
        context,
        title: 'Why remove this comment?',
        keyPrefix: 'comment_remove_reason',
      );
      if (reason == null) return;
    } else if (!await _confirmDelete(context)) {
      return;
    }
    if (!mounted) return;
    final toast = NowaToast.of(context);
    try {
      if (reason != null) {
        await notifier.removeAsAdmin(comment.id, reason);
      } else {
        await notifier.deleteComment(comment.id);
      }
      if (mounted && _editing?.id == comment.id) _cancelEdit();
    } on AppException catch (e) {
      toast.error(e.message);
    }
  }

  /// The web's report sheet: a scenario, then the rules it covers, then
  /// Submit. The sheet stays up while the report is sent, so a failure can be
  /// tried again without picking the reason a second time.
  Future<void> _report(CommentModel comment) async {
    final notifier = _notifier;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      backgroundColor: NowaColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportSheet(
        onSubmit: (reason) => notifier.report(comment.id, reason),
      ),
    );
    if (sent != true || !mounted) return;
    NowaToast.of(context).success(
      "Thanks for reporting. We'll review this comment.",
      key: const Key('comment_report_sent'),
    );
  }

  /// Top-level comments, each followed by its open thread (or the button
  /// that opens it), as one flat list for the builder.
  List<_Entry> _entries(
    List<CommentModel> comments,
    Map<String, ReplyThread> threads,
  ) {
    final entries = <_Entry>[];
    for (final comment in comments) {
      entries.add(_CommentEntry(comment));
      final thread = threads[comment.id];
      if (thread == null) {
        if (comment.replyCount > 0) entries.add(_ThreadEntry(comment, null));
        continue;
      }
      for (final reply in thread.items) {
        entries.add(_CommentEntry(reply));
      }
      entries.add(_ThreadEntry(comment, thread));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentNotifierProvider(widget.videoId));
    // Watched for the whole life of the sheet: it holds the open threads.
    final threads = ref.watch(commentRepliesProvider(widget.videoId));
    final me = ref.watch(authStateProvider).valueOrNull;
    final myId = me?.id;
    final isLoggedIn = myId != null;
    final isAdmin = me?.role == UserRole.admin;
    final ownsVideo = isLoggedIn && myId == widget.videoOwnerId;
    final count =
        _liveCount ?? widget.totalCount ?? commentsState.valueOrNull?.length;

    Widget row(CommentModel comment) {
      final mine = isLoggedIn && comment.userId == myId;
      return _Row(
        comment: comment,
        onReply: _startReply,
        onLike: _likeComment,
        onEdit: mine ? () => _startEdit(comment) : null,
        onDelete: mine || ownsVideo
            ? () => _delete(comment, asAdmin: false)
            : isAdmin
            ? () => _delete(comment, asAdmin: true)
            : null,
        onReport: isLoggedIn && !mine ? () => _report(comment) : null,
      );
    }

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
                      style: work(
                        color: NowaColors.text.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                final entries = _entries(comments, threads);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (_, index) => switch (entries[index]) {
                    _CommentEntry(:final comment) => Padding(
                      padding: EdgeInsets.only(
                        left: comment.isReply ? 47 : 0,
                        bottom: 18,
                      ),
                      child: row(comment),
                    ),
                    _ThreadEntry(:final parent, :final thread) => Padding(
                      padding: const EdgeInsets.only(left: 47, bottom: 18),
                      child: _ThreadControls(
                        parent: parent,
                        thread: thread,
                        onOpen: () => _openReplies(parent.id),
                        onMore: () => _replies.loadMore(parent.id),
                        onHide: () => _replies.close(parent.id),
                      ),
                    ),
                  },
                );
              },
            ),
          ),
          if (!_disabled && isLoggedIn)
            if (_mentionToken() case final token?)
              _MentionSuggestions(
                friends: ref.watch(mentionFriendsProvider),
                query: token.query,
                onPick: _pickMention,
              ),
          if (_disabled)
            const _CommentsClosed()
          else if (isLoggedIn)
            _Composer(
              onMention: _startMention,
              controller: _controller,
              focusNode: _focusNode,
              replyingTo: _replyTo?.name,
              editing: _editing != null,
              onCancel: _editing != null
                  ? _cancelEdit
                  : () => setState(() => _replyTo = null),
              onSend: _send,
              onSticker: _pickSticker,
            )
          else
            _SignInPrompt(
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

sealed class _Entry {
  const _Entry();
}

class _CommentEntry extends _Entry {
  const _CommentEntry(this.comment);
  final CommentModel comment;
}

/// Under a top-level comment: "View N replies" while the thread is closed,
/// "View more" / "Hide" once it is open.
class _ThreadEntry extends _Entry {
  const _ThreadEntry(this.parent, this.thread);
  final CommentModel parent;
  final ReplyThread? thread;
}

Future<bool> _confirmDelete(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: NowaColors.surfaceHigh,
      title: Text('Delete this comment?', style: sora(size: 15)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: sora(size: 13, color: NowaColors.dim)),
        ),
        TextButton(
          key: const Key('comment_confirm_delete'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Delete',
            style: sora(size: 13, color: NowaColors.danger),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}

/// One of [commentReportReasons], or null if the sheet was dismissed. Each
/// option is keyed `{keyPrefix}_{index}`.
Future<String?> _pickReason(
  BuildContext context, {
  required String title,
  required String keyPrefix,
}) {
  return showModalBottomSheet<String>(
    context: context,
    // Six options outgrow the default half-screen cap on a small or
    // landscape screen; scroll instead of overflowing.
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    backgroundColor: NowaColors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title, style: sora(size: 15)),
            ),
            for (var i = 0; i < commentReportReasons.length; i++)
              ListTile(
                key: Key('${keyPrefix}_$i'),
                title: Text(commentReportReasons[i], style: work()),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: NowaColors.text.withValues(alpha: 0.4),
                ),
                onTap: () => Navigator.of(context).pop(commentReportReasons[i]),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

/// Reporting a comment, as on the web: pick a scenario, read back what it
/// covers ("We don't allow the following"), then Submit. Pops true once the
/// server has the report.
class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.onSubmit});

  final Future<void> Function(String reason) onSubmit;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  CommentReportReason? _picked;
  bool _sending = false;

  Future<void> _submit() async {
    final picked = _picked;
    if (picked == null || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSubmit(picked.label);
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) NowaToast.of(context).error(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    final text = NowaColors.text;
    return SafeArea(
      child: Column(
        key: const Key('comment_report_sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                if (picked != null)
                  IconButton(
                    key: const Key('comment_report_back'),
                    tooltip: 'Back',
                    onPressed: _sending
                        ? null
                        : () => setState(() => _picked = null),
                    icon: Icon(Icons.chevron_left, color: text),
                  )
                else
                  const SizedBox(width: 20),
                Expanded(child: Text('Report', style: sora(size: 17))),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _sending
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: Icon(Icons.close, size: 20, color: text),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: NowaColors.hairline),
          Flexible(
            child: SingleChildScrollView(
              child: picked == null ? _scenarios() : _rules(picked),
            ),
          ),
          if (picked != null) ...[
            const Divider(height: 1, color: NowaColors.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                height: 46,
                child: FilledButton(
                  key: const Key('comment_report_submit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: NowaColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: sora(size: 14, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scenarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text(
            'Please select a scenario',
            style: work(
              size: 13,
              color: NowaColors.text.withValues(alpha: 0.6),
            ),
          ),
        ),
        for (var i = 0; i < commentReportScenarios.length; i++)
          ListTile(
            key: Key('comment_report_reason_$i'),
            title: Text(
              commentReportScenarios[i].label,
              style: work(size: 14.5),
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: 18,
              color: NowaColors.text.withValues(alpha: 0.4),
            ),
            onTap: () => setState(() => _picked = commentReportScenarios[i]),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _rules(CommentReportReason picked) {
    return Column(
      key: const Key('comment_report_rules'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: NowaColors.text.withValues(alpha: 0.07),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Text(picked.label, style: work(size: 16, height: 1.35)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            "We don't allow the following",
            style: work(size: 14.5, weight: FontWeight.w600),
          ),
        ),
        for (final rule in picked.bullets)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: work(size: 14, height: 1.4)),
                Expanded(
                  child: Text(
                    rule,
                    style: work(
                      size: 14,
                      height: 1.4,
                      color: NowaColors.text.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
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

class _ThreadControls extends StatelessWidget {
  const _ThreadControls({
    required this.parent,
    required this.thread,
    required this.onOpen,
    required this.onMore,
    required this.onHide,
  });

  final CommentModel parent;
  final ReplyThread? thread;
  final VoidCallback onOpen;
  final VoidCallback onMore;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final style = work(
      size: 12,
      weight: FontWeight.w500,
      height: 1,
      color: NowaColors.text.withValues(alpha: 0.5),
    );
    Widget link(String key, String label, VoidCallback onTap) =>
        GestureDetector(
          key: Key(key),
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Text(label, style: style),
        );

    final thread = this.thread;
    if (thread == null) {
      final n = parent.replyCount;
      return Align(
        alignment: Alignment.centerLeft,
        child: link(
          'comment_view_replies_${parent.id}',
          'View $n ${n == 1 ? 'reply' : 'replies'}',
          onOpen,
        ),
      );
    }
    final remaining = parent.replyCount - thread.items.length;
    return Row(
      children: [
        if (thread.loading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: NowaColors.dim,
            ),
          )
        else if (thread.error != null)
          link(
            'comment_retry_replies_${parent.id}',
            "Couldn't load replies. Retry",
            onMore,
          )
        else if (thread.hasMore)
          link(
            'comment_more_replies_${parent.id}',
            remaining > 0 ? 'View $remaining more' : 'View more replies',
            onMore,
          ),
        const SizedBox(width: 16),
        link('comment_hide_replies_${parent.id}', 'Hide', onHide),
      ],
    );
  }
}

/// One comment or reply. The name and picture come from the shared profile
/// cache; an author the cache has no entry for (id gone, or a block relation
/// hiding it) shows the placeholder rather than blocking the row.
class _Row extends ConsumerWidget {
  const _Row({
    required this.comment,
    required this.onReply,
    required this.onLike,
    this.onEdit,
    this.onDelete,
    this.onReport,
  });

  final CommentModel comment;
  final void Function(CommentModel comment, String authorName) onReply;
  final void Function(String commentId) onLike;

  /// Set on the viewer's own comments only.
  final VoidCallback? onEdit;

  /// Set for the comment's author, the video's owner and admins.
  final VoidCallback? onDelete;

  /// Set for signed-in viewers on everyone's comments but their own.
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profileCacheProvider);
    final author = profiles[comment.userId];
    final name = author?.displayName ?? 'user';
    final replyToId = comment.replyToUserId;
    final replyTo = replyToId == null
        ? null
        : profiles[replyToId]?.displayName ?? 'user';
    final avatar = comment.isReply ? 28.0 : 36.0;
    final metaStyle = work(
      size: 11.5,
      height: 1,
      color: NowaColors.text.withValues(alpha: 0.4),
    );

    Widget action(
      String key,
      String label,
      VoidCallback onTap, {
      Color? color,
    }) => Padding(
      padding: const EdgeInsets.only(left: 14),
      child: GestureDetector(
        key: Key(key),
        onTap: onTap,
        child: Text(
          label,
          style: work(
            size: 11.5,
            weight: FontWeight.w500,
            height: 1,
            color: color ?? NowaColors.text.withValues(alpha: 0.5),
          ),
        ),
      ),
    );

    final sticker = comment.sticker;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthorAvatar(
          key: Key('comment_avatar_${comment.id}'),
          userId: comment.userId,
          name: name,
          avatarUrl: author?.avatarUrl,
          size: avatar,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                key: Key('comment_author_${comment.id}'),
                children: [
                  _NameLink(
                    key: Key('comment_author_name_${comment.id}'),
                    userId: comment.userId,
                    name: name,
                  ),
                  if (replyTo != null) ...[
                    Text(' ▸ ', style: _nameStyle),
                    _NameLink(
                      key: Key('comment_reply_to_name_${comment.id}'),
                      userId: replyToId!,
                      name: replyTo,
                    ),
                  ],
                ],
              ),
              if (comment.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                _CommentText(
                  key: Key('comment_text_${comment.id}'),
                  text: comment.text,
                ),
              ],
              if (sticker != null) ...[
                const SizedBox(height: 6),
                _StickerView(
                  key: Key('comment_sticker_view_${comment.id}'),
                  sticker: sticker,
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 6,
                children: [
                  Text(timeAgo(comment.createdAt), style: metaStyle),
                  if (comment.editedAt != null)
                    Text(
                      ' · Edited',
                      key: Key('comment_edited_${comment.id}'),
                      style: metaStyle,
                    ),
                  action(
                    'comment_reply_${comment.id}',
                    'Reply',
                    () => onReply(comment, name),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Right-hand column, TikTok's own placement: the heart sits away from
        // the text so a tap meant for it cannot land on Reply.
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: GestureDetector(
            key: Key('comment_like_${comment.id}'),
            onTap: () => onLike(comment.id),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Icon(
                  comment.likedByMe ? Icons.favorite : Icons.favorite_border,
                  size: 15,
                  color: comment.likedByMe
                      ? NowaColors.accent
                      : NowaColors.text.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 3),
                Text(
                  // Nothing rather than a "0" under an empty heart.
                  comment.likeCount == 0 ? '' : compact(comment.likeCount),
                  style: work(
                    size: 11,
                    height: 1,
                    color: NowaColors.text.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    // Copy, Edit, Report and Delete wait behind a long press, so the row
    // itself only carries Reply. The row is lit while its menu is open.
    return _PressHighlight(
      key: Key('comment_row_${comment.id}'),
      onLongPress: () => _openActions(context, name),
      child: row,
    );
  }

  Future<void> _openActions(BuildContext context, String name) async {
    HapticFeedback.mediumImpact();
    final text = comment.text.trim();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NowaColors.surfaceHigh,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) {
        Widget tile(
          String value,
          IconData icon,
          String label, {
          Color color = NowaColors.text,
        }) => ListTile(
          key: Key('comment_${value}_${comment.id}'),
          leading: Icon(icon, size: 22, color: color),
          title: Text(label, style: work(size: 14.5, color: color)),
          onTap: () => Navigator.of(sheet).pop(value),
        );
        return SafeArea(
          top: false,
          child: Column(
            key: Key('comment_actions_${comment.id}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Which comment the menu is about.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$name  ', style: sora(size: 13)),
                      TextSpan(
                        text: text.isEmpty ? 'Sticker' : text,
                        style: work(
                          size: 13,
                          color: NowaColors.text.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1, color: NowaColors.hairline),
              tile('menu_reply', Icons.reply_rounded, 'Reply'),
              if (text.isNotEmpty) tile('copy', Icons.copy_rounded, 'Copy'),
              if (onEdit != null) tile('edit', Icons.edit_outlined, 'Edit'),
              if (onReport != null)
                tile('report', Icons.flag_outlined, 'Report'),
              if (onDelete != null)
                tile(
                  'delete',
                  Icons.delete_outline,
                  'Delete',
                  color: NowaColors.danger,
                ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'menu_reply':
        onReply(comment, name);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) NowaToast.of(context).success('Comment copied');
      case 'edit':
        onEdit?.call();
      case 'report':
        onReport?.call();
      case 'delete':
        onDelete?.call();
    }
  }
}

/// A comment row that answers a long press and stays lit until what the
/// press opened is closed, so it is plain which comment the menu is for.
class _PressHighlight extends StatefulWidget {
  const _PressHighlight({
    super.key,
    required this.onLongPress,
    required this.child,
  });

  final Future<void> Function() onLongPress;
  final Widget child;

  @override
  State<_PressHighlight> createState() => _PressHighlightState();
}

class _PressHighlightState extends State<_PressHighlight> {
  bool _lit = false;

  Future<void> _press() async {
    setState(() => _lit = true);
    try {
      await widget.onLongPress();
    } finally {
      if (mounted) setState(() => _lit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _press,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _lit
              ? NowaColors.text.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: widget.child,
      ),
    );
  }
}

TextStyle get _nameStyle =>
    sora(size: 12, color: NowaColors.text.withValues(alpha: 0.55));

/// Pushed over the sheet, so coming back from the profile lands on the same
/// comments. A guest is sent to sign in by the router.
void _openProfile(BuildContext context, String userId) =>
    context.push('/profile/$userId');

/// A commenter's name: a tap opens their profile.
class _NameLink extends StatelessWidget {
  const _NameLink({super.key, required this.userId, required this.name});

  final String userId;
  final String name;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openProfile(context, userId),
      child: Text(name, style: _nameStyle),
    );
  }
}

/// A commenter's picture. With a live story it wears the story ring: a tap
/// plays the story, a long press asks "story or profile?". Without one a tap
/// opens the profile.
///
/// The ring is drawn inside [size], so a row with a ring lines up with one
/// without.
class _AuthorAvatar extends ConsumerWidget {
  const _AuthorAvatar({
    super.key,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.size,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ring = ref.watch(storyRingsProvider.select((rings) => rings[userId]));

    if (ring == null) {
      return GestureDetector(
        onTap: () => _openProfile(context, userId),
        // Claimed here so the comment's own long-press menu stays off it.
        onLongPress: () => _openProfile(context, userId),
        child: SizedBox(
          width: size,
          height: size,
          child: AvatarImage(url: avatarUrl, radius: size / 2),
        ),
      );
    }

    // StoryRingBorder pads by 1.6 × its width on each side.
    final ringWidth = size >= 36 ? 2.0 : 1.5;
    final inner = size - ringWidth * 3.2;
    return GestureDetector(
      onTap: () => openUserStories(context, ref, userId),
      onLongPress: () => _showMenu(context, ref),
      child: SizedBox(
        width: size,
        height: size,
        child: StoryRingBorder(
          key: Key('comment_story_ring_$userId'),
          radius: inner / 2,
          width: ringWidth,
          unseen: ring.hasUnseen,
          child: SizedBox(
            width: inner,
            height: inner,
            child: AvatarImage(url: avatarUrl, radius: inner / 2),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_AvatarChoice>(
      context: context,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(name, style: sora(size: 14)),
            ),
            ListTile(
              key: const Key('comment_avatar_view_story'),
              leading: const Icon(
                Icons.play_circle_outline,
                color: NowaColors.text,
              ),
              title: Text('View story', style: work()),
              onTap: () => Navigator.of(sheetContext).pop(_AvatarChoice.story),
            ),
            ListTile(
              key: const Key('comment_avatar_view_profile'),
              leading: const Icon(Icons.person_outline, color: NowaColors.text),
              title: Text('View profile', style: work()),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AvatarChoice.profile),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _AvatarChoice.story:
        await openUserStories(context, ref, userId);
      case _AvatarChoice.profile:
        _openProfile(context, userId);
    }
  }
}

enum _AvatarChoice { story, profile }

/// A sticker in a comment: at most 96px on its longer side, its own aspect
/// ratio kept. The URL is public, so the disk cache keeps it.
class _StickerView extends StatelessWidget {
  const _StickerView({super.key, required this.sticker});

  final CommentSticker sticker;

  static const _max = 96.0;

  @override
  Widget build(BuildContext context) {
    final w = sticker.width, h = sticker.height;
    final (width, height) = w <= 0 || h <= 0
        ? (_max, _max)
        : w >= h
        ? (_max, _max * h / w)
        : (_max * w / h, _max);
    return SizedBox(
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: reachableFromDevice(sticker.url),
        fit: BoxFit.contain,
        placeholder: (_, _) => const SizedBox.shrink(),
        errorWidget: (_, _, _) => Icon(
          Icons.emoji_emotions_outlined,
          color: NowaColors.text.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onCancel,
    required this.onSticker,
    this.onMention,
    this.replyingTo,
    this.editing = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  /// The @ button: starts tagging a friend.
  final VoidCallback? onMention;

  /// Leaves reply or edit mode.
  final VoidCallback onCancel;
  final VoidCallback onSticker;
  final String? replyingTo;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    final chip = editing
        ? 'Editing comment'
        : replyingTo != null
        ? 'Replying to $replyingTo'
        : null;
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
          if (chip != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    chip,
                    key: const Key('comment_composer_mode'),
                    style: work(
                      size: 12,
                      color: NowaColors.text.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: const Key('comment_composer_cancel'),
                    onTap: onCancel,
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
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  decoration: BoxDecoration(
                    color: NowaColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                            hintText: editing
                                ? 'Edit your comment'
                                : replyingTo != null
                                ? 'Add a reply'
                                : 'Add a comment',
                            hintStyle: work(
                              size: 13.5,
                              height: 1.2,
                              color: NowaColors.text.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      if (onMention != null)
                        IconButton(
                          key: const Key('comment_mention_button'),
                          tooltip: 'Tag a friend',
                          visualDensity: VisualDensity.compact,
                          onPressed: onMention,
                          icon: Icon(
                            Icons.alternate_email_rounded,
                            size: 19,
                            color: NowaColors.text.withValues(alpha: 0.55),
                          ),
                        ),
                      // An edit changes the text only; the sticker stays.
                      if (!editing)
                        IconButton(
                          key: const Key('comment_sticker_button'),
                          tooltip: 'Stickers',
                          onPressed: onSticker,
                          icon: Icon(
                            Icons.emoji_emotions_outlined,
                            size: 20,
                            color: NowaColors.text.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
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
                  child: Icon(
                    editing ? Icons.check_rounded : Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The colour of a tag in a comment, the same as the web's `--tt-mention`.
const _mentionColor = Color(0xFF20D5EC);

/// A comment's text with its `@handle` tags drawn as links: a tap opens that
/// account, found by its handle.
class _CommentText extends StatefulWidget {
  const _CommentText({super.key, required this.text});

  final String text;

  @override
  State<_CommentText> createState() => _CommentTextState();
}

class _CommentTextState extends State<_CommentText> {
  final _taps = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _clear() {
    for (final tap in _taps) {
      tap.dispose();
    }
    _taps.clear();
  }

  Future<void> _open(String handle) async {
    final router = GoRouter.of(context);
    final toast = NowaToast.of(context);
    try {
      final profile = await ProviderScope.containerOf(
        context,
        listen: false,
      ).read(userRepositoryProvider).getProfileByUsername(handle);
      router.push('/profile/${profile.userId}');
    } on AppException {
      toast.error('Couldn\'t find @$handle');
    }
  }

  TapGestureRecognizer _tap(String handle) {
    final tap = TapGestureRecognizer()..onTap = () => _open(handle);
    _taps.add(tap);
    return tap;
  }

  @override
  Widget build(BuildContext context) {
    final runs = splitMentions(widget.text);
    if (runs.every((r) => r.handle == null)) {
      return Text(widget.text, style: work());
    }
    _clear();
    return Text.rich(
      TextSpan(
        style: work(),
        children: [
          for (final run in runs)
            if (run.handle case final handle?)
              TextSpan(
                text: run.text,
                style: work(color: _mentionColor, weight: FontWeight.w500),
                recognizer: _tap(handle),
              )
            else
              TextSpan(text: run.text),
        ],
      ),
    );
  }
}

/// Friends whose handle or name matches the `@word` being typed, over the
/// composer. Only friends are offered: they are the only people who can be
/// tagged.
class _MentionSuggestions extends StatelessWidget {
  const _MentionSuggestions({
    required this.friends,
    required this.query,
    required this.onPick,
  });

  final AsyncValue<List<UserProfileModel>> friends;
  final String query;
  final ValueChanged<UserProfileModel> onPick;

  @override
  Widget build(BuildContext context) {
    final hint = work(
      size: 12.5,
      color: NowaColors.text.withValues(alpha: 0.5),
    );
    final Widget body;
    if (friends.isLoading && !friends.hasValue) {
      body = Padding(
        padding: const EdgeInsets.all(14),
        child: Text('Loading friends…', style: hint),
      );
    } else if (friends.hasError && !friends.hasValue) {
      body = Padding(
        padding: const EdgeInsets.all(14),
        child: Text('Couldn\'t load your friends', style: hint),
      );
    } else {
      final matches = matchMentions(friends.requireValue, query);
      body = matches.isEmpty
          ? Padding(
              key: const Key('comment_mention_empty'),
              padding: const EdgeInsets.all(14),
              child: Text(
                friends.requireValue.isEmpty
                    ? 'You can tag friends — people you follow who follow you back'
                    : 'No friends match "@$query"',
                style: hint,
              ),
            )
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final friend in matches)
                  InkWell(
                    key: Key('comment_mention_${friend.userId}'),
                    onTap: () => onPick(friend),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          NowaAvatar(
                            url: friend.avatarUrl,
                            size: 34,
                            radius: 17,
                            border: false,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: work(size: 13.5, height: 1.2),
                                ),
                                Text(
                                  '@${mentionHandle(friend)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: work(
                                    size: 12,
                                    height: 1.2,
                                    color: NowaColors.text.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
    }
    return Container(
      key: const Key('comment_mention_suggestions'),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: const BoxDecoration(
        color: NowaColors.surface,
        border: Border(top: BorderSide(color: NowaColors.hairline)),
      ),
      child: body,
    );
  }
}

class _CommentsClosed extends StatelessWidget {
  const _CommentsClosed();

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
      child: Text(
        'Comments are turned off for this video',
        key: const Key('comments_disabled_notice'),
        textAlign: TextAlign.center,
        style: work(size: 13.5, color: NowaColors.text.withValues(alpha: 0.45)),
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
