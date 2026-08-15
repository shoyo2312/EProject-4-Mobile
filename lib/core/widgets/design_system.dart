import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

/// Diagonal striped placeholder that stands in for media that is missing,
/// still loading, or not backed by an endpoint yet.
class StripedPlaceholder extends StatelessWidget {
  const StripedPlaceholder({
    super.key,
    this.label,
    this.radius = 0,
    this.fontSize = 11,
    this.band = 8,
  });

  final String? label;
  final double radius;
  final double fontSize;
  final double band;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _StripePainter(band),
        child: Center(
          child: label == null || label!.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: fontSize,
                      letterSpacing: 0.4,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter(this.band);
  final double band;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = NowaColors.stripeB,
    );
    final paint = Paint()
      ..color = NowaColors.stripeA
      ..strokeWidth = band
      ..style = PaintingStyle.stroke;
    final step = band * 2;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.band != band;
}

/// A network image that falls back to the striped placeholder while loading
/// and when the URL is null or fails — the design never shows an empty box.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.radius = 0,
    this.band = 8,
    this.label,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double radius;
  final double band;
  final String? label;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback =
        StripedPlaceholder(label: label, radius: radius, band: band, fontSize: 9);
    if (url == null || url!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

/// Square avatar with the design's rounded-corner frame. Falls back to the
/// striped tile when the user has no picture.
class NowaAvatar extends StatelessWidget {
  const NowaAvatar({
    super.key,
    required this.url,
    this.size = 44,
    this.radius = 16,
    this.border = true,
  });

  final String? url;
  final double size;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: border
            ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: RemoteImage(url: url, radius: radius - 1, band: 5, label: 'pfp'),
    );
  }
}

/// Frosted container used for the rail, nav bar and top chips.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.opacity = 0.5,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF141218).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Pill used for feed sources, discover categories, inbox filters.
class Chip2 extends StatelessWidget {
  const Chip2({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: active ? NowaColors.accent : const Color(0x80141218),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active ? NowaColors.accent : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: sora(
            size: 12.5,
            weight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
    return expand ? Expanded(child: child) : child;
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: sora(
          size: 10,
          weight: FontWeight.w600,
          spacing: 1.4,
          color: NowaColors.text.withValues(alpha: 0.38),
        ),
      );
}

/// Solid accent button used for the primary action on a page.
class NowaButton extends StatelessWidget {
  const NowaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.filled = true,
    this.height = 44,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool filled;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? NowaColors.accent.withValues(alpha: enabled ? 1 : 0.4)
              : const Color(0xFF1A171F),
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 7),
                  ],
                  Text(label, style: sora(size: 13.5, color: Colors.white)),
                ],
              ),
      ),
    );
  }
}
