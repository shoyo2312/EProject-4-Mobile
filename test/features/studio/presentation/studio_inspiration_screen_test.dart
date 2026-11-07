import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'studio_test_app.dart';

void main() {
  testWidgets('trending is ranked and opens a video', (tester) async {
    await pumpStudio(tester, '/studio/inspiration');

    expect(find.text('#1'), findsOneWidget);

    await tester.tap(find.text('#1'));
    await tester.pumpAndSettle();

    expect(find.textContaining('video '), findsOneWidget);
  });

  testWidgets('My inspiration shows the saved tab', (tester) async {
    await pumpStudio(tester, '/studio/inspiration');

    await tester.tap(find.text('My inspiration'));
    await tester.pumpAndSettle();

    // Saved videos or the empty note, never an error.
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(TabBarView), findsOneWidget);
  });
}
