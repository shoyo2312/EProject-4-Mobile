import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_report_reasons.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_sheet.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_viewer_screen.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  /// Sheet backed by one existing comment and a resolvable author.
  Future<MockCommentRepository> pumpSheet(
    WidgetTester tester, {
    bool commentsDisabled = false,
    String? videoOwnerId,
    UserRole role = UserRole.user,
  }) async {
    final commentRepository = MockCommentRepository();
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(
        items: [
          CommentModel(
            id: 'c1',
            videoId: 'v1',
            userId: 'u1',
            text: 'first comment',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        hasMore: false,
        nextCursor: null,
      ),
    );
    final userRepository = MockUserRepository();
    when(() => userRepository.getProfiles(any()))
        .thenAnswer((_) async => <String, UserProfileModel>{});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(commentRepository),
          userRepositoryProvider.overrideWithValue(userRepository),
          storyRepositoryProvider.overrideWithValue(_FakeStories()),
          authStateProvider.overrideWith(() => _SignedInAuthState(role)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CommentSheet(
              videoId: 'v1',
              videoOwnerId: videoOwnerId,
              commentsDisabled: commentsDisabled,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return commentRepository;
  }

  testWidgets('a video with comments off still shows the thread, not the box',
      (tester) async {
    await pumpSheet(tester, commentsDisabled: true);

    expect(find.text('first comment'), findsOneWidget);
    expect(find.byKey(const Key('comments_disabled_notice')), findsOneWidget);
    expect(find.byKey(const Key('comment_input_field')), findsNothing);
  });

  testWidgets('a rejected post puts the text back and closes the box',
      (tester) async {
    final commentRepository = await pumpSheet(tester);
    // The owner switched comments off while the sheet was open — the server
    // saying so is the only way this sheet finds out.
    when(() => commentRepository.postComment('v1', 'hello')).thenThrow(
      const ServerException(403, 'Comments are turned off',
          code: 'COMMENTS_DISABLED'),
    );

    await tester.enterText(
        find.byKey(const Key('comment_input_field')), 'hello');
    await tester.tap(find.byKey(const Key('comment_send_button')));
    await tester.pump();

    expect(find.byKey(const Key('comments_disabled_notice')), findsOneWidget);
    expect(find.byKey(const Key('comment_input_field')), findsNothing);
  });

  testWidgets('a failed post does not swallow what was typed', (tester) async {
    final commentRepository = await pumpSheet(tester);
    when(() => commentRepository.postComment('v1', 'hello'))
        .thenThrow(const NetworkException());

    await tester.enterText(
        find.byKey(const Key('comment_input_field')), 'hello');
    await tester.tap(find.byKey(const Key('comment_send_button')));
    await tester.pump();

    final field = tester.widget<TextField>(
        find.byKey(const Key('comment_input_field')));
    expect(field.controller!.text, 'hello');
  });

  testWidgets('renders existing comments and posts a new one', (tester) async {
    final commentRepository = MockCommentRepository();
    final existing = CommentModel(
      id: 'c1',
      videoId: 'v1',
      userId: 'u1',
      text: 'first comment',
      createdAt: DateTime(2026, 1, 1),
    );
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [existing], hasMore: false, nextCursor: null),
    );
    final userRepository = MockUserRepository();
    when(() => userRepository.getProfiles(any())).thenAnswer(
      (_) async => {
        'u1': const UserProfileModel(
          userId: 'u1',
          displayName: 'jane',
          followerCount: 0,
          followingCount: 0,
        ),
      },
    );
    when(() => commentRepository.postComment('v1', 'new one')).thenAnswer(
      (_) async => CommentModel(
        id: 'c2',
        videoId: 'v1',
        userId: 'u2',
        text: 'new one',
        createdAt: DateTime(2026, 1, 2),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(commentRepository),
          userRepositoryProvider.overrideWithValue(userRepository),
          storyRepositoryProvider.overrideWithValue(_FakeStories()),
          // Signed-out viewers get a "log in to comment" prompt, not the input.
          authStateProvider.overrideWith(_SignedInAuthState.new),
        ],
        child: const MaterialApp(home: Scaffold(body: CommentSheet(videoId: 'v1'))),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('first comment'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('comment_input_field')), 'new one');
    await tester.tap(find.byKey(const Key('comment_send_button')));
    await tester.pump();

    verify(() => commentRepository.postComment('v1', 'new one')).called(1);
  });

  group('who may delete or report someone else\'s comment', () {
    // The one comment in pumpSheet belongs to 'u1'; the viewer is '1'.

    testWidgets('a viewer can report it but not delete it', (tester) async {
      await pumpSheet(tester, videoOwnerId: 'someone-else');

      expect(find.byKey(const Key('comment_delete_c1')), findsNothing);
      expect(find.byKey(const Key('comment_report_c1')), findsOneWidget);
    });

    testWidgets('the video owner deletes it after confirming', (tester) async {
      final repository = await pumpSheet(tester, videoOwnerId: '1');
      when(() => repository.deleteComment('v1', 'c1')).thenAnswer((_) async {});

      await tester.tap(find.byKey(const Key('comment_delete_c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_confirm_delete')));
      await tester.pumpAndSettle();

      verify(() => repository.deleteComment('v1', 'c1')).called(1);
      expect(find.text('first comment'), findsNothing);
    });

    testWidgets('only the owner sees the filters button', (tester) async {
      await pumpSheet(tester, videoOwnerId: '1');
      expect(find.byKey(const Key('comment_filters_button')), findsOneWidget);
    });

    testWidgets('an admin removes it with a reason, through admin-service',
        (tester) async {
      final repository = await pumpSheet(
        tester,
        videoOwnerId: 'someone-else',
        role: UserRole.admin,
      );
      when(() => repository.removeCommentAsAdmin('v1', 'c1', any()))
          .thenAnswer((_) async {});

      await tester.tap(find.byKey(const Key('comment_delete_c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_remove_reason_1')));
      await tester.pumpAndSettle();

      verify(() => repository.removeCommentAsAdmin(
          'v1', 'c1', commentReportReasons[1])).called(1);
      verifyNever(() => repository.deleteComment(any(), any()));
      expect(find.text('first comment'), findsNothing);
    });

    testWidgets('a report sends the picked reason and keeps the comment',
        (tester) async {
      final repository = await pumpSheet(tester, videoOwnerId: 'someone-else');
      when(() => repository.reportComment('v1', 'c1', any()))
          .thenAnswer((_) async {});

      await tester.tap(find.byKey(const Key('comment_report_c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_report_reason_5')));
      await tester.pumpAndSettle();

      verify(() => repository.reportComment(
          'v1', 'c1', commentReportReasons[5])).called(1);
      expect(find.byKey(const Key('comment_report_sent')), findsOneWidget);
      expect(find.text('first comment'), findsOneWidget);
    });
  });

  testWidgets('a held comment is not shown in the thread, and the author is told',
      (tester) async {
    final repository = await pumpSheet(tester);
    when(() => repository.postComment('v1', 'held one')).thenAnswer(
      (_) async => CommentModel(
        id: 'c9',
        videoId: 'v1',
        userId: '1',
        text: 'held one',
        createdAt: DateTime(2026, 1, 2),
        status: CommentStatus.held,
      ),
    );

    await tester.enterText(
        find.byKey(const Key('comment_input_field')), 'held one');
    await tester.tap(find.byKey(const Key('comment_send_button')));
    await tester.pump();

    expect(find.byKey(const Key('comment_held_notice')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('held one'),
      ),
      findsNothing,
    );
  });

  group('own comments, replies and stickers', () {
    // The viewer is '1'. 'mine' is theirs, 'theirs' belongs to 'u1' and has
    // one reply.
    final mine = CommentModel(
      id: 'mine',
      videoId: 'v1',
      userId: '1',
      text: 'my words',
      createdAt: DateTime(2026, 1, 1),
    );
    final theirs = CommentModel(
      id: 'theirs',
      videoId: 'v1',
      userId: 'u1',
      text: 'their words',
      replyCount: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    Future<MockCommentRepository> pumpThread(WidgetTester tester) async {
      final repository = MockCommentRepository();
      when(() => repository.fetchComments('v1', cursor: null)).thenAnswer(
        (_) async => CommentPage(
            items: [mine, theirs], hasMore: false, nextCursor: null),
      );
      final users = MockUserRepository();
      when(() => users.getProfiles(any())).thenAnswer((_) async => {
            'u1': const UserProfileModel(
              userId: 'u1',
              displayName: 'jane',
              followerCount: 0,
              followingCount: 0,
            ),
            'u2': const UserProfileModel(
              userId: 'u2',
              displayName: 'bob',
              followerCount: 0,
              followingCount: 0,
            ),
          });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commentRepositoryProvider.overrideWithValue(repository),
            userRepositoryProvider.overrideWithValue(users),
            storyRepositoryProvider.overrideWithValue(_FakeStories()),
            authStateProvider.overrideWith(() => _SignedInAuthState()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CommentSheet(videoId: 'v1', videoOwnerId: 'someone-else'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return repository;
    }

    testWidgets('only my comment offers Edit, and never Report',
        (tester) async {
      await pumpThread(tester);

      expect(find.byKey(const Key('comment_edit_mine')), findsOneWidget);
      expect(find.byKey(const Key('comment_delete_mine')), findsOneWidget);
      expect(find.byKey(const Key('comment_report_mine')), findsNothing);
      expect(find.byKey(const Key('comment_edit_theirs')), findsNothing);
      expect(find.byKey(const Key('comment_report_theirs')), findsOneWidget);
    });

    testWidgets('an edit is saved in place and marked edited', (tester) async {
      final repository = await pumpThread(tester);
      when(() => repository.editComment('v1', 'mine', 'better words'))
          .thenAnswer((_) async => mine.copyWith(
              text: 'better words', editedAt: DateTime(2026, 1, 2)));

      await tester.tap(find.byKey(const Key('comment_edit_mine')));
      await tester.pump();
      expect(find.text('Editing comment'), findsOneWidget);
      final field =
          tester.widget<TextField>(find.byKey(const Key('comment_input_field')));
      expect(field.controller!.text, 'my words');

      await tester.enterText(
          find.byKey(const Key('comment_input_field')), 'better words');
      await tester.tap(find.byKey(const Key('comment_send_button')));
      await tester.pump();

      expect(find.text('better words'), findsOneWidget);
      expect(find.byKey(const Key('comment_edited_mine')), findsOneWidget);
      expect(find.text('Editing comment'), findsNothing);
    });

    testWidgets('an edit that needs review says so and keeps the text',
        (tester) async {
      final repository = await pumpThread(tester);
      when(() => repository.editComment('v1', 'mine', 'spammy'))
          .thenThrow(const ServerException(422, 'needs review',
              code: 'COMMENT_EDIT_NEEDS_REVIEW'));

      await tester.tap(find.byKey(const Key('comment_edit_mine')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('comment_input_field')), 'spammy');
      await tester.tap(find.byKey(const Key('comment_send_button')));
      await tester.pump();

      expect(find.text("This edit needs review and wasn't saved"),
          findsOneWidget);
      expect(find.text('my words'), findsOneWidget);
      final field =
          tester.widget<TextField>(find.byKey(const Key('comment_input_field')));
      expect(field.controller!.text, 'spammy');
    });

    testWidgets('Reply sends the comment as parentId, text untouched',
        (tester) async {
      final repository = await pumpThread(tester);
      when(() => repository.postComment('v1', 'agreed', parentId: 'theirs'))
          .thenAnswer((_) async => CommentModel(
                id: 'r9',
                videoId: 'v1',
                userId: '1',
                text: 'agreed',
                parentId: 'theirs',
                createdAt: DateTime(2026, 1, 3),
              ));

      await tester.tap(find.byKey(const Key('comment_reply_theirs')));
      await tester.pump();
      expect(find.text('Replying to jane'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('comment_input_field')), 'agreed');
      await tester.tap(find.byKey(const Key('comment_send_button')));
      await tester.pump();

      verify(() => repository.postComment('v1', 'agreed', parentId: 'theirs'))
          .called(1);
      // Shown under its thread straight away.
      expect(find.text('agreed'), findsOneWidget);
    });

    testWidgets('View replies opens the thread, with "A > B" on a nested one',
        (tester) async {
      final repository = await pumpThread(tester);
      when(() => repository.fetchReplies('v1', 'theirs', cursor: null))
          .thenAnswer((_) async => CommentPage(
                items: [
                  CommentModel(
                    id: 'r1',
                    videoId: 'v1',
                    userId: 'u2',
                    text: 'a reply',
                    parentId: 'theirs',
                    replyToUserId: 'u1',
                    createdAt: DateTime(2026, 1, 2),
                  ),
                ],
                hasMore: false,
                nextCursor: null,
              ));

      expect(find.text('View 1 reply'), findsOneWidget);
      await tester.tap(find.byKey(const Key('comment_view_replies_theirs')));
      await tester.pump();
      await tester.pump();

      expect(find.text('a reply'), findsOneWidget);
      expect(find.byKey(const Key('comment_author_name_r1')), findsOneWidget);
      expect(find.text('bob'), findsOneWidget);
      expect(find.byKey(const Key('comment_reply_to_name_r1')), findsOneWidget);
      expect(find.byKey(const Key('comment_hide_replies_theirs')),
          findsOneWidget);
    });

    testWidgets('a sticker comment shows its sticker', (tester) async {
      final repository = MockCommentRepository();
      when(() => repository.fetchComments('v1', cursor: null)).thenAnswer(
        (_) async => CommentPage(items: [
          CommentModel(
            id: 's1',
            videoId: 'v1',
            userId: 'u1',
            text: '',
            sticker: const CommentSticker(
                stickerId: 'cat', url: 'http://x/cat.png', width: 10, height: 10),
            createdAt: DateTime(2026, 1, 1),
          ),
        ], hasMore: false, nextCursor: null),
      );
      final users = MockUserRepository();
      when(() => users.getProfiles(any()))
          .thenAnswer((_) async => <String, UserProfileModel>{});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commentRepositoryProvider.overrideWithValue(repository),
            userRepositoryProvider.overrideWithValue(users),
            storyRepositoryProvider.overrideWithValue(_FakeStories()),
            authStateProvider.overrideWith(() => _SignedInAuthState()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CommentSheet(videoId: 'v1')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('comment_sticker_view_s1')), findsOneWidget);
    });
  });
  group('commenter avatar and name', () {
    /// u1 wrote c1; u2 wrote c2. Only [withRing] have a live story. The
    /// story viewer and profile are stand-ins that name what was opened.
    Future<_FakeStories> pumpRouted(
      WidgetTester tester, {
      Set<String> withRing = const {},
    }) async {
      final repository = MockCommentRepository();
      when(() => repository.fetchComments('v1', cursor: null)).thenAnswer(
        (_) async => CommentPage(
          items: [
            for (final (id, user) in [('c1', 'u1'), ('c2', 'u2')])
              CommentModel(
                id: id,
                videoId: 'v1',
                userId: user,
                text: 'from $user',
                createdAt: DateTime(2026, 1, 1),
              ),
          ],
          hasMore: false,
          nextCursor: null,
        ),
      );
      final users = MockUserRepository();
      when(() => users.getProfiles(any())).thenAnswer((_) async => {
            'u1': const UserProfileModel(
              userId: 'u1',
              displayName: 'amy',
              followerCount: 0,
              followingCount: 0,
            ),
            'u2': const UserProfileModel(
              userId: 'u2',
              displayName: 'bob',
              followerCount: 0,
              followingCount: 0,
            ),
          });
      final stories = _FakeStories(withRing: withRing);
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: CommentSheet(videoId: 'v1')),
        ),
        GoRoute(
          path: '/profile/:userId',
          builder: (_, state) =>
              Text('profile ${state.pathParameters['userId']}'),
        ),
        GoRoute(
          path: '/stories/view',
          builder: (_, state) => Text(
            'stories of ${(state.extra! as StoryViewerArgs).groups.single.userId}',
          ),
        ),
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commentRepositoryProvider.overrideWithValue(repository),
            userRepositoryProvider.overrideWithValue(users),
            storyRepositoryProvider.overrideWithValue(stories),
            authStateProvider.overrideWith(() => _SignedInAuthState()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      return stories;
    }

    testWidgets('rings for the whole page are read in one call',
        (tester) async {
      final stories = await pumpRouted(tester, withRing: {'u1'});

      expect(stories.asked, [
        ['u1', 'u2'],
      ]);
      expect(find.byKey(const Key('comment_story_ring_u1')), findsOneWidget);
      expect(find.byKey(const Key('comment_story_ring_u2')), findsNothing);
    });

    testWidgets('a tap on a ringed avatar plays the story', (tester) async {
      await pumpRouted(tester, withRing: {'u1'});

      await tester.tap(find.byKey(const Key('comment_avatar_c1')));
      await tester.pumpAndSettle();

      expect(find.text('stories of u1'), findsOneWidget);
    });

    testWidgets('a long press offers story or profile', (tester) async {
      await pumpRouted(tester, withRing: {'u1'});

      await tester.longPress(find.byKey(const Key('comment_avatar_c1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('comment_avatar_view_story')), findsOneWidget);

      await tester.tap(find.byKey(const Key('comment_avatar_view_profile')));
      await tester.pumpAndSettle();

      expect(find.text('profile u1'), findsOneWidget);
    });

    testWidgets('the long-press menu can play the story too', (tester) async {
      await pumpRouted(tester, withRing: {'u1'});

      await tester.longPress(find.byKey(const Key('comment_avatar_c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_avatar_view_story')));
      await tester.pumpAndSettle();

      expect(find.text('stories of u1'), findsOneWidget);
    });

    testWidgets('an avatar without a story opens the profile', (tester) async {
      await pumpRouted(tester, withRing: {'u1'});

      await tester.tap(find.byKey(const Key('comment_avatar_c2')));
      await tester.pumpAndSettle();

      expect(find.text('profile u2'), findsOneWidget);
    });

    testWidgets('a long press without a story skips the menu',
        (tester) async {
      await pumpRouted(tester, withRing: {'u1'});

      await tester.longPress(find.byKey(const Key('comment_avatar_c2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('comment_avatar_view_story')), findsNothing);
      expect(find.text('profile u2'), findsOneWidget);
    });

    testWidgets('a tap on the name opens the profile, ring or not',
        (tester) async {
      await pumpRouted(tester, withRing: {'u1'});

      await tester.tap(find.byKey(const Key('comment_author_name_c1')));
      await tester.pumpAndSettle();

      expect(find.text('profile u1'), findsOneWidget);
    });
  });
}

class _SignedInAuthState extends AuthState {
  _SignedInAuthState([this.role = UserRole.user]);

  final UserRole role;

  @override
  FutureOr<UserModel?> build() => UserModel(
        id: '1',
        username: 'jane',
          email: 'jane@test.com',
        role: role,
        status: UserStatus.active,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );
}

/// Story rings for [withRing]; everyone else has none.
class _FakeStories extends Fake implements StoryRepository {
  _FakeStories({this.withRing = const {}});

  final Set<String> withRing;
  final asked = <List<String>>[];

  @override
  Future<List<StoryRing>> rings(List<String> userIds) async {
    asked.add(userIds);
    return [
      for (final id in userIds)
        if (withRing.contains(id)) StoryRing(userId: id, hasUnseen: true),
    ];
  }

  @override
  Future<List<StoryModel>> userStories(String userId) async => [
        StoryModel(
          id: 's-$userId',
          userId: userId,
          mediaUrl: 'https://cdn.test/s.jpg',
          mediaType: StoryMediaType.image,
          visibility: StoryVisibility.public,
          createdAt: DateTime(2026, 11, 1),
          expiresAt: DateTime(2026, 11, 2),
        ),
      ];
}
