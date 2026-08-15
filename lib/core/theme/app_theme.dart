import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the Nowa look — ported verbatim from the design mock so
/// every screen shares one palette.
class NowaColors {
  static const bg = Color(0xFF0B0A0D);
  static const surface = Color(0xFF15131A);
  static const surfaceHigh = Color(0xFF1E1B24);
  static const stripeA = Color(0xFF211D29);
  static const stripeB = Color(0xFF17151C);
  static const accent = Color(0xFFE75BC0);
  static const support = Color(0xFF1FB3CC);
  static const supportInk = Color(0xFF5FD7EA);
  static const text = Color(0xFFF6F4F8);
  static const dim = Color(0x9EFFFFFF); // rgba(255,255,255,.62)
  static const hairline = Color(0x1AFFFFFF);
  static const glass = Color(0x8C141218); // rgba(20,18,24,.55)
  static const danger = Color(0xFFFF6B81);
}

/// Sora — names, counts, labels.
TextStyle sora({
  double size = 13,
  FontWeight weight = FontWeight.w600,
  Color color = NowaColors.text,
  double? height,
  double? spacing,
}) =>
    GoogleFonts.sora(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

/// Work Sans — captions, body.
TextStyle work({
  double size = 13.5,
  FontWeight weight = FontWeight.w400,
  Color color = NowaColors.text,
  double height = 1.45,
}) =>
    GoogleFonts.workSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

/// 1.2K / 3.4M formatting used by the action rail and every count in the app.
String compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: NowaColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: NowaColors.accent,
        secondary: NowaColors.support,
        surface: NowaColors.surface,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
