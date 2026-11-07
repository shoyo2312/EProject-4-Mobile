import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_analytics_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_comments_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_edit_post_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_home_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_inspiration_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_posts_screen.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_video_analytics_screen.dart';
import 'package:tiktok_mobile/mock/mock_backend.dart';

/// Pumps the Studio routes over the mock backend, starting at [location].
/// Pages outside Studio are stand-ins that only say where they are.
Future<GoRouter> pumpStudio(WidgetTester tester, String location) async {
  // A phone-sized screen: Studio is laid out for one.
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/studio', builder: (_, _) => const StudioHomeScreen()),
      GoRoute(
        path: '/studio/analytics',
        builder: (_, state) => StudioAnalyticsScreen(
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
          initialMetric: state.uri.queryParameters['metric'],
        ),
      ),
      GoRoute(
        path: '/studio/analytics/:videoId',
        builder: (_, state) => StudioVideoAnalyticsScreen(
          videoId: state.pathParameters['videoId']!,
        ),
      ),
      GoRoute(path: '/studio/posts', builder: (_, _) => const StudioPostsScreen()),
      GoRoute(
        path: '/studio/posts/:videoId/edit',
        builder: (_, state) =>
            StudioEditPostScreen(videoId: state.pathParameters['videoId']!),
      ),
      GoRoute(
        path: '/studio/comments',
        builder: (_, state) => StudioCommentsScreen(
          initialVideoId: state.uri.queryParameters['videoId'],
        ),
      ),
      GoRoute(
        path: '/studio/inspiration',
        builder: (_, _) => const StudioInspirationScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (_, state) => Text('feed ${state.uri.query}'),
      ),
      GoRoute(
        path: '/video/:id',
        builder: (_, state) => Text('video ${state.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: mockOverrides(),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
