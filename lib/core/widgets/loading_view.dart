import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2, color: NowaColors.accent),
      ),
    );
  }
}
