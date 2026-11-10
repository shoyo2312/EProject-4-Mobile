import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/sticker_sheet.dart';

/// What a reply answers, above the reply itself: "You replied" and the
/// original in a quieter bubble. Tapping it goes to the original. A recalled
/// or unavailable original is shown as such and goes nowhere.
class ReplyQuoteBlock extends StatelessWidget {
  const ReplyQuoteBlock({
    super.key,
    required this.quote,
    required this.label,
    required this.mine,
    required this.maxWidth,
    this.onTap,
  });

  final ReplyQuote quote;

  /// "You replied to yourself", "Lan replied to you", …
  final String label;
  final bool mine;
  final double maxWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = NowaColors.text.withValues(alpha: 0.55);
    final line = BorderSide(
      color: NowaColors.text.withValues(alpha: 0.35),
      width: 2,
    );
    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reply_rounded, size: 13, color: meta),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: work(size: 11, height: 1.2, color: meta),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          key: Key('chat_quote_${quote.messageId}'),
          behavior: HitTestBehavior.opaque,
          onTap: quote.visible ? onTap : null,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
            decoration: BoxDecoration(
              color: NowaColors.text.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: mine ? BorderSide.none : line,
                right: mine ? line : BorderSide.none,
              ),
            ),
            child: _body(meta),
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _body(Color meta) {
    final sticker = quote.sticker;
    if (quote.visible && sticker != null) {
      return StickerImage(sticker: sticker, size: 40);
    }
    final thumb = quote.visible ? quote.video?.thumbnailUrl : null;
    final text = Text(
      quote.text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: work(size: 12.5, height: 1.3, color: meta).copyWith(
        fontStyle: quote.visible ? FontStyle.normal : FontStyle.italic,
      ),
    );
    if (thumb == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: thumb,
            width: 28,
            height: 40,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const SizedBox(width: 28, height: 40),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: text),
      ],
    );
  }
}

/// A message row that answers a swipe from right to left: it follows the
/// finger, a reply arrow fades in behind it, and letting go past the mark
/// starts a reply. Null [onReply] (a pending or unsent message, a request)
/// leaves the row still.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({super.key, required this.child, this.onReply});

  final Widget child;
  final VoidCallback? onReply;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  /// How far the row must travel for letting go to count.
  static const _trigger = 56.0;

  /// How far it travels at most.
  static const _limit = 84.0;

  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..addListener(_onSettle);
  double _dx = 0;
  double _from = 0;
  bool _armed = false;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onSettle() {
    setState(() => _dx = _from * (1 - Curves.easeOut.transform(_settle.value)));
  }

  void _onStart(DragStartDetails _) => _settle.stop();

  void _onUpdate(DragUpdateDetails details) {
    final dx = (_dx + details.delta.dx).clamp(-_limit, 0.0);
    final armed = -dx >= _trigger;
    if (armed && !_armed) HapticFeedback.selectionClick();
    setState(() {
      _dx = dx;
      _armed = armed;
    });
  }

  void _onEnd([DragEndDetails? _]) {
    if (_armed) widget.onReply?.call();
    _armed = false;
    _from = _dx;
    if (_from != 0) _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onReply != null;
    final shown = (-_dx / _trigger).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: enabled ? _onStart : null,
      onHorizontalDragUpdate: enabled ? _onUpdate : null,
      onHorizontalDragEnd: enabled ? _onEnd : null,
      onHorizontalDragCancel: enabled ? _onEnd : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (shown > 0)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: shown,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * shown,
                    child: Container(
                      key: const Key('chat_swipe_reply_icon'),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _armed
                            ? NowaColors.accent.withValues(alpha: 0.3)
                            : NowaColors.surfaceHigh,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.reply_rounded,
                        size: 18,
                        color: NowaColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}

/// The reactions under a message, one pill per emoji. Tapping the viewer's
/// own takes it back; tapping another's reacts with the same.
class ReactionPills extends StatelessWidget {
  const ReactionPills({
    super.key,
    required this.messageId,
    required this.groups,
    required this.mine,
    this.onTap,
  });

  final String messageId;
  final List<ReactionGroup> groups;
  final bool mine;

  /// Null where the viewer may not react (a request, a block).
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      // Tucked against the bubble's lower edge.
      offset: const Offset(0, -6),
      child: Wrap(
        alignment: mine ? WrapAlignment.end : WrapAlignment.start,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final group in groups)
            GestureDetector(
              key: Key('chat_reaction_${messageId}_${group.emoji}'),
              onTap: onTap == null ? null : () => onTap!(group.emoji),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: group.mine
                      ? NowaColors.accent.withValues(alpha: 0.22)
                      : NowaColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: group.mine
                        ? NowaColors.accent.withValues(alpha: 0.7)
                        : NowaColors.bg,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(group.emoji, style: const TextStyle(fontSize: 13)),
                    if (group.count > 1) ...[
                      const SizedBox(width: 3),
                      Text(
                        '${group.count}',
                        style: work(
                          size: 11,
                          height: 1,
                          color: NowaColors.text.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The six reactions in a row, the viewer's own marked: the top of a
/// message's long-press sheet.
class ReactionStrip extends StatelessWidget {
  const ReactionStrip({super.key, required this.current, required this.onPick});

  final String? current;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: NowaColors.surfaceHigh,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final emoji in chatReactions)
            Semantics(
              button: true,
              selected: emoji == current,
              label: emoji == current ? 'Remove $emoji' : 'React $emoji',
              child: InkWell(
                key: Key('chat_react_${chatReactions.indexOf(emoji)}'),
                customBorder: const CircleBorder(),
                onTap: () => onPick(emoji),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: emoji == current
                      ? BoxDecoration(
                          color: NowaColors.accent.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Above the composer while a reply is being written: who is answered, what
/// they said, and a way out.
class ReplyBar extends StatelessWidget {
  const ReplyBar({
    super.key,
    required this.name,
    required this.quote,
    required this.onClose,
  });

  final String name;
  final ReplyQuote quote;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chat_reply_bar'),
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      decoration: const BoxDecoration(
        color: NowaColors.surface,
        border: Border(top: BorderSide(color: NowaColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: NowaColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: work(
                    size: 12,
                    weight: FontWeight.w600,
                    color: NowaColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quote.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: work(
                    size: 12,
                    color: NowaColors.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('chat_reply_cancel'),
            tooltip: 'Cancel reply',
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              size: 18,
              color: NowaColors.text.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// A video shared from the app: its cover, title and a play mark. Tapping an
/// available one opens it; a deleted or private one says so.
class ChatVideoCardView extends StatelessWidget {
  const ChatVideoCardView({
    super.key,
    required this.card,
    required this.width,
    this.onOpen,
  });

  final ChatVideoCard? card;
  final double width;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final card = this.card;
    final available = card?.available ?? false;
    final thumb = available ? card!.thumbnailUrl : null;
    final height = width * 16 / 11;
    return GestureDetector(
      key: Key('chat_video_${card?.videoId}'),
      onTap: available ? onOpen : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          height: height,
          color: NowaColors.surfaceHigh,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              if (available) ...[
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                if ((card!.title ?? '').trim().isNotEmpty)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Text(
                      card.title!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: work(size: 11.5, height: 1.3, color: Colors.white),
                    ),
                  ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_outlined,
                          size: 26,
                          color: NowaColors.text.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          card?.state == 'UNKNOWN'
                              ? 'Video can\'t be loaded right now'
                              : 'This video isn\'t available',
                          textAlign: TextAlign.center,
                          style: work(
                            size: 11.5,
                            height: 1.3,
                            color: NowaColors.text.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
