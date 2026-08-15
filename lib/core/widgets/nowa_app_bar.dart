import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

/// Flat dark header used by the pushed pages (edit profile, user lists).
class NowaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NowaAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: NowaColors.bg,
      surfaceTintColor: NowaColors.bg,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white, size: 20),
      title: Text(title, style: sora(size: 15.5, spacing: -0.2)),
      actions: actions,
      shape: const Border(bottom: BorderSide(color: NowaColors.hairline)),
    );
  }
}
