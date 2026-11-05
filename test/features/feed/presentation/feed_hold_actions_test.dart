import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_model.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_repository.dart';
import 'package:tiktok_mobile/features/interaction/presentation/interaction_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockInteractionRepository extends Mock implements InteractionRepository {}

class MockCommentRepository extends Mock implements CommentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class _SignedInAuthState extends AuthState {
  @override
  FutureOr<UserModel?> build() => UserModel(
        id: '1',
        username: 'jane',
        email: 'jane@test.com',
        role: UserRole.user,
        status: UserStatus.active,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );
}

void main() {
  late MockInteractionRepository interactions;
  late MockCommentRepository comments;

  /// One panel, on screen, for a signed-in viewer. No hlsUrl, so no player:
  /// the placeholder frame stands in and nothing keeps animating.
  Future<void> pumpPanel(
    WidgetTester tester, {
    bool commentsDisabled = false,
  }) async {
    interactions = MockInteractionRepository();
    when(() => interactions.getCounts('v1')).thenAnswer(
      (_) async => const InteractionCounts(
        videoId: 'v1',
        likeCount: 5,
        commentCount: 0,
        shareCount: 0,
        viewCount: 0,
      ),
    );
    when(() => interactions.getLikeStatus('v1')).thenAnswer(
      (_) async => const LikeStatus(videoId: 'v1', liked: false, likeCount: 5),
    );
    when(() => interactions.like('v1')).thenAnswer(
      (_) async => const LikeStatus(videoId: 'v1', liked: true, likeCount: 6),
    );
    when(() => interactions.getSaveStatus('v1')).thenAnswer(
      (_) async => const SaveStatus(videoId: 'v1', saved: false),
    );
    when(() => interactions.recordView('v1', playId: any(named: 'playId')))
        .thenAnswer((_) async {});
    when(() => interactions.repost('v1')).thenAnswer((_) async => true);
    when(() => interactions.unrepost('v1')).thenAnswer((_) async => false);

    comments = MockCommentRepository();
    final users = MockUserRepository();
    when(() => users.getProfiles(any())).thenAnswer((_) async => const {
          '123': UserProfileModel(
            userId: '123',
            displayName: 'amy',
            followerCount: 0,
            followingCount: 0,
          ),
        });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_SignedInAuthState.new),
          interactionRepositoryProvider.overrideWithValue(interactions),
          commentRepositoryProvider.overrideWithValue(comments),
          userRepositoryProvider.overrideWithValue(users),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: FeedVideoPanel(
              isActive: true,
              video: VideoModel(
                id: 'v1',
                userId: '123',
                title: 'clip',
                status: VideoStatus.published,
                visibility: VideoVisibility.public,
                commentsDisabled: commentsDisabled,
                viewCount: 0,
                likeCount: 5,
                commentCount: 0,
                createdAt: DateTime(2026, 11, 1),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Finder heart() => find.byKey(const Key('feed_like_count_v1'));
  Finder commentButton() => find.byKey(const Key('feed_comment_count_v1'));

  group('holding the heart', () {
    testWidgets('for 1.5s reposts, with a ring filling meanwhile',
        (tester) async {
      await pumpPanel(tester);

      final press = await tester.startGesture(tester.getCenter(heart()));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('rail_hold_progress')), findsOneWidget);
      verifyNever(() => interactions.repost(any()));

      await tester.pump(const Duration(milliseconds: 800));
      await press.up();
      await tester.pump();
      await tester.pump();

      verify(() => interactions.repost('v1')).called(1);
      verifyNever(() => interactions.like(any()));
      expect(find.text('Reposted to your profile'), findsOneWidget);
      expect(find.byKey(const Key('rail_hold_progress')), findsNothing);
    });

    testWidgets('and letting go early reposts nothing', (tester) async {
      await pumpPanel(tester);

      final press = await tester.startGesture(tester.getCenter(heart()));
      await tester.pump(const Duration(milliseconds: 900));
      await press.up();
      await tester.pump(const Duration(milliseconds: 400));

      verifyNever(() => interactions.repost(any()));
      expect(find.byKey(const Key('rail_hold_progress')), findsNothing);
    });

    testWidgets('a quick tap still likes', (tester) async {
      await pumpPanel(tester);

      await tester.tap(heart());
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => interactions.like('v1')).called(1);
      verifyNever(() => interactions.repost(any()));
    });

    testWidgets('Undo takes the repost back', (tester) async {
      await pumpPanel(tester);

      await tester.timedDrag(heart(), Offset.zero, const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const Key('feed_repost_undo')));
      await tester.pump();

      verify(() => interactions.unrepost('v1')).called(1);
    });
  });

  group('holding the comment button', () {
    testWidgets('offers emojis, and the one picked is posted as a comment',
        (tester) async {
      await pumpPanel(tester);
      when(() => comments.postComment('v1', '🔥')).thenAnswer(
        (_) async => CommentModel(
          id: 'c1',
          videoId: 'v1',
          userId: '1',
          text: '🔥',
          createdAt: DateTime(2026, 11, 5),
        ),
      );

      await tester.longPress(commentButton());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quick_comment_picker')), findsOneWidget);

      await tester.tap(find.byKey(const Key('quick_comment_🔥')));
      await tester.pumpAndSettle();

      verify(() => comments.postComment('v1', '🔥')).called(1);
      expect(find.byKey(const Key('quick_comment_picker')), findsNothing);
      expect(find.text('Commented 🔥'), findsOneWidget);
    });

    testWidgets('dismissed, posts nothing', (tester) async {
      await pumpPanel(tester);

      await tester.longPress(commentButton());
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_comment_picker')), findsNothing);
      verifyNever(() => comments.postComment(any(), any()));
    });

    testWidgets('a held comment says it is being reviewed', (tester) async {
      await pumpPanel(tester);
      when(() => comments.postComment('v1', '😂')).thenAnswer(
        (_) async => CommentModel(
          id: 'c1',
          videoId: 'v1',
          userId: '1',
          text: '😂',
          createdAt: DateTime(2026, 11, 5),
          status: CommentStatus.held,
        ),
      );

      await tester.longPress(commentButton());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick_comment_😂')));
      await tester.pumpAndSettle();

      expect(
        find.text('Your comment is being reviewed before it appears'),
        findsOneWidget,
      );
    });

    testWidgets('on a video with comments off, explains instead',
        (tester) async {
      await pumpPanel(tester, commentsDisabled: true);

      await tester.longPress(commentButton());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_comment_picker')), findsNothing);
      expect(find.text('Comments are turned off for this video'),
          findsOneWidget);
    });
  });
}
