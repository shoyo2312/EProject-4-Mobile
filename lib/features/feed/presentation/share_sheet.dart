import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

/// Share targets are presentation-only — there is no share endpoint and no
/// deep-link host yet, so "Copy link" is the single action that really does
/// something. The rest exist to show the sheet's layout.
/// Resolves to true when the viewer actually shared something — that, and not
/// opening the sheet, is what counts as a share (interaction doc 3.7). The
/// app-target row is decorative: nothing leaves the app, so nothing is
/// reported. Copying the link does leave the app, and does.
Future<bool> showShareSheet(
  BuildContext context, {
  required VideoModel video,
}) async {
  final shared = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ShareSheet(video: video),
  );
  return shared ?? false;
}

class _Target {
  const _Target(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

const _targets = <_Target>[
  _Target('Messages', Icons.chat_bubble_rounded, Color(0xFF34C759)),
  _Target('Zalo', Icons.forum_rounded, Color(0xFF2D8CFF)),
  _Target('Messenger', Icons.send_rounded, Color(0xFF7B4BFF)),
  _Target('Instagram', Icons.camera_alt_rounded, Color(0xFFE1306C)),
  _Target('Facebook', Icons.public_rounded, Color(0xFF1877F2)),
  _Target('Email', Icons.mail_rounded, Color(0xFF8E8E93)),
];

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final link = 'https://tiktok-clone.local/v/${video.id}';
    return Container(
      decoration: const BoxDecoration(
        color: NowaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: NowaColors.hairline)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: NowaColors.text.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text('Share to', style: sora(size: 15)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: _targets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (_, i) {
                final t = _targets[i];
                return Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: t.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: t.color.withValues(alpha: 0.4)),
                      ),
                      child: Icon(t.icon, color: t.color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 62,
                      child: Text(
                        t.label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: work(
                          size: 11.5,
                          color: NowaColors.text.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: NowaColors.hairline, height: 24),
          _Row(
            icon: Icons.link_rounded,
            label: 'Copy link',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) Navigator.of(context).pop(true);
            },
          ),
          const _Row(icon: Icons.bookmark_add_outlined, label: 'Add to favorites'),
          const _Row(icon: Icons.flag_outlined, label: 'Report', danger: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? NowaColors.danger : NowaColors.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 14),
            Text(label, style: work(size: 14, color: color)),
            const Spacer(),
            if (onTap == null)
              Text(
                'not connected',
                style: work(
                  size: 11,
                  color: NowaColors.text.withValues(alpha: 0.28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
