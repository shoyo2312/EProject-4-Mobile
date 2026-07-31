import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  late MockCommentRepository commentRepository;
  late ProviderContainer container;

  CommentModel makeComment(String id) => CommentModel(
        id: id,
        videoId: 'v1',
        userId: 'u1',
        username: 'jane',
        text: 'comment $id',
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    commentRepository = MockCommentRepository();
    container = ProviderContainer(
      overrides: [commentRepositoryProvider.overrideWithValue(commentRepository)],
    );
  });

  tearDown(() => container.dispose());

  test('build(videoId) loads the first page for that video', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [makeComment('c1')], nextCursor: null),
    );

    final result = await container.read(commentNotifierProvider('v1').future);

    expect(result.map((c) => c.id), ['c1']);
  });

  test('postComment() appends the new comment to the front', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [makeComment('c1')], nextCursor: null),
    );
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.postComment('v1', 'new comment'))
        .thenAnswer((_) async => makeComment('c2'));

    await container.read(commentNotifierProvider('v1').notifier).postComment('new comment');

    final result = container.read(commentNotifierProvider('v1')).value!;
    expect(result.map((c) => c.id), ['c2', 'c1']);
  });
}
