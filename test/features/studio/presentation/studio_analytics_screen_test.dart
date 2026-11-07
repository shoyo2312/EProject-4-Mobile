import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'studio_test_app.dart';

void main() {
  testWidgets('overview draws a chart for the selected metric', (tester) async {
    await pumpStudio(tester, '/studio/analytics');

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Video views'), findsWidgets);

    await tester.tap(find.byKey(const Key('studio_overview_comments')));
    await tester.pumpAndSettle();

    // The chart card is now titled Comments, as well as the tile.
    expect(find.text('Comments'), findsNWidgets(2));
  });

  testWidgets('content ranks videos and opens one', (tester) async {
    await pumpStudio(tester, '/studio/analytics?tab=1');

    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('studio_content_sort_viewers')));
    await tester.pumpAndSettle();
    expect(find.text('viewers'), findsWidgets);

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('Video analytics'), findsOneWidget);
  });

  testWidgets('viewers shows active hours and days', (tester) async {
    await pumpStudio(tester, '/studio/analytics?tab=2');

    expect(find.text('Total viewers'), findsOneWidget);
    expect(find.text('Most active times'), findsOneWidget);
    expect(find.byType(BarChart), findsWidgets);
  });
}
