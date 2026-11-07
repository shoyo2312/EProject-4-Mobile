import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/studio/presentation/studio_edit_post_screen.dart';
import 'package:tiktok_mobile/mock/mock_backend.dart';

import 'studio_test_app.dart';

void main() {
  NowaSave save(WidgetTester tester) => NowaSave(tester);

  testWidgets('Save stays off until something changes', (tester) async {
    await pumpStudio(tester, '/studio/posts/${mockMyVideoIds.first}/edit');

    expect(save(tester).enabled, isFalse);

    await tester.enterText(find.byKey(const Key('studio_edit_title')), 'A new title');
    await tester.pump();

    expect(save(tester).enabled, isTrue);
  });

  testWidgets('an empty or too long title cannot be saved', (tester) async {
    await pumpStudio(tester, '/studio/posts/${mockMyVideoIds.first}/edit');

    await tester.enterText(find.byKey(const Key('studio_edit_title')), '   ');
    await tester.pump();
    expect(find.text('Add a title.'), findsOneWidget);
    expect(save(tester).enabled, isFalse);

    await tester.enterText(
        find.byKey(const Key('studio_edit_title')), 'x' * (titleLimit + 1));
    await tester.pump();
    expect(find.textContaining('at most $titleLimit'), findsOneWidget);
    expect(save(tester).enabled, isFalse);
  });

  testWidgets('saving a caption and visibility goes back with a note', (
    tester,
  ) async {
    final router = await pumpStudio(tester, '/studio/posts');
    router.push('/studio/posts/${mockMyVideoIds.first}/edit');
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('studio_edit_title')), 'Renamed');
    await tester.tap(find.byKey(const Key('studio_edit_visibility_private')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('studio_edit_save')));
    await tester.pumpAndSettle();

    expect(find.text('Changes saved'), findsOneWidget);
    expect(find.text('Posts'), findsOneWidget);
    expect(find.text('Renamed'), findsOneWidget);
  });
}

/// Reads whether the Save button would act on a tap.
class NowaSave {
  NowaSave(this.tester);

  final WidgetTester tester;

  bool get enabled {
    final detector = tester.widget<GestureDetector>(find.descendant(
      of: find.byKey(const Key('studio_edit_save')),
      matching: find.byType(GestureDetector),
    ).first);
    return detector.onTap != null;
  }
}
