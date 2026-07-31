import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';

void main() {
  testWidgets('shows message and invokes onRetry when button tapped', (tester) async {
    var retried = false;

    await tester.pumpWidget(MaterialApp(
      home: ErrorView(
        message: 'Something went wrong',
        onRetry: () => retried = true,
      ),
    ));

    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('hides retry button when onRetry is null', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ErrorView(message: 'Oops'),
    ));

    expect(find.text('Retry'), findsNothing);
  });
}
