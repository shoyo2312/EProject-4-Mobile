import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/app_share.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

/// Resolves to true when the viewer actually shared something — that, and not
/// opening the sheet, is what counts as a share (interaction doc 3.7). Handing
/// the link to another app or copying it both count.
///
/// [saved] and [onToggleSave] drive the "Add to favorites" row, which is the
/// same save as the bookmark on the rail.
Future<bool> showShareSheet(
  BuildContext context, {
  required VideoModel video,
  bool saved = false,
  VoidCallback? onToggleSave,
}) async {
  final shared = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ShareSheet(
      video: video,
      saved: saved,
      onToggleSave: onToggleSave,
    ),
  );
  return shared ?? false;
}

/// The page on the web app that plays this video.
String videoShareLink(VideoModel video) => '${Env.webBaseUrl}/video/${video.id}';

class _Target {
  const _Target({
    required this.app,
    required this.label,
    required this.logo,
    required this.colors,
  });

  final ShareApp app;
  final String label;

  /// White-filled glyph from `assets/share_icons/` (Simple Icons).
  final String logo;

  /// One colour for a flat tile, several for the brand's gradient.
  final List<Color> colors;
}

const _targets = <_Target>[
  _Target(
    app: ShareApp.messages,
    label: 'Messages',
    logo: 'assets/share_icons/googlemessages.svg',
    colors: [Color(0xFF1A73E8)],
  ),
  _Target(
    app: ShareApp.zalo,
    label: 'Zalo',
    logo: 'assets/share_icons/zalo.svg',
    colors: [Color(0xFF0068FF)],
  ),
  _Target(
    app: ShareApp.messenger,
    label: 'Messenger',
    logo: 'assets/share_icons/messenger.svg',
    colors: [Color(0xFF0099FF), Color(0xFFA033FF), Color(0xFFFF5280)],
  ),
  _Target(
    app: ShareApp.instagram,
    label: 'Instagram',
    logo: 'assets/share_icons/instagram.svg',
    colors: [
      Color(0xFFFEDA75),
      Color(0xFFFA7E1E),
      Color(0xFFD62976),
      Color(0xFF962FBF),
      Color(0xFF4F5BD5),
    ],
  ),
  _Target(
    app: ShareApp.facebook,
    label: 'Facebook',
    logo: 'assets/share_icons/facebook.svg',
    colors: [Color(0xFF0866FF)],
  ),
];

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({
    required this.video,
    required this.saved,
    required this.onToggleSave,
  });

  final VideoModel video;
  final bool saved;
  final VoidCallback? onToggleSave;

  /// The link alone: Facebook drops any text around a URL, and every other
  /// app turns a bare link into a preview card anyway.
  String get _link => videoShareLink(video);

  Future<void> _shareTo(BuildContext context, ShareApp app) async {
    final shared = await AppShare.shareTo(app, _link);
    if (shared && context.mounted) Navigator.of(context).pop(true);
  }

  Future<void> _shareMore(BuildContext context) async {
    final shared = await AppShare.shareWithSystem(_link);
    if (shared && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                for (final t in _targets) ...[
                  _TargetTile(
                    key: Key('share_target_${t.app.name}'),
                    label: t.label,
                    onTap: () => _shareTo(context, t.app),
                    tile: _BrandTile(target: t),
                  ),
                  const SizedBox(width: 16),
                ],
                // Every other app on the phone, through the system sheet.
                _TargetTile(
                  key: const Key('share_target_more'),
                  label: 'More',
                  onTap: () => _shareMore(context),
                  tile: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: NowaColors.text.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: NowaColors.text,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: NowaColors.hairline, height: 24),
          _Row(
            icon: Icons.link_rounded,
            label: 'Copy link',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: _link));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied')),
              );
              Navigator.of(context).pop(true);
            },
          ),
          _Row(
            icon: saved ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined,
            label: saved ? 'Remove from favorites' : 'Add to favorites',
            onTap: onToggleSave == null
                ? null
                : () {
                    Navigator.of(context).pop(false);
                    onToggleSave!();
                  },
          ),
          const _Row(icon: Icons.flag_outlined, label: 'Report', danger: true),
        ],
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    super.key,
    required this.label,
    required this.onTap,
    required this.tile,
  });

  final String label;
  final VoidCallback onTap;
  final Widget tile;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          tile,
          const SizedBox(height: 8),
          SizedBox(
            width: 62,
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: work(
                size: 11.5,
                color: NowaColors.text.withValues(alpha: 0.62),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The app's own logo in white on its brand colour — how it looks on a home
/// screen, so it is recognised at a glance.
class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.target});

  final _Target target;

  @override
  Widget build(BuildContext context) {
    final colors = target.colors;
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.length == 1 ? colors.first : null,
        gradient: colors.length > 1
            ? LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: colors,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SvgPicture.asset(
        target.logo,
        width: 28,
        height: 28,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
