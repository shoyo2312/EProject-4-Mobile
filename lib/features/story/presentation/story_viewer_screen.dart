import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/presentation/floating_reactions.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_viewers_sheet.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';
import 'package:video_player/video_player.dart';

/// How long a photo stays up. A video plays for its own length (≤ 60s).
const storyImageDuration = Duration(seconds: 5);

/// chat-service's limit on a story reply.
const _maxReplyLength = 1000;

/// What `/stories/view` is opened with: the groups to play and where to start.
class StoryViewerArgs {
  const StoryViewerArgs({required this.groups, this.initialGroup = 0});

  final List<StoryGroup> groups;
  final int initialGroup;
}

/// Full-screen player. Swipe sideways between people, tap the right/left of
/// the screen for the next/previous story, hold to pause, swipe down to close.
class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key, required this.args});

  final StoryViewerArgs args;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  late final List<StoryGroup> _groups = [...widget.args.groups];
  late final PageController _pages =
      PageController(initialPage: widget.args.initialGroup);
  late int _page = widget.args.initialGroup;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) context.pop();
  }

  void _nextGroup() {
    if (_page >= _groups.length - 1) return _close();
    _pages.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _previousGroup() {
    if (_page == 0) return;
    _pages.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  /// A group emptied by deleting its last story leaves the viewer — it can
  /// only be the owner's own, and there is nothing left of it to show.
  void _groupChanged(int index, StoryGroup group) {
    if (group.stories.isEmpty) {
      _close();
      return;
    }
    setState(() => _groups[index] = group);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) _close();
        },
        child: PageView.builder(
          controller: _pages,
          itemCount: _groups.length,
          onPageChanged: (index) => setState(() => _page = index),
          itemBuilder: (context, index) => _GroupPlayer(
            key: ValueKey(_groups[index].userId),
            group: _groups[index],
            active: index == _page,
            onFinished: _nextGroup,
            onBeforeFirst: _previousGroup,
            onClose: _close,
            onChanged: (group) => _groupChanged(index, group),
          ),
        ),
      ),
    );
  }
}

class _GroupPlayer extends ConsumerStatefulWidget {
  const _GroupPlayer({
    super.key,
    required this.group,
    required this.active,
    required this.onFinished,
    required this.onBeforeFirst,
    required this.onClose,
    required this.onChanged,
  });

  final StoryGroup group;

  /// False while another person's group is the page on screen.
  final bool active;
  final VoidCallback onFinished;
  final VoidCallback onBeforeFirst;
  final VoidCallback onClose;
  final ValueChanged<StoryGroup> onChanged;

  @override
  ConsumerState<_GroupPlayer> createState() => _GroupPlayerState();
}

class _GroupPlayerState extends ConsumerState<_GroupPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });

  /// Someone else's group opens at the first story they have not seen; your
  /// own always from the start.
  late int _index = _startIndex();

  /// Set once the current story's media is on screen. Until then the bar
  /// does not move: a slow network should not eat a photo's five seconds.
  var _ready = false;

  // Reasons to hold the story still. Any one of them pauses it.
  var _holding = false;
  var _typing = false;
  var _sheetOpen = false;

  final _reply = TextEditingController();
  final _replyFocus = FocusNode();
  final _floats = GlobalKey<FloatingReactionsState>();

  /// One id per attempt at one text: a retry after a lost response is the
  /// same message, not a second.
  ({String text, String id})? _replyAttempt;
  var _sending = false;

  StoryModel get _story => widget.group.stories[_index];

  bool get _isOwn =>
      ref.read(authStateProvider).valueOrNull?.id == widget.group.userId;

  bool get _paused => !widget.active || _holding || _typing || _sheetOpen;

  int _startIndex() {
    final me = ref.read(authStateProvider).valueOrNull?.id;
    if (me == widget.group.userId) return 0;
    final unseen = widget.group.stories.indexWhere((s) => !s.viewedByMe);
    return unseen < 0 ? 0 : unseen;
  }

  @override
  void initState() {
    super.initState();
    _replyFocus.addListener(() {
      setState(() => _typing = _replyFocus.hasFocus || _reply.text.isNotEmpty);
      _syncPlayback();
    });
    if (widget.active) _onShownLater();
  }

  /// [_onShown] tells the parent and the tray, which must not happen while
  /// this widget is still being built.
  void _onShownLater() =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onShown();
      });

  @override
  void didUpdateWidget(covariant _GroupPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.group.stories.length) {
      _index = widget.group.stories.length - 1;
    }
    if (!oldWidget.active && widget.active) {
      _onShownLater();
      _replayReactions();
    }
    _syncPlayback();
  }

  /// Leaving the viewer before the taps settled still sends them. Here and
  /// not in dispose: ref is gone by then.
  @override
  void deactivate() {
    if (_reactionPending != null) _flushReaction();
    super.deactivate();
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    _progress.dispose();
    _reply.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  /// The story is on screen: count the view and grey the ring. The server
  /// ignores repeats and the owner's own views, so this is not de-duplicated
  /// beyond what is already known.
  void _onShown() {
    final story = _story;
    if (_isOwn || story.viewedByMe) return;
    if (ref.read(authStateProvider).valueOrNull == null) return;
    ref.read(storyRepositoryProvider).recordView(story.id).ignore();
    _replaceStory(story.copyWith(viewedByMe: true));
    if (ref.exists(storyTrayProvider)) {
      ref.read(storyTrayProvider.notifier).markViewed(story.id);
    }
  }

  void _replaceStory(StoryModel story) {
    widget.onChanged(widget.group.copyWith(
      stories: [
        for (final s in widget.group.stories) s.id == story.id ? story : s,
      ],
      hasUnseen: widget.group.stories
          .any((s) => s.id != story.id && !s.viewedByMe),
    ));
  }

  /// The media finished loading; start the bar with its length.
  void _onReady(Duration length) {
    if (!mounted) return;
    _progress.duration = length;
    _ready = true;
    _syncPlayback();
    _replayReactions();
  }

  /// The story [_replayReactions] last played, so going back to it or a
  /// rebuild does not send the same reactions up again.
  String? _replayedFor;

  /// The owner's own story, on screen and loaded: what everyone gave it
  /// rises over it, the way a viewer's tap does.
  void _replayReactions() {
    if (!widget.active || !_ready || !_isOwn) return;
    final story = _story;
    final counts = story.reactionCounts;
    if (counts == null || counts.isEmpty || _replayedFor == story.id) return;
    _replayedFor = story.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _floats.currentState?.replay(counts);
    });
  }

  void _syncPlayback() {
    if (!_ready) return;
    if (_paused) {
      _progress.stop();
    } else if (!_progress.isAnimating && _progress.value < 1) {
      _progress.forward();
    }
  }

  void _goTo(int index) {
    setState(() {
      _index = index;
      _ready = false;
      _progress.value = 0;
    });
    _onShown();
  }

  void _next() {
    if (_index < widget.group.stories.length - 1) {
      _goTo(_index + 1);
    } else {
      widget.onFinished();
    }
  }

  void _previous() {
    if (_index > 0) {
      _goTo(_index - 1);
    } else {
      // Already at the start: restart this one, or step back a person.
      _progress.value = 0;
      widget.onBeforeFirst();
      _syncPlayback();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_replyFocus.hasFocus) {
      _replyFocus.unfocus();
      return;
    }
    final width = MediaQuery.of(context).size.width;
    details.globalPosition.dx < width / 3 ? _previous() : _next();
  }

  Future<T?> _whilePaused<T>(Future<T?> Function() open) async {
    setState(() => _sheetOpen = true);
    _syncPlayback();
    try {
      return await open();
    } finally {
      if (mounted) {
        setState(() => _sheetOpen = false);
        _syncPlayback();
      }
    }
  }

  void _toast(String text, [ToastKind kind = ToastKind.error]) {
    NowaToast.of(context).show(text, kind: kind);
  }

  // ---- Owner actions --------------------------------------------------------

  Future<void> _openViewers() => _whilePaused(
        () => showStoryViewersSheet(context, story: _story),
      );

  Future<void> _openOwnerMenu() async {
    final action = await _whilePaused(() => showModalBottomSheet<String>(
          context: context,
          backgroundColor: NowaColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (context) => _OwnerMenu(current: _story.visibility),
        ));
    if (action == null || !mounted) return;
    if (action == 'delete') return _delete();
    final visibility = StoryVisibility.values.byName(action);
    if (visibility == _story.visibility) return;
    try {
      final updated = await ref
          .read(storyRepositoryProvider)
          .updateVisibility(_story.id, visibility);
      if (!mounted) return;
      _replaceStory(updated);
      if (ref.exists(storyTrayProvider)) {
        ref.read(storyTrayProvider.notifier).replace(updated);
      }
      _toast('Audience updated', ToastKind.success);
    } on AppException catch (e) {
      if (mounted) _toast(storyErrorMessage(e));
    }
  }

  Future<void> _delete() async {
    final confirmed = await _whilePaused(() => showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: NowaColors.surface,
            title: Text('Delete this story?', style: sora(size: 16)),
            content: Text(
              'It disappears for everyone right away.',
              style: work(size: 13, color: NowaColors.dim),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: sora(size: 13)),
              ),
              TextButton(
                key: const Key('story_delete_confirm'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: sora(size: 13, color: NowaColors.danger),
                ),
              ),
            ],
          ),
        ));
    if (confirmed != true || !mounted) return;
    final story = _story;
    try {
      await ref.read(storyRepositoryProvider).delete(story.id);
    } on AppException catch (e) {
      if (mounted) _toast(storyErrorMessage(e));
      return;
    }
    if (!mounted) return;
    if (ref.exists(storyTrayProvider)) {
      ref.read(storyTrayProvider.notifier).remove(story.id);
    }
    ref.invalidate(storyRingProvider(story.userId));
    ref.invalidate(userStoryGroupProvider(story.userId));
    final remaining = [
      for (final s in widget.group.stories)
        if (s.id != story.id) s,
    ];
    setState(() {
      _ready = false;
      _progress.value = 0;
    });
    widget.onChanged(widget.group.copyWith(stories: remaining));
    _onShownLater();
    _toast('Story deleted', ToastKind.success);
  }

  // ---- Viewer actions -------------------------------------------------------

  /// Tapping the reaction already chosen takes it back.
  ///
  /// The screen follows every tap at once; the server hears only where the
  /// taps ended up, [_reactionSettle] after the last one — someone tapping
  /// away at the bar to watch the emoji fly is one request, not twenty.
  void _react(StoryReaction reaction) {
    if (ref.read(authStateProvider).valueOrNull == null) {
      context.push('/login');
      return;
    }
    final story = _story;
    if (_reactionPending?.storyId != story.id) _flushReaction();
    final pending = _reactionPending;
    // Two taps in one frame both have to see the first: the group may not
    // have been rebuilt in between, the pending target has.
    final current = pending != null ? pending.target : story.myReaction;
    final next = current == reaction ? null : reaction;
    _reactionPending = (
      storyId: story.id,
      confirmed: pending != null ? pending.confirmed : story.myReaction,
      target: next,
    );
    _replaceStory(story.copyWith(myReaction: next, viewedByMe: true));
    _reactionTimer?.cancel();
    _reactionTimer = Timer(_reactionSettle, _flushReaction);
  }

  static const _reactionSettle = Duration(milliseconds: 400);
  Timer? _reactionTimer;

  /// The story with taps not yet sent: what the server holds for it, and
  /// where the taps have got to. Kept here rather than read back from the
  /// group, which the parent may not have rebuilt yet when the timer fires.
  ({String storyId, StoryReaction? confirmed, StoryReaction? target})?
      _reactionPending;

  /// Sends where the taps ended up, if that is not where they started. A
  /// refusal puts the bar back to what the server has.
  Future<void> _flushReaction() async {
    _reactionTimer?.cancel();
    _reactionTimer = null;
    final pending = _reactionPending;
    _reactionPending = null;
    if (pending == null) return;
    StoryModel? find() =>
        widget.group.stories.where((s) => s.id == pending.storyId).firstOrNull;
    final target = pending.target;
    if (target == pending.confirmed) return;
    final storyId = pending.storyId;

    final repo = ref.read(storyRepositoryProvider);
    final tray = ref.exists(storyTrayProvider)
        ? ref.read(storyTrayProvider.notifier)
        : null;
    try {
      target == null
          ? await repo.clearReaction(storyId)
          : await repo.setReaction(storyId, target);
      tray?.setReaction(storyId, target);
    } on AppException catch (e) {
      if (!mounted) return;
      final current = find();
      if (current != null) {
        _replaceStory(current.copyWith(myReaction: pending.confirmed));
      }
      _toast(storyErrorMessage(e));
    }
  }

  Future<void> _sendReply() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    if (ref.read(authStateProvider).valueOrNull == null) {
      context.push('/login');
      return;
    }
    final attempt = _replyAttempt?.text == text
        ? _replyAttempt!
        : (text: text, id: newClientRequestId());
    _replyAttempt = attempt;
    setState(() => _sending = true);
    try {
      final message = await ref.read(chatRepositoryProvider).sendStoryReply(
            storyId: _story.id,
            content: text,
            clientRequestId: attempt.id,
          );
      if (!mounted) return;
      _replyAttempt = null;
      _reply.clear();
      _replyFocus.unfocus();
      NowaToast.of(context).success(
        'Reply sent',
        actionLabel: 'View',
        onAction: () => context.push('/messages/${message.conversationId}'),
      );
    } on AppException catch (e) {
      if (mounted) _toast(storyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    final profile = ref.watch(profileCacheProvider)[widget.group.userId];
    final signedIn = ref.watch(authStateProvider).valueOrNull != null;
    final isOwn = _isOwn;
    final padding = MediaQuery.of(context).padding;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _onTapUp,
          onLongPressStart: (_) {
            setState(() => _holding = true);
            _syncPlayback();
          },
          onLongPressEnd: (_) {
            setState(() => _holding = false);
            _syncPlayback();
          },
          child: _StoryMedia(
            key: ValueKey(story.id),
            story: story,
            paused: _paused,
            onReady: _onReady,
          ),
        ),
        const IgnorePointer(child: _Scrims()),
        Positioned(
          left: 10,
          right: 10,
          top: padding.top + 8,
          child: Column(
            children: [
              _ProgressBars(
                count: widget.group.stories.length,
                index: _index,
                progress: _progress,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final router = GoRouter.of(context);
                      widget.onClose();
                      router.push('/profile/${widget.group.userId}');
                    },
                    child: Row(
                      children: [
                        NowaAvatar(url: profile?.avatarUrl, size: 34, radius: 12),
                        const SizedBox(width: 9),
                        Text(
                          isOwn ? 'Your story' : profile?.displayName ?? '…',
                          style: sora(size: 13.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeAgo(story.createdAt),
                    style: work(size: 12, color: NowaColors.dim),
                  ),
                  if (story.visibility != StoryVisibility.public) ...[
                    const SizedBox(width: 6),
                    Icon(
                      story.visibility == StoryVisibility.friends
                          ? Icons.people_alt_outlined
                          : Icons.lock_outline,
                      size: 13,
                      color: NowaColors.dim,
                    ),
                  ],
                  const Spacer(),
                  if (isOwn)
                    IconButton(
                      key: const Key('story_owner_menu'),
                      onPressed: _openOwnerMenu,
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                    ),
                  IconButton(
                    key: const Key('story_close'),
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14 + (keyboard > 0 ? keyboard : padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The song's credit, which its Creative Commons licence asks for.
              if (story.music case final music?) ...[
                Center(
                  child: Glass(
                    key: const Key('story_music_credit'),
                    radius: 999,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_note, size: 13, color: NowaColors.supportInk),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${music.title} · ${music.artist}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: sora(size: 11.5, weight: FontWeight.w500, color: NowaColors.supportInk),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (story.caption != null && story.caption!.isNotEmpty) ...[
                Text(
                  story.caption!,
                  key: const Key('story_caption'),
                  textAlign: TextAlign.center,
                  style: work(size: 14.5),
                ),
                const SizedBox(height: 14),
              ],
              if (isOwn)
                _OwnerFooter(
                  story: story,
                  floats: _floats,
                  onViewers: _openViewers,
                )
              else if (signedIn)
                _ViewerFooter(
                  story: story,
                  floats: _floats,
                  reply: _reply,
                  replyFocus: _replyFocus,
                  sending: _sending,
                  onReact: _react,
                  onSend: _sendReply,
                  onChanged: (text) {
                    setState(() =>
                        _typing = _replyFocus.hasFocus || text.isNotEmpty);
                    _syncPlayback();
                  },
                )
              else
                NowaButton(
                  label: 'Log in to reply',
                  filled: false,
                  onTap: () => context.push('/login'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The photo or clip. Reports its length once it can actually be seen.
class _StoryMedia extends StatefulWidget {
  const _StoryMedia({
    super.key,
    required this.story,
    required this.paused,
    required this.onReady,
  });

  final StoryModel story;
  final bool paused;
  final ValueChanged<Duration> onReady;

  @override
  State<_StoryMedia> createState() => _StoryMediaState();
}

class _StoryMediaState extends State<_StoryMedia> {
  VideoPlayerController? _video;
  var _reported = false;
  var _failed = false;

  /// The in-memory mock serves local files; the real service never does.
  bool get _isLocal => widget.story.mediaUrl.startsWith('file://');

  @override
  void initState() {
    super.initState();
    if (widget.story.mediaType == StoryMediaType.video) {
      final uri = Uri.parse(widget.story.mediaUrl);
      final controller = _video = _isLocal
          ? VideoPlayerController.file(File(uri.toFilePath()))
          : VideoPlayerController.networkUrl(uri);
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        final length = controller.value.duration;
        _report(length > Duration.zero ? length : storyImageDuration);
        _sync();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
        _report(storyImageDuration);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _StoryMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paused != widget.paused) _sync();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  void _sync() {
    final controller = _video;
    if (controller == null || !controller.value.isInitialized) return;
    widget.paused ? controller.pause() : controller.play();
  }

  void _report(Duration length) {
    if (_reported) return;
    _reported = true;
    widget.onReady(length);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _MediaError();
    final controller = _video;
    if (controller != null) {
      if (!controller.value.isInitialized) return const _MediaLoading();
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }

    Widget frame(BuildContext context, Widget child, int? frame, bool sync) {
      if (frame != null || sync) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _report(storyImageDuration));
        return child;
      }
      return const _MediaLoading();
    }

    Widget error(BuildContext context, Object error, StackTrace? stack) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _report(storyImageDuration));
      return const _MediaError();
    }

    final uri = Uri.parse(widget.story.mediaUrl);
    return _isLocal
        ? Image.file(File(uri.toFilePath()),
            fit: BoxFit.contain, frameBuilder: frame, errorBuilder: error)
        : Image.network(widget.story.mediaUrl,
            fit: BoxFit.contain, frameBuilder: frame, errorBuilder: error);
  }
}

class _MediaLoading extends StatelessWidget {
  const _MediaLoading();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: NowaColors.accent),
      );
}

class _MediaError extends StatelessWidget {
  const _MediaError();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'This story could not be loaded',
          style: work(size: 13, color: NowaColors.dim),
        ),
      );
}

class _Scrims extends StatelessWidget {
  const _Scrims();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
          stops: const [0, 0.18, 0.6, 1],
        ),
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.count,
    required this.index,
    required this.progress,
  });

  final int count;
  final int index;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) => Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: i < index
                        ? 1
                        : i == index
                            ? progress.value
                            : 0,
                    minHeight: 2.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Status, views and reactions — only the owner gets these numbers.
class _OwnerFooter extends StatelessWidget {
  const _OwnerFooter({
    required this.story,
    required this.floats,
    required this.onViewers,
  });

  final StoryModel story;

  /// What the story was given rises out of here when it opens.
  final GlobalKey<FloatingReactionsState> floats;
  final VoidCallback onViewers;

  @override
  Widget build(BuildContext context) {
    final notice = switch (story.status) {
      StoryStatus.pendingModeration =>
        'Waiting for review — only you can see it for now',
      StoryStatus.held => 'Held for review — only you can see it',
      StoryStatus.rejected => 'Not approved — only you can see it',
      _ => null,
    };
    final reactions = story.reactionCounts ?? const {};
    return FloatingReactions(
      key: floats,
      rise: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null) ...[
            Glass(
              key: const Key('story_status_notice'),
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    story.status == StoryStatus.rejected
                        ? Icons.block
                        : Icons.hourglass_top,
                    size: 15,
                    color: story.status == StoryStatus.rejected
                        ? NowaColors.danger
                        : NowaColors.supportInk,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(notice, style: work(size: 12.5))),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              GestureDetector(
                key: const Key('story_viewers_button'),
                onTap: onViewers,
                child: Glass(
                  radius: 14,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 16),
                      const SizedBox(width: 7),
                      Text(
                        '${story.viewCount ?? 0} ${story.viewCount == 1 ? 'view' : 'views'}',
                        style: sora(size: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              for (final entry in reactions.entries)
                Padding(
                  key: Key('story_reaction_count_${entry.key.name}'),
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReactionIcon(reaction: entry.key, size: 20),
                      const SizedBox(width: 4),
                      Text('${entry.value}', style: sora(size: 12.5)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reactions and the reply box, for everyone but the owner.
class _ViewerFooter extends StatelessWidget {
  const _ViewerFooter({
    required this.story,
    required this.floats,
    required this.reply,
    required this.replyFocus,
    required this.sending,
    required this.onReact,
    required this.onSend,
    required this.onChanged,
  });

  final StoryModel story;
  final GlobalKey<FloatingReactionsState> floats;
  final TextEditingController reply;
  final FocusNode replyFocus;
  final bool sending;
  final ValueChanged<StoryReaction> onReact;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  static const _reactions = [
    StoryReaction.like,
    StoryReaction.love,
    StoryReaction.wow,
    StoryReaction.angry,
    StoryReaction.sad,
  ];

  /// Every tap sends the emoji flying, choosing or taking back alike: it is
  /// the acknowledgement either way.
  Widget _reactionButton(StoryReaction reaction) => Builder(
        builder: (button) => GestureDetector(
          key: Key('story_reaction_${reaction.name}'),
          onTap: () {
            final box = button.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              floats.currentState?.burst(
                reaction,
                box.localToGlobal(box.size.center(Offset.zero)),
              );
            }
            HapticFeedback.selectionClick();
            onReact(reaction);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: story.myReaction == reaction
                  ? NowaColors.accent.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: story.myReaction == reaction ? 1.2 : 1,
              child: ReactionIcon(reaction: reaction, size: 30),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingReactions(
          key: floats,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final reaction in _reactions) _reactionButton(reaction),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Glass(
          radius: 22,
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('story_reply_field'),
                  controller: reply,
                  focusNode: replyFocus,
                  maxLength: _maxReplyLength,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSend(),
                  textInputAction: TextInputAction.send,
                  style: work(size: 14),
                  cursorColor: NowaColors.accent,
                  decoration: InputDecoration(
                    hintText: 'Send a message…',
                    hintStyle: work(size: 14, color: NowaColors.dim),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              IconButton(
                key: const Key('story_reply_send'),
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NowaColors.accent,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: NowaColors.accent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Audience and delete. Pops a visibility name or `'delete'`.
class _OwnerMenu extends StatelessWidget {
  const _OwnerMenu({required this.current});

  final StoryVisibility current;

  @override
  Widget build(BuildContext context) {
    Widget audience(StoryVisibility value, IconData icon, String label) =>
        ListTile(
          key: Key('story_menu_${value.name}'),
          leading: Icon(icon, color: NowaColors.text),
          title: Text(label, style: sora(size: 14)),
          trailing: current == value
              ? const Icon(Icons.check, color: NowaColors.accent)
              : null,
          onTap: () => Navigator.of(context).pop(value.name),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Who can see this story', style: sora(size: 14)),
            const SizedBox(height: 6),
            audience(StoryVisibility.public, Icons.public, 'Everyone'),
            audience(StoryVisibility.friends, Icons.people_alt_outlined,
                'Friends'),
            audience(StoryVisibility.private, Icons.lock_outline, 'Only me'),
            const Divider(color: NowaColors.hairline),
            ListTile(
              key: const Key('story_menu_delete'),
              leading: const Icon(Icons.delete_outline,
                  color: NowaColors.danger),
              title: Text(
                'Delete story',
                style: sora(size: 14, color: NowaColors.danger),
              ),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
  }
}
