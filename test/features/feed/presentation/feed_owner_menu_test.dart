import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_model.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_repository.dart';
import 'package:tiktok_mobile/features/interaction/presentation/interaction_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockInteractionRepository extends Mock implements InteractionRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

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
  setUpAll(() => registerFallbackValue(VideoVisibility.public));

  late MockFeedRepository feed;

  VideoModel clip(String ownerId, {String? hlsUrl}) => VideoModel(
    id: 'v1',
    userId: ownerId,
    hlsUrl: hlsUrl,
    title: 'clip',
    status: VideoStatus.published,
    visibility: VideoVisibility.public,
    viewCount: 0,
    likeCount: 5,
    commentCount: 0,
    createdAt: DateTime(2026, 11, 1),
  );

  /// One panel on screen for the signed-in user '1'. No hlsUrl, so the
  /// placeholder frame stands in for the player.
  Future<void> pumpPanel(
    WidgetTester tester, {
    required String ownerId,
    String? hlsUrl,
  }) async {
    final interactions = MockInteractionRepository();
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
    when(() => interactions.getSaveStatus('v1')).thenAnswer(
      (_) async => const SaveStatus(videoId: 'v1', saved: false),
    );
    when(
      () => interactions.recordView('v1', playId: any(named: 'playId')),
    ).thenAnswer((_) async {});

    final users = MockUserRepository();
    when(() => users.getProfiles(any())).thenAnswer(
      (_) async => {
        ownerId: UserProfileModel(
          userId: ownerId,
          displayName: 'amy',
          followerCount: 0,
          followingCount: 0,
        ),
      },
    );

    final video = clip(ownerId, hlsUrl: hlsUrl);
    feed = MockFeedRepository();
    when(() => feed.updateVisibility('v1', any())).thenAnswer(
      (inv) async =>
          video.copyWith(visibility: inv.positionalArguments[1] as VideoVisibility),
    );
    when(() => feed.updateCommentsDisabled('v1', true)).thenAnswer(
      (_) async => video.copyWith(commentsDisabled: true),
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_SignedInAuthState.new),
          interactionRepositoryProvider.overrideWithValue(interactions),
          userRepositoryProvider.overrideWithValue(users),
          feedRepositoryProvider.overrideWithValue(feed),
        ],
        child: MaterialApp(
          home: Scaffold(body: FeedVideoPanel(isActive: true, video: video)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Finder surface() => find.byKey(const Key('feed_video_surface'));

  testWidgets('the owner holding the video gets the manage menu', (
    tester,
  ) async {
    await pumpPanel(tester, ownerId: '1');

    await tester.longPress(surface());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manage_video_pin')), findsOneWidget);
    expect(find.byKey(const Key('manage_video_edit')), findsOneWidget);
    expect(find.byKey(const Key('manage_video_delete')), findsOneWidget);
  });

  testWidgets('someone else holding the video gets no menu', (tester) async {
    await pumpPanel(tester, ownerId: '123');

    await tester.longPress(surface());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manage_video_edit')), findsNothing);
  });

  testWidgets('edit video from the player saves each change', (tester) async {
    await pumpPanel(tester, ownerId: '1');

    await tester.longPress(surface());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage_video_edit')));
    await tester.pumpAndSettle();

    final friends = find.byKey(const Key('edit_video_visibility_friends'));
    await tester.tap(friends);
    await tester.pumpAndSettle();
    verify(
      () => feed.updateVisibility('v1', VideoVisibility.friends),
    ).called(1);
    expect(
      find.descendant(of: friends, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );

    final comments = find.byKey(const Key('edit_video_comments'));
    await tester.tap(comments);
    await tester.pumpAndSettle();
    verify(() => feed.updateCommentsDisabled('v1', true)).called(1);
    expect(tester.widget<SwitchListTile>(comments).value, isFalse);
  });

  group('someone else holding a playable video', () {
    // The player never finishes loading in a widget test, and its spinner
    // keeps animating, so these pump fixed frames instead of settling.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('picks the playback speed, and a badge shows it', (
      tester,
    ) async {
      await pumpPanel(tester, ownerId: '123', hlsUrl: 'https://x/v1.m3u8');
      expect(find.byKey(const Key('feed_speed_badge')), findsNothing);

      await tester.longPress(surface());
      await settle(tester);
      expect(find.byKey(const Key('playback_speed_sheet')), findsOneWidget);
      expect(find.byKey(const Key('manage_video_edit')), findsNothing);

      await tester.tap(find.byKey(const Key('playback_speed_1.5x')));
      await settle(tester);

      expect(find.byKey(const Key('playback_speed_sheet')), findsNothing);
      expect(find.byKey(const Key('feed_speed_badge')), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);

      // Back to normal: the badge goes away.
      await tester.longPress(surface());
      await settle(tester);
      await tester.tap(find.byKey(const Key('playback_speed_1x')));
      await settle(tester);
      expect(find.byKey(const Key('feed_speed_badge')), findsNothing);
    });
  });
}
