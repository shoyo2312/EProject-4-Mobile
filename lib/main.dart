import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/router/app_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: TikTokMobileApp()));
}

class TikTokMobileApp extends ConsumerWidget {
  const TikTokMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'TikTok Mobile',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
