import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/widgets/nav_bar.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, int unread) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NowaNavBar(index: 0, onTap: (_) {}, unread: unread),
          ),
        ),
      ),
    );
  }

  const inboxBadge = Key('nav_badge_3');

  testWidgets('no badge while nothing is unread', (tester) async {
    await pumpBar(tester, 0);

    expect(find.byKey(inboxBadge), findsNothing);
  });

  testWidgets('shows the exact count up to 99', (tester) async {
    await pumpBar(tester, 99);

    expect(tester.widget<Text>(find.byKey(inboxBadge)).data, '99');
  });

  testWidgets('shows 99+ from 100 on, without overflowing', (tester) async {
    await pumpBar(tester, 250);

    expect(tester.widget<Text>(find.byKey(inboxBadge)).data, '99+');
    expect(tester.takeException(), isNull);
  });
}
