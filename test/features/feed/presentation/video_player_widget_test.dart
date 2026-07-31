import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/feed/presentation/video_player_widget.dart';

void main() {
  testWidgets('shows LoadingView before the video controller initializes', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: VideoPlayerWidget(
        url: 'https://example.com/does-not-load-in-tests.mp4',
        isActive: true,
      ),
    ));

    // Network video initialization never completes in the widget test
    // environment, so the widget must still show its loading state.
    expect(find.byType(LoadingView), findsOneWidget);
  });
}
