import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'studio_test_app.dart';

void main() {
  testWidgets('home shows the tools, key metrics and recent rows', (tester) async {
    await pumpStudio(tester, '/studio');

    expect(find.text('Nowa Studio'), findsOneWidget);
    for (final tool in ['upload', 'posts', 'analytics', 'comments', 'inspiration']) {
      expect(find.byKey(Key('studio_tool_$tool')), findsOneWidget, reason: tool);
    }
    expect(find.byKey(const Key('studio_metric_views')), findsOneWidget);
    expect(find.byKey(const Key('studio_metric_followers')), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
  });

  testWidgets('picking a window relabels the metrics', (tester) async {
    await pumpStudio(tester, '/studio');

    await tester.tap(find.byKey(const Key('studio_range_28')));
    await tester.pumpAndSettle();

    expect(find.text('Last 28 days'), findsOneWidget);
  });

  testWidgets('a metric opens analytics on that metric', (tester) async {
    await pumpStudio(tester, '/studio');

    await tester.tap(find.byKey(const Key('studio_metric_likes')));
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsOneWidget);
    // The chart section is titled after the selected metric.
    expect(find.text('Likes'), findsWidgets);
  });

  testWidgets('Upload goes to the Create tab', (tester) async {
    await pumpStudio(tester, '/studio');

    await tester.tap(find.byKey(const Key('studio_tool_upload')));
    await tester.pumpAndSettle();

    expect(find.text('feed tab=create'), findsOneWidget);
  });
}
