import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';

/// One slot on the horizontal glass rail under a feed caption.
class RailAction {
  const RailAction({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.onTap,
    this.itemKey,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Null renders the slot as a read-only counter — used for the metrics the
  /// backend reports but exposes no write endpoint for.
  final VoidCallback? onTap;
  final Key? itemKey;
}

/// Horizontal glass rail: like → comment → save → share.
class ActionRail extends StatelessWidget {
  const ActionRail({super.key, required this.actions});

  final List<RailAction> actions;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const _Divider(),
            _item(actions[i]),
          ],
        ],
      ),
    );
  }

  Widget _item(RailAction action) {
    return Expanded(
      child: GestureDetector(
        key: action.itemKey,
        onTap: action.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 23, color: action.color),
              const SizedBox(height: 4),
              Text(action.label, style: sora(size: 11, color: action.color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 26,
        color: Colors.white.withValues(alpha: 0.1),
      );
}
