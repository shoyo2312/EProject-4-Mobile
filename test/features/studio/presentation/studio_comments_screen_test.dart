import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_comment_tile.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_widgets.dart';

import 'studio_test_app.dart';

String _firstId(WidgetTester tester) =>
    tester.widget<StudioCommentTile>(find.byType(StudioCommentTile).first).comment.id;

void main() {
  testWidgets('lists comments on my videos, held ones marked', (tester) async {
    await pumpStudio(tester, '/studio/comments');

    expect(find.byType(StudioCommentTile), findsWidgets);
    expect(find.text('Held'), findsWidgets);
  });

  testWidgets('"Held for review" keeps only held comments', (tester) async {
    await pumpStudio(tester, '/studio/comments');

    await tester.tap(find.byKey(const Key('studio_comments_held')));
    await tester.pumpAndSettle();

    final tiles = find.byType(StudioCommentTile);
    expect(tiles, findsWidgets);
    expect(find.text('Held'), findsNWidgets(tester.widgetList(tiles).length));
  });

  testWidgets('approving a held comment takes it off the review list', (
    tester,
  ) async {
    await pumpStudio(tester, '/studio/comments');
    await tester.tap(find.byKey(const Key('studio_comments_held')));
    await tester.pumpAndSettle();
    final first = _firstId(tester);

    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();

    expect(find.text('Comment approved'), findsOneWidget);
    expect(find.byKey(Key('studio_comment_$first')), findsNothing);
  });

  testWidgets('deleting asks first', (tester) async {
    await pumpStudio(tester, '/studio/comments');
    // The first row is held (it says Reject), so delete the first visible one.
    final tile = tester
        .widgetList<StudioCommentTile>(find.byType(StudioCommentTile))
        .firstWhere((t) => t.comment.status.name == 'visible');

    await tester.tap(find.descendant(
      of: find.byKey(Key('studio_comment_${tile.comment.id}')),
      matching: find.text('Delete'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Delete this comment?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('studio_comment_delete_confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('studio_comment_${tile.comment.id}')), findsNothing);
  });

  testWidgets('a reply is sent from the sheet', (tester) async {
    await pumpStudio(tester, '/studio/comments');

    await tester.tap(find.text('Reply').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('studio_reply_field')), 'Thanks!');
    await tester.pump();
    await tester.tap(find.byKey(const Key('studio_reply_send')));
    await tester.pumpAndSettle();

    expect(find.text('Reply posted'), findsOneWidget);
  });

  testWidgets('picking a video offers its sort chips', (tester) async {
    await pumpStudio(tester, '/studio/comments');
    expect(find.text('Most liked'), findsNothing);

    await tester.tap(find.byKey(const Key('studio_comments_video')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a video'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(StudioPostTile),
    ).first);
    await tester.pumpAndSettle();

    expect(find.text('Most liked'), findsOneWidget);
  });
}
