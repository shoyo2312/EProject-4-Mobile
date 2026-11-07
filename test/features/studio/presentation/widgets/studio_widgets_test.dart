import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('a metric tile shows its value and change', (tester) async {
    await tester.pumpWidget(_wrap(
      const MetricTile(label: 'Likes', value: 1200, previous: 800),
    ));

    expect(find.text('Likes'), findsOneWidget);
    expect(find.text('1.2K'), findsOneWidget);
    expect(find.text('+400 (+50.0%)'), findsOneWidget);
  });

  testWidgets('a falling metric is coloured as a fall', (tester) async {
    await tester.pumpWidget(_wrap(
      const ChangeText(current: 5, previous: 10),
    ));

    final text = tester.widget<Text>(find.text('-5 (-50.0%)'));
    expect(text.style?.color, NowaColors.danger);
  });

  testWidgets('a negative net count keeps its sign', (tester) async {
    await tester.pumpWidget(_wrap(
      const MetricTile(label: 'Net followers', value: -3),
    ));

    expect(find.text('-3'), findsOneWidget);
  });

  testWidgets('a bar list shows shares of the total', (tester) async {
    await tester.pumpWidget(_wrap(
      const BarList(rows: [('For You', 75), ('Search', 25)]),
    ));

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('an empty chart says there is no data', (tester) async {
    await tester.pumpWidget(_wrap(
      const StudioLineChart(values: [], labels: []),
    ));

    expect(find.text('No data yet'), findsOneWidget);
  });

  testWidgets('a post row marks pinned and not-live videos', (tester) async {
    await tester.pumpWidget(_wrap(StudioPostTile(
      video: VideoModel(
        id: '1',
        userId: '2',
        title: 'Trip',
        status: VideoStatus.pendingReview,
        visibility: VideoVisibility.private,
        viewCount: 1500,
        likeCount: 3,
        commentCount: 0,
        createdAt: DateTime(2026, 10, 17),
        pinnedAt: DateTime(2026, 10, 18),
      ),
    )));

    expect(find.text('Pinned'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Oct 17, 2026 · Only me'), findsOneWidget);
    expect(find.text('1.5K'), findsOneWidget);
  });
}
