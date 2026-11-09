import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';

void main() {
  late BuildContext ctx;

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold();
          },
        ),
      ),
    );
  }

  final toast = find.byKey(NowaToast.viewKey);

  testWidgets('shows the message, then leaves on its own', (tester) async {
    await pumpHost(tester);

    NowaToast.of(ctx).success('Link copied');
    await tester.pumpAndSettle();
    expect(find.text('Link copied'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(toast, findsNothing);
  });

  testWidgets('an error gets its own icon and stays a little longer', (
    tester,
  ) async {
    await pumpHost(tester);

    NowaToast.of(ctx).error('Stories could not be loaded');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(toast, findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(toast, findsNothing);
  });

  testWidgets('a new toast replaces the one on screen', (tester) async {
    await pumpHost(tester);

    NowaToast.of(ctx).info('first');
    await tester.pumpAndSettle();
    NowaToast.of(ctx).info('second');
    await tester.pumpAndSettle();

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(toast, findsOneWidget);
  });

  testWidgets('the action runs once and closes the toast', (tester) async {
    await pumpHost(tester);
    var undone = 0;

    NowaToast.of(ctx).success(
      'Reposted to your profile',
      actionLabel: 'Undo',
      actionKey: const Key('undo'),
      onAction: () => undone++,
    );
    // Not pumpAndSettle: the countdown bar keeps animating until it runs out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('undo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(undone, 1);
    expect(toast, findsNothing);
  });

  testWidgets('swiping up dismisses it early', (tester) async {
    await pumpHost(tester);

    NowaToast.of(ctx).info('Sleep hours start in 10 minutes');
    await tester.pumpAndSettle();
    await tester.drag(
      find.text('Sleep hours start in 10 minutes'),
      const Offset(0, -60),
    );
    await tester.pumpAndSettle();

    expect(toast, findsNothing);
  });

  testWidgets('stays clear of the status bar', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 90);
    addTearDown(tester.view.resetPadding);
    await pumpHost(tester);

    NowaToast.of(ctx).info('hello');
    await tester.pumpAndSettle();

    final top = tester.getTopLeft(find.text('hello')).dy;
    final dpr = tester.view.devicePixelRatio;
    expect(top, greaterThan(90 / dpr));
  });
}
