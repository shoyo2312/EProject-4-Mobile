import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

/// What a long press on the feed's comment button offers. Each one is posted
/// as the whole text of a comment, so it goes through the same screening as
/// anything typed.
const quickCommentEmojis = ['😂', '😍', '🔥', '👏', '😮', '😢', '💯'];

const _slot = 42.0;
const _padding = 8.0;

/// A row of [quickCommentEmojis] floating just above [anchor] (where the
/// finger is). Resolves to the one picked, or null when dismissed.
Future<String?> showQuickCommentPicker(
  BuildContext context, {
  required Offset anchor,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss quick comments',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (dialogContext, _, _) => _QuickCommentPicker(anchor: anchor),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(curved),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );
    },
  );
}

class _QuickCommentPicker extends StatelessWidget {
  const _QuickCommentPicker({required this.anchor});

  final Offset anchor;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final width = quickCommentEmojis.length * _slot + _padding * 2;
    // Centred on the finger, but never off either edge of a narrow phone.
    final left = (anchor.dx - width / 2).clamp(12.0, screen.width - width - 12);

    return Stack(
      children: [
        Positioned(
          left: left,
          bottom: screen.height - anchor.dy + 28,
          child: Material(
            key: const Key('quick_comment_picker'),
            color: NowaColors.surface,
            elevation: 8,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _padding,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final emoji in quickCommentEmojis)
                    InkResponse(
                      key: Key('quick_comment_$emoji'),
                      radius: _slot / 2,
                      onTap: () => Navigator.of(context).pop(emoji),
                      child: SizedBox(
                        width: _slot,
                        height: _slot,
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
