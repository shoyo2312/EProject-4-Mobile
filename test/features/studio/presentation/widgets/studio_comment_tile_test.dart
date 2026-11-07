import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/studio/presentation/widgets/studio_comment_tile.dart';

Future<void> _pump(WidgetTester tester, StudioCommentTile tile) =>
    tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: Scaffold(body: tile)),
    ));

CommentModel _comment({CommentStatus status = CommentStatus.visible}) =>
    CommentModel(
      id: '1',
      videoId: '2',
      userId: '3',
      text: 'Love this',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likeCount: 4,
      status: status,
    );

void main() {
  testWidgets('a visible comment offers like, reply and delete', (tester) async {
    var liked = false;
    await _pump(
      tester,
      StudioCommentTile(
        comment: _comment(),
        onLike: () => liked = true,
        onReply: () {},
        onApprove: () {},
        onDelete: () {},
      ),
    );

    expect(find.text('Love this'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('4'));
    expect(liked, isTrue);
  });

  testWidgets('a held comment offers approve and reject only', (tester) async {
    await _pump(
      tester,
      StudioCommentTile(
        comment: _comment(status: CommentStatus.held),
        onLike: () {},
        onReply: () {},
        onApprove: () {},
        onDelete: () {},
      ),
    );

    expect(find.text('Held'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Reply'), findsNothing);
  });

  testWidgets('without actions it is a plain preview row', (tester) async {
    await _pump(tester, StudioCommentTile(comment: _comment()));

    expect(find.text('Nowa user'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });
}
