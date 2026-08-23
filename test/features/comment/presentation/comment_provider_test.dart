import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockCommentRepository commentRepository;
  late ProviderContainer container;

  CommentModel makeComment(String id) => CommentModel(
        id: id,
        videoId: 'v1',
        userId: 'u1',
        text: 'comment $id',
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    commentRepository = MockCommentRepository();
    // The notifier resolves comment authors through the profile cache; without
    // this it would reach for a real ApiClient.
    final userRepository = MockUserRepository();
    when(() => userRepository.getProfiles(any()))
        .thenAnswer((_) async => <String, UserProfileModel>{});
    container = ProviderContainer(
      overrides: [
        commentRepositoryProvider.overrideWithValue(commentRepository),
        userRepositoryProvider.overrideWithValue(userRepository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('build(videoId) loads the first page for that video', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [makeComment('c1')], hasMore: false, nextCursor: null),
    );

    final result = await container.read(commentNotifierProvider('v1').future);

    expect(result.map((c) => c.id), ['c1']);
  });

  test('postComment() appends the new comment to the front', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [makeComment('c1')], hasMore: false, nextCursor: null),
    );
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.postComment('v1', 'new comment'))
        .thenAnswer((_) async => makeComment('c2'));

    await container.read(commentNotifierProvider('v1').notifier).postComment('new comment');

    final result = container.read(commentNotifierProvider('v1')).value!;
    expect(result.map((c) => c.id), ['c2', 'c1']);
  });

  test('loadMore keeps going through a page emptied by deleted comments',
      () async {
    // A page can come back empty while hasMore is still true: deleted rows are
    // filtered after Cassandra cut the page (interaction doc 3.5). Stopping
    // there would end the list early.
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(
        items: [makeComment('c1')],
        hasMore: true,
        nextCursor: 'cur1',
      ),
    );
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.fetchComments('v1', cursor: 'cur1')).thenAnswer(
      (_) async => const CommentPage(items: [], hasMore: true, nextCursor: 'cur2'),
    );
    when(() => commentRepository.fetchComments('v1', cursor: 'cur2')).thenAnswer(
      (_) async => CommentPage(
        items: [makeComment('c2')],
        hasMore: false,
        nextCursor: null,
      ),
    );

    await container.read(commentNotifierProvider('v1').notifier).loadMore();

    expect(
      container.read(commentNotifierProvider('v1')).value!.map((c) => c.id),
      ['c1', 'c2'],
    );
  });

  test('deleteComment drops the row it removed', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(
        items: [makeComment('c1'), makeComment('c2')],
        hasMore: false,
        nextCursor: null,
      ),
    );
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.deleteComment('v1', 'c1'))
        .thenAnswer((_) async {});

    await container.read(commentNotifierProvider('v1').notifier).deleteComment('c1');

    expect(
      container.read(commentNotifierProvider('v1')).value!.map((c) => c.id),
      ['c2'],
    );
  });
}
