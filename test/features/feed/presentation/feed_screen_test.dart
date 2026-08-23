import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
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

class MockFeedRepository extends Mock implements FeedRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockInteractionRepository extends Mock implements InteractionRepository {}

/// The screen needs three things stubbed beyond the videos themselves: a
/// session (ranking is only asked for when there is one), the like state of
/// the clip on screen, and the author behind the caption.
class _SignedOutAuthState extends AuthState {
  @override
  FutureOr<UserModel?> build() => null;
}

List<Override> _overrides({
  required FeedRepository feedRepository,
  required UserRepository userRepository,
  required int likeCount,
}) {
  final interactionRepository = MockInteractionRepository();
  when(() => interactionRepository.getCounts(any())).thenAnswer(
    (invocation) async => InteractionCounts(
      videoId: invocation.positionalArguments.first as String,
      likeCount: likeCount,
      commentCount: 0,
      shareCount: 0,
      viewCount: 0,
    ),
  );
  when(() => interactionRepository.getLikeStatus(any())).thenAnswer(
    (invocation) async => LikeStatus(
      videoId: invocation.positionalArguments.first as String,
      liked: false,
      likeCount: likeCount,
    ),
  );
  return [
    authStateProvider.overrideWith(_SignedOutAuthState.new),
    feedRepositoryProvider.overrideWithValue(feedRepository),
    userRepositoryProvider.overrideWithValue(userRepository),
    interactionRepositoryProvider.overrideWithValue(interactionRepository),
  ];
}

void main() {
  testWidgets('renders the title and the like count of the first video',
      (tester) async {
    final feedRepository = MockFeedRepository();
    final video = VideoModel(
      id: 'v1',
      userId: '123',
      title: 'hello world',
      description: 'a description',
      hlsUrl: 'https://cdn.test/v1.m3u8',
      status: VideoStatus.published,
      visibility: VideoVisibility.public,
      viewCount: 9,
      likeCount: 5,
      commentCount: 0,
      createdAt: DateTime(2026, 8, 12),
    );
    when(() => feedRepository.fetchFeed(
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => VideoPage(items: [video]));

    // The caption shows the author. The feed resolves every author of a page
    // in one batched call before handing the page over.
    final userRepository = MockUserRepository();
    when(() => userRepository.getProfiles(any())).thenAnswer(
      (_) async => const {
        '123': UserProfileModel(
          userId: '123',
          displayName: 'jane',
          followerCount: 0,
          followingCount: 0,
        ),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          feedRepository: feedRepository,
          userRepository: userRepository,
          likeCount: 5,
        ),
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('jane'), findsOneWidget);
    expect(find.text('hello world'), findsOneWidget);
    expect(find.text('a description'), findsOneWidget);
    expect(find.byKey(const Key('feed_like_count_v1')), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('a single tap on the panel toggles the pause badge',
      (tester) async {
    final feedRepository = MockFeedRepository();
    when(() => feedRepository.fetchFeed(
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer(
      (_) async => VideoPage(
        items: [
          VideoModel(
            id: 'v1',
            userId: '123',
            title: 'hello world',
            hlsUrl: 'https://cdn.test/v1.m3u8',
            status: VideoStatus.published,
            visibility: VideoVisibility.public,
            viewCount: 9,
            likeCount: 5,
            commentCount: 0,
            createdAt: DateTime(2026, 8, 12),
          ),
        ],
      ),
    );
    final userRepository = MockUserRepository();
    when(() => userRepository.getProfiles(any())).thenAnswer(
      (_) async => const {
        '123': UserProfileModel(
          userId: '123',
          displayName: 'jane',
          followerCount: 0,
          followingCount: 0,
        ),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          feedRepository: feedRepository,
          userRepository: userRepository,
          likeCount: 5,
        ),
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    double badgeOpacity() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(const Key('feed_pause_badge')),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    expect(badgeOpacity(), 0);

    // The tap is held back until the double-tap window closes; pumping past
    // that window and then past the badge's fade is what makes it visible.
    // (pumpAndSettle would hang on the player's spinner.)
    await tester.tap(find.byKey(const Key('feed_pause_badge')), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(badgeOpacity(), 1);

    await tester.tap(find.byKey(const Key('feed_pause_badge')), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(badgeOpacity(), 0);
  });
}
