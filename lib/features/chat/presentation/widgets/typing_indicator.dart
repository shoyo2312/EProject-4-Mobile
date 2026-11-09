import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';

/// The thread's "typing" row: the other person's avatar beside a small bubble
/// of three dots that take turns. Not a message — never in the list, never
/// counted, never read.
///
/// The row is always there, at a fixed height, whether or not anyone is
/// typing: it appearing must not move the list above it, so somebody reading
/// history is not nudged. Only its content comes and goes, fading in. The
/// dots animate only while [active]; with reduced motion they keep still.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    super.key,
    required this.active,
    required this.name,
    this.avatarUrl,
  });

  static const height = 30.0;

  final bool active;
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: active
                ? Semantics(
                    key: const Key('chat_typing_indicator'),
                    container: true,
                    liveRegion: true,
                    label: '$name is typing',
                    // Read as the one sentence above, not avatar and dots.
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NowaAvatar(
                            url: avatarUrl,
                            size: 24,
                            radius: 12,
                            border: false,
                          ),
                          const SizedBox(width: 6),
                          const _DotsBubble(),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _DotsBubble extends StatefulWidget {
  const _DotsBubble();

  @override
  State<_DotsBubble> createState() => _DotsBubbleState();
}

class _DotsBubbleState extends State<_DotsBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: NowaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _dot(i),
            ],
          ],
        ),
      ),
    );
  }

  /// Each dot rises and falls over half a cycle, starting a fifth of a cycle
  /// after the one before, and rests the remainder.
  Widget _dot(int index) {
    final phase = (_controller.value - index * 0.2) % 1.0;
    final lift = phase < 0.5 ? math.sin(phase / 0.5 * math.pi) : 0.0;
    return Transform.translate(
      offset: Offset(0, -3 * lift),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NowaColors.text.withValues(alpha: 0.45 + 0.4 * lift),
        ),
      ),
    );
  }
}
