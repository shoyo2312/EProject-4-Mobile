import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/sticker_suggestions.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/photo_preview_screen.dart';
import 'package:tiktok_mobile/features/chat/presentation/report_conversation_screen.dart';
import 'package:tiktok_mobile/features/chat/presentation/typing_sender.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/chat_image.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/mute_sheet.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/sticker_sheet.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Picks a picture from the camera or the gallery. Swapped in tests, where
/// there is neither.
typedef PhotoPicker = Future<XFile?> Function(ImageSource source);

/// Scaled and re-encoded on the device before it is sent: a phone camera's
/// 12 MP original is well past the server's 5 MB, and nothing in a chat needs
/// more than 2048 px a side.
Future<XFile?> pickChatPhoto(ImageSource source) => ImagePicker().pickImage(
  source: source,
  maxWidth: 2048,
  maxHeight: 2048,
  imageQuality: 85,
);

/// One conversation: history above, composer below, live updates in between.
///
/// The list is reversed — index 0 is the newest message and sits at the
/// bottom, which is both how the server sorts a page and how a chat is read.
/// Pictures still on their way out sit below everything the server has.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversationId,
    this.pickPhoto = pickChatPhoto,
  });

  final String conversationId;
  final PhotoPicker pickPhoto;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// Tells the other side while the caller types. Holds the repository it
  /// was made with, so the "stopped" sent on the way out of the screen does
  /// not need `ref` once the screen is going.
  late final TypingSender _typing;

  /// Which answer to a message request is on its way ('accept' / 'delete'),
  /// so a double tap cannot send two.
  String? _answering;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final repository = ref.read(chatRepositoryProvider);
    _typing = TypingSender(
      send: (typing) => repository.sendTyping(widget.conversationId, typing),
      connectionLost: repository.connectionLost(),
    );
    // Leaving the box — for the sticker sheet, a menu, the keyboard closed —
    // is not typing any more.
    _focus.addListener(() {
      if (!_focus.hasFocus) _typing.stop();
    });
    // Without it (tests, a broken store) suggestions just never go quiet.
    SharedPreferences.getInstance().then<void>(
      (prefs) => _prefs = prefs,
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _suggestTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _typing.dispose();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Typing is only announced where a message could go out right now — the
  /// same rule chat-service applies before it passes a frame on.
  bool get _mayAnnounceTyping =>
      _conversation?.sendPermission == SendPermission.allowed &&
      _conversation?.messagingBlocked != true;

  bool _unblocking = false;

  /// The way out of the caller's own block, right where the composer was.
  Future<void> _unblock(String? me) async {
    final otherId = _otherId(me);
    if (otherId == null || _unblocking) return;
    setState(() => _unblocking = true);
    try {
      await ref.read(userRepositoryProvider).unblock(otherId);
    } on ServerException catch (e) {
      if (e.code != 'NOT_BLOCKED') _toast(e.message);
    } on AppException catch (e) {
      _toast(e.message);
    }
    if (!mounted) return;
    ref.invalidate(conversationsProvider);
    ref.invalidate(conversationDetailProvider(widget.conversationId));
    ref.invalidate(profileNotifierProvider(otherId));
    setState(() => _unblocking = false);
  }

  void _onComposerChanged(String text) {
    _typing.input(_mayAnnounceTyping && text.trim().isNotEmpty);
    _suggestFor(text);
  }

  /// A message that lands while the phone is locked or the app is behind
  /// another is not "Seen" until the user is actually back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _typing.stop();
    ref
        .read(threadProvider(widget.conversationId).notifier)
        .setForeground(state == AppLifecycleState.resumed);
  }

  void _toast(String message, [ToastKind kind = ToastKind.error]) {
    if (!mounted) return;
    NowaToast.of(context).show(message, kind: kind);
  }

  /// The message shows at once, as "Sending…", so the composer is free for
  /// the next one straight away.
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!await _mayReopen()) return;
    _typing.stop();
    _ignoreSuggestion();
    _controller.clear();
    try {
      await ref.read(threadProvider(widget.conversationId).notifier).send(text);
    } on AppException catch (e) {
      if (!mounted) return;
      // Put the text back rather than losing what was typed — unless
      // something new is being written already.
      if (_controller.text.isEmpty) _controller.text = text;
      _toast(requestErrorMessage(e) ?? e.message);
    }
  }

  Future<void> _pickSticker() async {
    final sticker = await showStickerSheet(context);
    if (sticker == null || !mounted) return;
    await _sendSticker(sticker);
  }

  Future<bool> _sendSticker(StickerModel sticker) async {
    if (!await _mayReopen()) return false;
    _typing.stop();
    try {
      await ref
          .read(threadProvider(widget.conversationId).notifier)
          .sendSticker(sticker);
      return true;
    } on AppException catch (e) {
      _toast(requestErrorMessage(e) ?? e.message);
      return false;
    }
  }

  /// The topic of what is being typed, once typing pauses; its stickers show
  /// over the composer. Same rules as the web client: a short message naming
  /// a feeling or greeting, not a topic closed in this visit, not a
  /// conversation silenced on this device.
  String? _suggestTopic;
  Timer? _suggestTimer;
  final _closedTopics = <String>{};
  SharedPreferences? _prefs;

  void _suggestFor(String text) {
    _suggestTimer?.cancel();
    final topic = _topicFor(text);
    if (topic == _suggestTopic) return;
    if (topic == null) {
      setState(() => _suggestTopic = null);
      return;
    }
    _suggestTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _suggestTopic = topic);
    });
  }

  String? _topicFor(String text) {
    if (text.trim().isEmpty) return null;
    final topics = ref.read(suggestionTopicsProvider);
    if (!topics.hasValue) {
      ref.read(suggestionTopicsProvider.future).then(
        (_) {
          if (mounted) _suggestFor(_controller.text);
        },
        // Tried again on the next keystroke.
        onError: (_) => ref.invalidate(suggestionTopicsProvider),
      );
      return null;
    }
    final topic = matchSuggestionTopic(text, topics.requireValue);
    if (topic == null || _closedTopics.contains(topic)) return null;
    final prefs = _prefs;
    if (prefs != null &&
        isSuggestionMuted(prefs, widget.conversationId, DateTime.now())) {
      return null;
    }
    return topic;
  }

  void _closeSuggestion(String topic) {
    _suggestTimer?.cancel();
    setState(() {
      _closedTopics.add(topic);
      _suggestTopic = null;
    });
  }

  /// Closed, or sent past: twice in a row silences this conversation a day.
  void _dismissSuggestion(String topic) {
    _closeSuggestion(topic);
    final prefs = _prefs;
    if (prefs != null) {
      recordSuggestionDismissed(prefs, widget.conversationId, DateTime.now());
    }
  }

  /// The message went out; a bar that was showing counts as ignored.
  void _ignoreSuggestion() {
    _suggestTimer?.cancel();
    final topic = _suggestTopic;
    if (topic == null) return;
    final shown =
        ref.read(stickerSuggestionsProvider(topic)).valueOrNull?.isNotEmpty ??
        false;
    if (shown) {
      _dismissSuggestion(topic);
    } else {
      setState(() => _suggestTopic = null);
    }
  }

  Future<void> _sendSuggested(String topic, StickerModel sticker) async {
    if (!await _sendSticker(sticker) || !mounted) return;
    _closeSuggestion(topic);
    final prefs = _prefs;
    if (prefs != null) recordSuggestionUsed(prefs, widget.conversationId);
  }

  ConversationModel? get _conversation =>
      ref.read(conversationDetailProvider(widget.conversationId)).valueOrNull;

  /// The other person's name for sentences; never an id.
  String _nameFor(String? me) {
    final otherId = _otherId(me);
    final name = otherId == null
        ? null
        : ref.read(profileCacheProvider)[otherId]?.displayName;
    return name ?? 'This user';
  }

  /// The caller deleted this person's request: writing to them now lets
  /// them reply freely, so that is asked first. Anything else goes straight
  /// through.
  Future<bool> _mayReopen() async {
    if (_conversation?.sendPermission != SendPermission.reopenOnSend) {
      return true;
    }
    final me = ref.read(authStateProvider).valueOrNull?.id;
    final name = _nameFor(me);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NowaColors.surfaceHigh,
        title: Text('Let $name message you again?', style: sora(size: 15)),
        content: Text(
          'You deleted $name\'s message request. If you send a message now, '
          '$name will be able to reply and chat with you freely. If you '
          'don\'t want that, cancel — they stay unable to message you.',
          style: work(size: 13.5, height: 1.45, color: NowaColors.dim),
        ),
        actions: [
          TextButton(
            key: const Key('reopen_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: work(size: 14)),
          ),
          TextButton(
            key: const Key('reopen_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Send message',
              style: work(size: 14, color: NowaColors.accent),
            ),
          ),
        ],
      ),
    );
    return confirmed == true && mounted;
  }

  /// Accept or Delete on a request the caller received. Accepting turns it
  /// into an ordinary chat right here; deleting takes the caller back to
  /// where they came from.
  Future<void> _answer({required bool accept}) async {
    if (_answering != null) return;
    setState(() => _answering = accept ? 'accept' : 'delete');
    final requests = ref.read(messageRequestsProvider.notifier);
    try {
      if (accept) {
        final accepted = await requests.accept(widget.conversationId);
        ref
            .read(conversationDetailProvider(widget.conversationId).notifier)
            .show(accepted);
      } else {
        await requests.decline(widget.conversationId);
        if (!mounted) return;
        _toast('Request deleted', ToastKind.success);
        if (context.canPop()) context.pop();
      }
    } on AppException catch (e) {
      _toast(requestErrorMessage(e) ?? e.message);
      // Answered somewhere else first: show what the server says now.
      ref.invalidate(messageRequestsProvider);
      ref.invalidate(conversationDetailProvider(widget.conversationId));
    } finally {
      if (mounted) setState(() => _answering = null);
    }
  }

  Future<void> _report(String? me) async {
    final otherId = _otherId(me);
    if (otherId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportConversationScreen(
          conversationId: widget.conversationId,
          otherUserId: otherId,
        ),
      ),
    );
  }

  Future<void> _attach() async {
    if (!await _mayReopen()) return;
    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('chat_attach_camera'),
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: NowaColors.text,
              ),
              title: Text('Take a photo', style: work(size: 14)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              key: const Key('chat_attach_gallery'),
              leading: const Icon(
                Icons.photo_library_outlined,
                color: NowaColors.text,
              ),
              title: Text('Choose from library', style: work(size: 14)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _sendPhotoFrom(source);
  }

  /// Pick, preview, send. A shot from the camera can be retaken from the
  /// preview, which loops back here.
  Future<void> _sendPhotoFrom(ImageSource source) async {
    while (mounted) {
      final XFile? file;
      try {
        file = await widget.pickPhoto(source);
      } catch (_) {
        // Permission refused, or no camera: the picker throws rather than
        // answering null.
        _toast(
          source == ImageSource.camera
              ? 'Could not open the camera'
              : 'Could not open your photos',
        );
        return;
      }
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      final problem = OutgoingImages.problemWith(bytes);
      if (problem != null) {
        _toast(problem);
        return;
      }
      if (!mounted) return;
      final result = await Navigator.of(context).push(
        MaterialPageRoute<PhotoPreviewResult>(
          fullscreenDialog: true,
          builder: (_) => PhotoPreviewScreen(
            bytes: bytes,
            canRetake: source == ImageSource.camera,
          ),
        ),
      );
      switch (result) {
        case SendPhoto(:final caption):
          _typing.stop();
          // Not awaited: the row shows its own progress and failure.
          ref
              .read(outgoingImagesProvider(widget.conversationId).notifier)
              .send(bytes, filename: file.name, caption: caption);
          return;
        case RetakePhoto():
          continue;
        case null:
          return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final thread = ref.watch(threadProvider(widget.conversationId));
    final outgoing = ref.watch(outgoingImagesProvider(widget.conversationId));
    final maxWidth = MediaQuery.of(context).size.width * 0.62;

    final receipt = ref
        .watch(peerReceiptProvider(widget.conversationId))
        .valueOrNull;

    final conversation = ref
        .watch(conversationDetailProvider(widget.conversationId))
        .valueOrNull;
    final otherId = _otherId(me?.id);
    final profiles = ref.watch(profileCacheProvider);
    final otherAvatar = otherId == null ? null : profiles[otherId]?.avatarUrl;
    final myAvatar =
        ref.watch(myProfileProvider).valueOrNull?.avatarUrl ??
        (me == null ? null : profiles[me.id]?.avatarUrl);
    final peerTyping = ref.watch(peerTypingProvider(widget.conversationId));

    // Blocked, a request turned around, an allowance spent: whatever was
    // being announced stops with the right to send.
    ref.listen(conversationDetailProvider(widget.conversationId), (_, next) {
      if (next.valueOrNull?.sendPermission != SendPermission.allowed ||
          next.valueOrNull?.messagingBlocked == true) {
        _typing.stop();
      }
    });

    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: NowaAppBar(
        title: _title(me?.id),
        titleWidget: otherId == null
            ? null
            : _header(otherId, otherAvatar, _title(me?.id)),
        actions: [
          IconButton(
            key: const Key('chat_more_button'),
            tooltip: 'More',
            onPressed: () => _openMenu(me?.id),
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
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
              data: (messages) {
                // The status line goes under the caller's newest message,
                // while no picture of theirs is still on its way below it.
                final statusAt = outgoing.isEmpty
                    ? messages.indexWhere((m) => m.senderId == me?.id)
                    : -1;
                return NotificationListener<ScrollNotification>(
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
                    itemCount: outgoing.length + messages.length,
                    itemBuilder: (_, i) {
                      if (i < outgoing.length) {
                        // Newest pending at the bottom, like everything else.
                        return _OutgoingPhoto(
                          item: outgoing[outgoing.length - 1 - i],
                          conversationId: widget.conversationId,
                          maxWidth: maxWidth,
                        );
                      }
                      final index = i - outgoing.length;
                      final message = messages[index];
                      final mine = message.senderId == me?.id;
                      final seen = receipt?.read?.covers(message) ?? false;
                      // The avatar goes on the last of a run of messages from
                      // one person — the one with nothing newer from them.
                      final newerSender = index == 0
                          ? (outgoing.isNotEmpty ? me?.id : null)
                          : messages[index - 1].senderId;
                      return _Bubble(
                        message: message,
                        mine: mine,
                        maxWidth: maxWidth,
                        showAvatar: newerSender != message.senderId,
                        avatarUrl: mine ? myAvatar : otherAvatar,
                        onAvatarTap: mine
                            ? () => context.push('/profile')
                            : otherId == null
                            ? null
                            : () => context.push('/profile/$otherId'),
                        status: index == statusAt && !message.recalled
                            ? _statusLabel(message, receipt)
                            : null,
                        onLongPress: message.pending
                            ? null
                            : () => _messageActions(
                                message,
                                mine: mine,
                                seen: seen,
                              ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          TypingIndicator(
            active: peerTyping,
            name: _nameFor(me?.id),
            avatarUrl: otherAvatar,
          ),
          _bottom(conversation, me?.id),
        ],
      ),
    );
  }

  /// What stands where the composer goes, from what the server says the
  /// caller may send: Accept / Delete on a request they received, a notice
  /// once their own request message is out, otherwise the composer.
  Widget _bottom(ConversationModel? conversation, String? me) {
    // A block in either direction comes first: there is nothing to send into.
    if (conversation?.messagingBlocked == true) {
      final own = conversation!.blockedByViewer == true;
      return _BlockedNotice(
        name: _nameFor(me),
        unblocking: own ? _unblocking : null,
        onUnblock: own ? () => _unblock(me) : null,
      );
    }
    switch (conversation?.sendPermission) {
      case SendPermission.awaitingAccept:
        return _RequestPrompt(
          name: _nameFor(me),
          answering: _answering,
          onAccept: () => _answer(accept: true),
          onDelete: () => _answer(accept: false),
          onReport: () => _report(me),
        );
      case SendPermission.requestSent:
        return _RequestSentNotice(
          retryAvailableAt: conversation!.retryAvailableAt,
        );
      case SendPermission.firstMessageOnly:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              key: const Key('request_first_message_hint'),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Text(
                'They\'ll get this as a message request. You can send 1 '
                'message until they accept.',
                textAlign: TextAlign.center,
                style: work(
                  size: 11.5,
                  height: 1.4,
                  color: NowaColors.text.withValues(alpha: 0.5),
                ),
              ),
            ),
            _composer(),
          ],
        );
      case SendPermission.allowed:
      case SendPermission.reopenOnSend:
      case null:
        return _composer();
    }
  }

  /// "Sending…", "Sent", "Delivered" or "Seen 5m ago" for one of the caller's
  /// messages, from where the other side's marks are.
  static String _statusLabel(MessageModel message, ReceiptView? receipt) {
    final status =
        receipt?.statusOf(message) ??
        (message.pending ? MessageStatus.sending : MessageStatus.sent);
    if (status != MessageStatus.seen) return status.label;
    final at = receipt?.read?.at;
    if (at == null) return status.label;
    final ago = timeAgo(at);
    return ago == 'now' ? 'Seen just now' : 'Seen $ago ago';
  }

  /// Mute and Report, for the whole conversation.
  Future<void> _openMenu(String? me) async {
    final conversation = _conversation;
    final muted = conversation?.muted ?? false;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('chat_menu_mute'),
              leading: Icon(
                muted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: NowaColors.text,
              ),
              title: Text(
                muted ? 'Unmute notifications' : 'Mute notifications',
                style: work(size: 14),
              ),
              subtitle: muted && conversation != null
                  ? Text(
                      mutedLabel(conversation),
                      style: work(size: 12, color: NowaColors.dim),
                    )
                  : null,
              onTap: () => Navigator.of(context).pop(muted ? 'unmute' : 'mute'),
            ),
            ListTile(
              key: const Key('chat_menu_report'),
              leading: const Icon(
                Icons.flag_outlined,
                color: NowaColors.danger,
              ),
              title: Text(
                'Report',
                style: work(size: 14, color: NowaColors.danger),
              ),
              onTap: () => Navigator.of(context).pop('report'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'mute':
        await _mute();
      case 'unmute':
        await _unmute();
      case 'report':
        if (me == null || conversation == null) return;
        await _report(me);
    }
  }

  Future<void> _mute() async {
    final length = await pickMuteLength(context);
    if (length == null || !mounted) return;
    try {
      await ref
          .read(conversationsProvider.notifier)
          .mute(widget.conversationId, length);
      _toast('Notifications muted', ToastKind.success);
    } on AppException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _unmute() async {
    try {
      await ref
          .read(conversationsProvider.notifier)
          .unmute(widget.conversationId);
      _toast('Notifications turned on', ToastKind.success);
    } on AppException catch (e) {
      _toast(e.message);
    }
  }

  /// Long press on a message. Anything can be deleted from the caller's own
  /// side; only the caller's own, and only until the other side has seen it,
  /// can be taken back for everyone.
  Future<void> _messageActions(
    MessageModel message, {
    required bool mine,
    required bool seen,
  }) async {
    final canRecall = mine && !message.recalled;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRecall)
              ListTile(
                key: const Key('chat_action_recall'),
                enabled: !seen,
                leading: Icon(
                  Icons.undo,
                  color: NowaColors.text.withValues(alpha: seen ? 0.35 : 1),
                ),
                title: Text(
                  'Unsend for everyone',
                  style: work(
                    size: 14,
                    color: NowaColors.text.withValues(alpha: seen ? 0.35 : 1),
                  ),
                ),
                subtitle: seen
                    ? Text(
                        'Already seen, so it can\'t be unsent',
                        style: work(size: 12, color: NowaColors.dim),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop('recall'),
              ),
            ListTile(
              key: const Key('chat_action_hide'),
              leading: const Icon(
                Icons.delete_outline,
                color: NowaColors.danger,
              ),
              title: Text(
                'Delete for you',
                style: work(size: 14, color: NowaColors.danger),
              ),
              subtitle: Text(
                'It stays in the chat for the other person',
                style: work(size: 12, color: NowaColors.dim),
              ),
              onTap: () => Navigator.of(context).pop('hide'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final recall = choice == 'recall';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NowaColors.surfaceHigh,
        title: Text(
          recall ? 'Unsend message?' : 'Delete for you?',
          style: sora(size: 15),
        ),
        content: Text(
          recall
              ? 'It will be removed for everyone in this chat. They will see that a message was unsent.'
              : 'It will be removed from this chat on your side only.',
          style: work(size: 13.5, color: NowaColors.dim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: work(size: 14)),
          ),
          TextButton(
            key: const Key('chat_action_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              recall ? 'Unsend' : 'Delete',
              style: work(size: 14, color: NowaColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final thread = ref.read(threadProvider(widget.conversationId).notifier);
    try {
      if (recall) {
        await thread.recall(message.id);
      } else {
        await thread.hide(message.id);
      }
    } on AppException catch (e) {
      final code = e is ServerException ? e.code : null;
      _toast(switch (code) {
        'MESSAGE_ALREADY_SEEN' =>
          'They\'ve already seen this message, so it can\'t be unsent',
        'NOT_MESSAGE_AUTHOR' => 'Only the sender can unsend a message',
        _ => e.message,
      });
    }
  }

  /// The other participant, once the conversation is known — from the inbox,
  /// the request box or the server.
  String? _otherId(String? me) {
    if (me == null) return null;
    return ref
        .watch(conversationDetailProvider(widget.conversationId))
        .valueOrNull
        ?.otherParticipant(me);
  }

  /// The other participant's name, once the conversation and their profile are
  /// both known. Until then the header says "Messages" rather than flashing an
  /// id at the reader.
  String _title(String? me) {
    final otherId = _otherId(me);
    if (otherId == null) return 'Messages';
    return ref.watch(profileCacheProvider)[otherId]?.displayName ?? 'Messages';
  }

  /// Their avatar and name; tapping either opens their profile.
  Widget _header(String otherId, String? avatarUrl, String name) {
    return GestureDetector(
      key: const Key('chat_header_profile'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/profile/$otherId'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NowaAvatar(url: avatarUrl, size: 30, radius: 15, border: false),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sora(size: 15.5, spacing: -0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    final dim = NowaColors.text.withValues(alpha: 0.7);
    final topic = _suggestTopic;
    final suggested = topic == null
        ? const <StickerModel>[]
        : ref.watch(stickerSuggestionsProvider(topic)).valueOrNull ??
              const <StickerModel>[];
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (topic != null && suggested.isNotEmpty)
            _StickerSuggestionBar(
              stickers: suggested,
              onPick: (sticker) => _sendSuggested(topic, sticker),
              onDismiss: () => _dismissSuggestion(topic),
            ),
          _composerRow(dim),
        ],
      ),
    );
  }

  Widget _composerRow(Color dim) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NowaColors.hairline)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('chat_attach_button'),
            tooltip: 'Photo',
            onPressed: _attach,
            icon: Icon(Icons.add_circle_outline, size: 22, color: dim),
          ),
          Expanded(
            child: TextField(
              key: const Key('chat_composer_field'),
              controller: _controller,
              focusNode: _focus,
              onChanged: _onComposerChanged,
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
          IconButton(
            key: const Key('chat_sticker_button'),
            tooltip: 'Stickers',
            onPressed: _pickSticker,
            icon: Icon(Icons.emoji_emotions_outlined, size: 22, color: dim),
          ),
          GestureDetector(
            key: const Key('chat_send_button'),
            behavior: HitTestBehavior.opaque,
            onTap: _send,
            child: Icon(Icons.arrow_upward, size: 20, color: NowaColors.accent),
          ),
        ],
      ),
    );
  }
}

/// Stickers for the feeling being typed, over the composer. A tap sends one.
class _StickerSuggestionBar extends StatelessWidget {
  const _StickerSuggestionBar({
    required this.stickers,
    required this.onPick,
    required this.onDismiss,
  });

  final List<StickerModel> stickers;
  final ValueChanged<StickerModel> onPick;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('sticker_suggestions'),
      height: 64,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: NowaColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NowaColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(4),
              children: [
                for (final sticker in stickers)
                  Semantics(
                    button: true,
                    label: 'Send sticker: ${sticker.name}',
                    child: InkWell(
                      key: Key('sticker_suggestion_${sticker.stickerId}'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onPick(sticker),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: StickerImage(sticker: sticker, size: 50),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('sticker_suggestions_close'),
            tooltip: 'Hide sticker suggestions',
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              size: 18,
              color: NowaColors.text.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom of a request the caller received: what it means, and Delete /
/// Accept. There is no composer under it — the server refuses a reply before
/// Accept. Reading the request is not answering it; only a tap here is.
class _RequestPrompt extends StatelessWidget {
  const _RequestPrompt({
    required this.name,
    required this.answering,
    required this.onAccept,
    required this.onDelete,
    required this.onReport,
  });

  final String name;

  /// 'accept' or 'delete' while that answer is on its way.
  final String? answering;
  final VoidCallback onAccept;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final busy = answering != null;
    final meta = work(
      size: 12.5,
      height: 1.45,
      color: NowaColors.text.withValues(alpha: 0.6),
    );
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('request_prompt'),
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: NowaColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NowaColors.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$name wants to send you a message',
              textAlign: TextAlign.center,
              style: sora(size: 14.5, height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              'If you accept, you can chat with this user right away. If you '
              'delete, this chat will be removed from your Message requests. '
              'This user can send only 1 message before you accept.',
              textAlign: TextAlign.center,
              style: meta,
            ),
            const SizedBox(height: 6),
            GestureDetector(
              key: const Key('request_report'),
              behavior: HitTestBehavior.opaque,
              onTap: onReport,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Report this user',
                  style: meta.copyWith(
                    color: NowaColors.text,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: NowaColors.text.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: NowaButton(
                    key: const Key('request_delete'),
                    label: answering == 'delete' ? 'Deleting…' : 'Delete',
                    filled: false,
                    onTap: busy ? null : onDelete,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NowaButton(
                    key: const Key('request_accept'),
                    label: answering == 'accept' ? 'Accepting…' : 'Accept',
                    onTap: busy ? null : onAccept,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the composer was once the one message a request allows is out. An
/// ignored request and a deleted one look the same from this side, so it
/// promises nothing about either: what happens on accept, and when one more
/// message may be sent.
class _RequestSentNotice extends StatelessWidget {
  const _RequestSentNotice({required this.retryAvailableAt});

  final DateTime? retryAvailableAt;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final at = retryAvailableAt?.toLocal();
    final when = at == null
        ? '${ConversationModel.requestRetryAfter.inDays} days from now'
        : '${_months[at.month - 1]} ${at.day}, ${at.year}';
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('request_sent_notice'),
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NowaColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NowaColors.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: NowaColors.surfaceHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat request sent', style: sora(size: 14)),
                  const SizedBox(height: 3),
                  Text(
                    'You can keep chatting as soon as they accept. If they '
                    'haven\'t responded or have declined by $when, you can '
                    'send 1 more message to ask again.',
                    style: work(
                      size: 12.5,
                      height: 1.45,
                      color: NowaColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stands where the composer would be while a block closes the thread. The
/// caller's own block offers Unblock; the other side's names no one and
/// offers nothing, as on the web. History stays readable above it.
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice({required this.name, this.unblocking, this.onUnblock});

  final String name;
  final bool? unblocking;
  final VoidCallback? onUnblock;

  @override
  Widget build(BuildContext context) {
    final own = onUnblock != null;
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('blocked_notice'),
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NowaColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NowaColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: NowaColors.surfaceHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                own
                    ? 'You blocked $name. You can\'t message each other until '
                          'you unblock them.'
                    : 'You can\'t message this account.',
                style: work(
                  size: 13,
                  height: 1.4,
                  color: NowaColors.text.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (own) ...[
              const SizedBox(width: 8),
              TextButton(
                key: const Key('blocked_unblock'),
                onPressed: unblocking == true ? null : onUnblock,
                child: Text(
                  unblocking == true ? 'Unblocking…' : 'Unblock',
                  style: work(size: 13, color: NowaColors.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The column beside the bubbles that the avatars sit in, kept even where
/// there is no avatar so a run of messages lines up.
const _avatarSize = 28.0;
const _avatarGap = 6.0;

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.maxWidth,
    this.status,
    this.onLongPress,
    this.showAvatar = false,
    this.avatarUrl,
    this.onAvatarTap,
  });

  final MessageModel message;
  final bool mine;
  final double maxWidth;

  /// Only on the last message of a run from one sender.
  final bool showAvatar;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  /// "Sent" / "Delivered" / "Seen …" — under the caller's newest message only.
  final String? status;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final sticker = message.sticker;
    if (sticker != null && !message.recalled) {
      return _aligned(StickerImage(sticker: sticker, size: 120));
    }

    final image = message.image;
    if (image != null && !message.recalled) {
      return _aligned(
        Column(
          crossAxisAlignment: align,
          children: [
            ChatImage(image: image, maxWidth: maxWidth),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              _textBubble(
                context,
                Text(message.content, style: work(size: 13.5, height: 1.35)),
              ),
            ],
          ],
        ),
      );
    }

    final text = Text(
      message.content,
      style: message.recalled
          ? work(
              size: 13.5,
              height: 1.35,
              color: NowaColors.text.withValues(alpha: 0.55),
            ).copyWith(fontStyle: FontStyle.italic)
          : work(size: 13.5, height: 1.35),
    );
    return _aligned(_textBubble(context, text));
  }

  Widget _aligned(Widget child) {
    final status = this.status;
    Widget body = GestureDetector(
      key: Key('chat_message_${message.id}'),
      onLongPress: onLongPress,
      // Still on its way: drawn, but plainly not there yet.
      child: Opacity(opacity: message.pending ? 0.6 : 1, child: child),
    );
    final avatar = SizedBox(
      width: _avatarSize,
      child: showAvatar
          ? GestureDetector(
              key: Key('chat_avatar_${message.id}'),
              onTap: onAvatarTap,
              child: NowaAvatar(
                url: avatarUrl,
                size: _avatarSize,
                radius: _avatarSize / 2,
                border: false,
              ),
            )
          : null,
    );
    // Beside the bubble, on the side facing the middle of the screen, so it
    // never squeezes the message itself.
    final time = Text(
      timeAgo(message.sentAt),
      key: Key('chat_time_${message.id}'),
      style: work(
        size: 10,
        height: 1,
        color: NowaColors.text.withValues(alpha: 0.45),
      ),
    );
    // The avatar and the time sit level with the bottom of the bubble.
    Widget row = Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (mine) ...[time, const SizedBox(width: _avatarGap)],
        if (!mine) ...[avatar, const SizedBox(width: _avatarGap)],
        Flexible(child: body),
        if (mine) ...[const SizedBox(width: _avatarGap), avatar],
        if (!mine) ...[const SizedBox(width: _avatarGap), time],
      ],
    );
    if (status != null) {
      row = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          row,
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(right: _avatarSize + _avatarGap),
            child: Text(
              status,
              key: const Key('chat_message_status'),
              style: work(
                size: 10.5,
                height: 1,
                color: NowaColors.text.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      );
    }
    // Tighter inside a run, a little air between runs.
    return Padding(
      padding: EdgeInsets.only(bottom: showAvatar ? 10 : 3),
      child: row,
    );
  }

  Widget _textBubble(BuildContext context, Widget text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: mine && !message.recalled
            ? NowaColors.accent
            : NowaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: text,
    );
  }
}

/// A picture the caller is sending: drawn from the bytes on the device, with
/// a progress ring while it goes up, or Retry / Remove if it failed.
class _OutgoingPhoto extends ConsumerWidget {
  const _OutgoingPhoto({
    required this.item,
    required this.conversationId,
    required this.maxWidth,
  });

  final OutgoingImage item;
  final String conversationId;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(outgoingImagesProvider(conversationId).notifier);
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        // Lined up with the caller's sent messages, whose avatar column
        // sits to their right.
        padding: const EdgeInsets.only(
          bottom: 8,
          right: _avatarSize + _avatarGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              key: Key('outgoing_photo_${item.localId}'),
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxWidth * 1.3,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: item.failed ? 0.4 : 0.7,
                      child: Image.memory(item.bytes, fit: BoxFit.cover),
                    ),
                    if (!item.failed)
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          value: item.progress > 0 && item.progress < 1
                              ? item.progress
                              : null,
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (item.failed) ...[
              const SizedBox(height: 4),
              Text(
                item.error!,
                style: work(size: 11.5, color: NowaColors.danger),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    key: Key('outgoing_photo_remove_${item.localId}'),
                    onPressed: () => notifier.remove(item.localId),
                    child: Text('Remove', style: work(size: 12)),
                  ),
                  TextButton(
                    key: Key('outgoing_photo_retry_${item.localId}'),
                    onPressed: () => notifier.retry(item.localId),
                    child: Text(
                      'Retry',
                      style: work(size: 12, color: NowaColors.accent),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
