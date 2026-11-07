import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_comments_screen.dart';
import 'package:tiktok_mobile/mock/mock_backend.dart';

import 'studio_test_app.dart';

void main() {
  testWidgets('one video shows lifetime, retention, sources and audience', (
    tester,
  ) async {
    await pumpStudio(tester, '/studio/analytics/${mockMyVideoIds.first}');

    expect(find.text('Video analytics'), findsOneWidget);
    expect(find.text('Lifetime'), findsOneWidget);
    expect(find.text('Average watch time'), findsOneWidget);

    // The page's own vertical list, not the horizontal range chips.
    final page = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(find.text('Retention'), 300, scrollable: page);
    expect(find.textContaining('Most viewers stop watching'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('For You'), 300, scrollable: page);
    await tester.scrollUntilVisible(find.text('18-24'), 300, scrollable: page);
    expect(find.text('Returning viewers'), findsOneWidget);
  });

  testWidgets('the comments button opens that video\'s comments', (tester) async {
    await pumpStudio(tester, '/studio/analytics/${mockMyVideoIds.first}');

    await tester.tap(find.byTooltip('Comments'));
    await tester.pumpAndSettle();

    final screen =
        tester.widget<StudioCommentsScreen>(find.byType(StudioCommentsScreen));
    expect(screen.initialVideoId, mockMyVideoIds.first);
  });
}
