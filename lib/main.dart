import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:tiktok_mobile/mock/mock_backend.dart';
import 'package:tiktok_mobile/core/router/app_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

void main() {
  // The whole app is a dark, edge-to-edge surface — keep the status bar icons
  // light over it.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(
    ProviderScope(
      overrides: Env.useMockData ? mockOverrides() : const [],
      child: const TikTokMobileApp(),
    ),
  );
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
