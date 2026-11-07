import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/mock/mock_backend.dart';

import 'studio_test_app.dart';

void main() {
  testWidgets('lists every one of my posts', (tester) async {
    await pumpStudio(tester, '/studio/posts');

    for (final id in mockMyVideoIds) {
      expect(find.byKey(Key('studio_post_$id')), findsOneWidget, reason: id);
    }
  });

  testWidgets('a search that matches nothing says so', (tester) async {
    await pumpStudio(tester, '/studio/posts');

    await tester.enterText(
        find.byKey(const Key('studio_posts_search')), 'zzzz-no-such-post');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('No posts match these filters.'), findsOneWidget);
  });

  testWidgets('filters change the sort line', (tester) async {
    await pumpStudio(tester, '/studio/posts');

    await tester.tap(find.byKey(const Key('studio_posts_filter')));
    await tester.pumpAndSettle();
    for (final target in [
      find.text('Views').first,
      find.text('Low to high'),
      find.byKey(const Key('studio_filter_apply')),
    ]) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Sorted by views, low to high'), findsOneWidget);
  });

  testWidgets('pinning from the actions sheet marks the row', (tester) async {
    await pumpStudio(tester, '/studio/posts');
    final id = mockMyVideoIds.first;
    final row = find.byKey(Key('studio_post_$id'));
    expect(find.descendant(of: row, matching: find.text('Pinned')), findsNothing);

    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('studio_action_pin')));
    await tester.pumpAndSettle();

    expect(find.descendant(of: row, matching: find.text('Pinned')), findsOneWidget);
  });

  testWidgets('deleting asks first, then removes the row', (tester) async {
    await pumpStudio(tester, '/studio/posts');
    // The first row: later ones may not be built yet in a lazy list.
    final id = mockMyVideoIds.first;

    await tester.tap(find.byKey(Key('studio_post_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('studio_action_delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this post?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('studio_delete_confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('studio_post_$id')), findsNothing);
    expect(find.text('Post deleted'), findsOneWidget);
  });

  testWidgets('Edit post opens the edit page', (tester) async {
    await pumpStudio(tester, '/studio/posts');

    await tester.tap(find.byKey(Key('studio_post_${mockMyVideoIds.first}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('studio_action_edit')));
    await tester.pumpAndSettle();

    expect(find.text('Edit post'), findsOneWidget);
    expect(find.byKey(const Key('studio_edit_title')), findsOneWidget);
  });
}
