import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';

/// Floating glass tab bar. Index 2 is the create button.
class NowaNavBar extends StatelessWidget {
  const NowaNavBar({
    super.key,
    required this.index,
    required this.onTap,
    this.unread = 0,
  });

  final int index;
  final ValueChanged<int> onTap;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 22,
      opacity: 0.72,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            _item(0, Icons.home_outlined, 'Feed'),
            _item(1, Icons.search, 'Discover'),
            _create(),
            _item(3, Icons.chat_bubble_outline, 'Inbox', badge: unread),
            _item(4, Icons.person_outline, 'You', key: const Key('feed_profile_button')),
          ],
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label, {int? badge, Key? key}) {
    final active = index == i;
    final color = active ? NowaColors.accent : NowaColors.dim;
    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(height: 3),
                Text(label,
                    style: sora(size: 9.5, weight: FontWeight.w500, color: color)),
              ],
            ),
            if (badge != null && badge > 0)
              Positioned(
                top: 4,
                right: 10,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17),
                  height: 17,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: NowaColors.accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$badge', style: sora(size: 10, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _create() {
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 56,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [NowaColors.accent, NowaColors.support],
          ),
          boxShadow: [
            BoxShadow(
              color: NowaColors.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 20, color: Colors.white),
      ),
    );
  }
}
