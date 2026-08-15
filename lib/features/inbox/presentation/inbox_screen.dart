import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/inbox/data/sample_notifications.dart';

/// The activity list from the design. No notification service exists yet, so
/// the rows come from [sampleNotifications] and the header says so.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String _tab = 'All';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 14,
        16,
        130,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Inbox', style: sora(size: 26, spacing: -0.6)),
            const Spacer(),
            Text(
              'Mark all read',
              style: work(size: 12, height: 1, color: NowaColors.accent),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const SectionLabel('SAMPLE DATA · NOT CONNECTED'),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final t in ['All', 'Likes', 'Mentions'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip2(
                  label: t,
                  active: t == _tab,
                  onTap: () => setState(() => _tab = t),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final n in sampleNotifications) _Row(notification: n),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.notification});

  final InboxNotification notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const StripedPlaceholder(radius: 23, band: 5),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: n.accent ? NowaColors.accent : NowaColors.support,
                      shape: BoxShape.circle,
                      border: Border.all(color: NowaColors.bg, width: 2),
                    ),
                    child: Text(n.badge, style: sora(size: 10, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.who, style: sora(size: 13.5, height: 1.3)),
                const SizedBox(height: 3),
                Text(
                  n.what,
                  style: work(
                    size: 12.5,
                    height: 1.4,
                    color: NowaColors.text.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            n.when,
            style: work(
              size: 11,
              height: 1,
              color: NowaColors.text.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 44,
            height: 58,
            child: StripedPlaceholder(radius: 10, band: 5),
          ),
        ],
      ),
    );
  }
}
