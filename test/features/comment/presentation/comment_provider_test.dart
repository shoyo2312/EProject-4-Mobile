import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
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
        // Rings are the comment sheet's business; nothing to read here.
        storyRingsProvider.overrideWith(_NoRings.new),
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

  test('postComment() leaves a held comment out of the thread', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [makeComment('c1')], hasMore: false, nextCursor: null),
    );
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.postComment('v1', 'held')).thenAnswer(
      (_) async => makeComment('c2').copyWith(status: CommentStatus.held),
    );

    final created = await container
        .read(commentNotifierProvider('v1').notifier)
        .postComment('held');

    expect(created.status, CommentStatus.held);
    final result = container.read(commentNotifierProvider('v1')).value!;
    expect(result.map((c) => c.id), ['c1']);
  });

  test('removeAsAdmin() drops the comment once admin-service accepts', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(
        items: [makeComment('c1'), makeComment('c2')],
        hasMore: false,
        nextCursor: null,
      ),
    );
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.removeCommentAsAdmin('v1', 'c1', 'spam'))
        .thenAnswer((_) async {});

    await container
        .read(commentNotifierProvider('v1').notifier)
        .removeAsAdmin('c1', 'spam');

    final result = container.read(commentNotifierProvider('v1')).value!;
    expect(result.map((c) => c.id), ['c2']);
  });

  test('a refused admin removal keeps the comment', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [makeComment('c1')], hasMore: false, nextCursor: null),
    );
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.removeCommentAsAdmin('v1', 'c1', 'spam'))
        .thenThrow(const ServerException(403, 'Forbidden'));

    await expectLater(
      container
          .read(commentNotifierProvider('v1').notifier)
          .removeAsAdmin('c1', 'spam'),
      throwsA(isA<ServerException>()),
    );

    final result = container.read(commentNotifierProvider('v1')).value!;
    expect(result.map((c) => c.id), ['c1']);
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

  test('the server tally replaces the optimistic guess', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(
          items: [makeComment('c1')], hasMore: false, nextCursor: null),
    );
    // Two other people liked it between the render and the tap.
    when(() => commentRepository.likeComment('v1', 'c1'))
        .thenAnswer((_) async => const CommentLikeResult(liked: true, likeCount: 3));
    await container.read(commentNotifierProvider('v1').future);

    await container.read(commentNotifierProvider('v1').notifier).toggleLike('c1');

    final result = container.read(commentNotifierProvider('v1')).value!.single;
    expect(result.likedByMe, isTrue);
    expect(result.likeCount, 3);
  });

  test('a failed comment like empties the heart again', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(
          items: [makeComment('c1')], hasMore: false, nextCursor: null),
    );
    when(() => commentRepository.likeComment('v1', 'c1'))
        .thenThrow(const NetworkException());
    await container.read(commentNotifierProvider('v1').future);

    await container.read(commentNotifierProvider('v1').notifier).toggleLike('c1');

    final result = container.read(commentNotifierProvider('v1')).value!.single;
    expect(result.likedByMe, isFalse);
    expect(result.likeCount, 0);
  });

  group('replies', () {
    CommentModel reply(String id, {String parent = 'c1'}) => CommentModel(
          id: id,
          videoId: 'v1',
          userId: 'u2',
          text: 'reply $id',
          parentId: parent,
          createdAt: DateTime(2026, 1, 2),
        );

    /// A thread c1 with [replyCount] replies; both notifiers kept alive the
    /// way the open sheet keeps them.
    Future<void> loadThread({int replyCount = 2}) async {
      when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
        (_) async => CommentPage(
          items: [makeComment('c1').copyWith(replyCount: replyCount)],
          hasMore: false,
          nextCursor: null,
        ),
      );
      container.listen(commentRepliesProvider('v1'), (_, _) {});
      container.listen(commentNotifierProvider('v1'), (_, _) {});
      await container.read(commentNotifierProvider('v1').future);
    }

    Map<String, ReplyThread> threads() =>
        container.read(commentRepliesProvider('v1'));
    CommentModel top() =>
        container.read(commentNotifierProvider('v1')).value!.single;

    test('open() reads the first page, loadMore() the next', () async {
      await loadThread();
      when(() => commentRepository.fetchReplies('v1', 'c1', cursor: null))
          .thenAnswer((_) async => CommentPage(
              items: [reply('r1')], hasMore: true, nextCursor: 'k'));
      when(() => commentRepository.fetchReplies('v1', 'c1', cursor: 'k'))
          .thenAnswer((_) async => CommentPage(
              items: [reply('r2')], hasMore: false, nextCursor: null));

      final replies = container.read(commentRepliesProvider('v1').notifier);
      await replies.open('c1');
      expect(threads()['c1']!.items.map((c) => c.id), ['r1']);
      expect(threads()['c1']!.hasMore, isTrue);

      await replies.loadMore('c1');
      expect(threads()['c1']!.items.map((c) => c.id), ['r1', 'r2']);
      expect(threads()['c1']!.hasMore, isFalse);
    });

    test('a posted reply joins its thread and counts on the parent', () async {
      await loadThread(replyCount: 0);
      when(() => commentRepository.postComment('v1', 'hey', parentId: 'c1'))
          .thenAnswer((_) async => reply('r9'));

      await container
          .read(commentNotifierProvider('v1').notifier)
          .postComment('hey', parentId: 'c1');

      expect(top().replyCount, 1);
      expect(threads()['c1']!.items.map((c) => c.id), ['r9']);
      // Nothing earlier to read: no "more" offered.
      expect(threads()['c1']!.hasMore, isFalse);
    });

    test('a reply posted here is not doubled when its page arrives', () async {
      await loadThread(replyCount: 1);
      when(() => commentRepository.postComment('v1', 'hey', parentId: 'c1'))
          .thenAnswer((_) async => reply('r9'));
      when(() => commentRepository.fetchReplies('v1', 'c1', cursor: null))
          .thenAnswer((_) async => CommentPage(
              items: [reply('r1'), reply('r9')], hasMore: false, nextCursor: null));

      await container
          .read(commentNotifierProvider('v1').notifier)
          .postComment('hey', parentId: 'c1');
      expect(threads()['c1']!.hasMore, isTrue);
      await container.read(commentRepliesProvider('v1').notifier).loadMore('c1');

      expect(threads()['c1']!.items.map((c) => c.id), ['r1', 'r9']);
    });

    test('a held reply goes nowhere and counts nothing', () async {
      await loadThread(replyCount: 0);
      when(() => commentRepository.postComment('v1', 'hey', parentId: 'c1'))
          .thenAnswer(
              (_) async => reply('r9').copyWith(status: CommentStatus.held));

      await container
          .read(commentNotifierProvider('v1').notifier)
          .postComment('hey', parentId: 'c1');

      expect(top().replyCount, 0);
      expect(threads(), isEmpty);
    });

    test('deleting a reply takes it off its thread and the count', () async {
      await loadThread(replyCount: 1);
      when(() => commentRepository.fetchReplies('v1', 'c1', cursor: null))
          .thenAnswer((_) async => CommentPage(
              items: [reply('r1')], hasMore: false, nextCursor: null));
      when(() => commentRepository.deleteComment('v1', 'r1'))
          .thenAnswer((_) async {});
      await container.read(commentRepliesProvider('v1').notifier).open('c1');

      await container
          .read(commentNotifierProvider('v1').notifier)
          .deleteComment('r1');

      expect(threads()['c1']!.items, isEmpty);
      expect(top().replyCount, 0);
    });

    test('deleting a top-level comment closes its thread', () async {
      await loadThread(replyCount: 1);
      when(() => commentRepository.fetchReplies('v1', 'c1', cursor: null))
          .thenAnswer((_) async => CommentPage(
              items: [reply('r1')], hasMore: false, nextCursor: null));
      when(() => commentRepository.deleteComment('v1', 'c1'))
          .thenAnswer((_) async {});
      await container.read(commentRepliesProvider('v1').notifier).open('c1');

      await container
          .read(commentNotifierProvider('v1').notifier)
          .deleteComment('c1');

      expect(threads(), isEmpty);
      expect(container.read(commentNotifierProvider('v1')).value, isEmpty);
    });

    test('an edited reply is replaced in its thread', () async {
      await loadThread(replyCount: 1);
      when(() => commentRepository.fetchReplies('v1', 'c1', cursor: null))
          .thenAnswer((_) async => CommentPage(
              items: [reply('r1')], hasMore: false, nextCursor: null));
      when(() => commentRepository.editComment('v1', 'r1', 'better'))
          .thenAnswer((_) async => reply('r1')
              .copyWith(text: 'better', editedAt: DateTime(2026, 1, 3)));
      await container.read(commentRepliesProvider('v1').notifier).open('c1');

      await container
          .read(commentNotifierProvider('v1').notifier)
          .editComment('r1', 'better');

      final edited = threads()['c1']!.items.single;
      expect(edited.text, 'better');
      expect(edited.editedAt, isNotNull);
    });
  });

  test('an edit replaces the top-level row in place', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(
          items: [makeComment('c1'), makeComment('c2')],
          hasMore: false,
          nextCursor: null),
    );
    container.listen(commentRepliesProvider('v1'), (_, _) {});
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.editComment('v1', 'c2', 'new'))
        .thenAnswer((_) async => makeComment('c2').copyWith(text: 'new'));

    await container
        .read(commentNotifierProvider('v1').notifier)
        .editComment('c2', 'new');

    final result = container.read(commentNotifierProvider('v1')).value!;
    expect(result.map((c) => c.text), ['comment c1', 'new']);
  });

  test('a sticker comment goes up with its stickerId', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [], hasMore: false, nextCursor: null),
    );
    container.listen(commentRepliesProvider('v1'), (_, _) {});
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.postComment('v1', '', stickerId: 'cat'))
        .thenAnswer((_) async => makeComment('c9').copyWith(
            text: '',
            sticker: const CommentSticker(stickerId: 'cat', url: 'http://x')));

    await container
        .read(commentNotifierProvider('v1').notifier)
        .postComment('', stickerId: 'cat');

    final result = container.read(commentNotifierProvider('v1')).value!;
    expect(result.single.sticker?.stickerId, 'cat');
  });
}

class _NoRings extends StoryRings {
  @override
  Map<String, StoryRing?> build() => const {};

  @override
  Future<void> loadMissing(Iterable<String> userIds) async {}
}
