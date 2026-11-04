import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
import 'package:tiktok_mobile/features/story/presentation/floating_reactions.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_viewer_screen.dart';

class MockStoryRepository extends Mock implements StoryRepository {}

class _SignedIn extends AuthState {
  @override
  FutureOr<UserModel?> build() => UserModel(
        id: '1',
        username: 'me',
        email: 'me@test.com',
        role: UserRole.user,
        status: UserStatus.active,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );
}

StoryModel story(
  String id,
  String userId, {
  String? caption,
  StoryStatus? status,
  int? viewCount,
  bool viewed = false,
  Map<StoryReaction, int>? reactionCounts,
}) =>
    StoryModel(
      id: id,
      userId: userId,
      mediaUrl: 'https://cdn.test/$id.jpg',
      mediaType: StoryMediaType.image,
      caption: caption,
      visibility: StoryVisibility.public,
      status: status,
      viewCount: viewCount,
      viewedByMe: viewed,
      reactionCounts: reactionCounts,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      expiresAt: DateTime.now().add(const Duration(hours: 23)),
    );

void main() {
  late MockStoryRepository repository;

  setUpAll(() => registerFallbackValue(StoryReaction.like));

  setUp(() {
    repository = MockStoryRepository();
    when(() => repository.recordView(any())).thenAnswer((_) async {});
    when(() => repository.setReaction(any(), any())).thenAnswer((_) async {});
    when(() => repository.clearReaction(any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, List<StoryGroup> groups) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_SignedIn.new),
        storyRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: StoryViewerScreen(args: StoryViewerArgs(groups: groups)),
      ),
    ));
    // Let the session resolve and the post-frame view record run. Not
    // pumpAndSettle: the progress bar animates for as long as it is shown.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets("someone else's story counts a view and offers a reply",
      (tester) async {
    await pump(tester, [
      StoryGroup(
        userId: '7',
        stories: [story('a', '7', caption: 'beach day')],
        hasUnseen: true,
      ),
    ]);

    expect(find.byKey(const Key('story_caption')), findsOneWidget);
    expect(find.text('beach day'), findsOneWidget);
    expect(find.byKey(const Key('story_reply_field')), findsOneWidget);
    expect(find.byKey(const Key('story_viewers_button')), findsNothing);
    verify(() => repository.recordView('a')).called(1);
  });

  testWidgets('a reaction is sent, and tapping it again takes it back',
      (tester) async {
    await pump(tester, [
      StoryGroup(userId: '7', stories: [story('a', '7', viewed: true)]),
    ]);

    await tester.tap(find.byKey(const Key('story_reaction_love')));
    await tester.pump(const Duration(milliseconds: 450));
    verify(() => repository.setReaction('a', StoryReaction.love)).called(1);

    await tester.tap(find.byKey(const Key('story_reaction_love')));
    await tester.pump(const Duration(milliseconds: 450));
    verify(() => repository.clearReaction('a')).called(1);
    // Let the last emoji finish its flight.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a reaction sends emoji flying, 3 to 5 per tap, then they go',
      (tester) async {
    await pump(tester, [
      StoryGroup(userId: '7', stories: [story('a', '7', viewed: true)]),
    ]);
    final bar = tester
        .state<FloatingReactionsState>(find.byType(FloatingReactions));

    await tester.tap(find.byKey(const Key('story_reaction_wow')));
    await tester.pump(const Duration(milliseconds: 16));
    expect(bar.inFlight, inInclusiveRange(3, 5));

    await tester.pump(FloatingReactions.maxLifetime);
    await tester.pump(const Duration(milliseconds: 16));
    expect(bar.inFlight, 0);
  });

  testWidgets('tapping away at the bar sends one request, for where it ended',
      (tester) async {
    await pump(tester, [
      StoryGroup(userId: '7', stories: [story('a', '7', viewed: true)]),
    ]);

    // Love, unlove, love, then wow — all inside the settle window.
    for (final key in ['love', 'love', 'love', 'wow']) {
      await tester.tap(find.byKey(Key('story_reaction_$key')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    verifyNever(() => repository.setReaction(any(), any()));

    await tester.pump(const Duration(milliseconds: 450));
    verify(() => repository.setReaction('a', StoryReaction.wow)).called(1);
    verifyNever(() => repository.clearReaction(any()));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('tapping back to where it started sends nothing',
      (tester) async {
    await pump(tester, [
      StoryGroup(userId: '7', stories: [story('a', '7', viewed: true)]),
    ]);

    await tester.tap(find.byKey(const Key('story_reaction_sad')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('story_reaction_sad')));
    await tester.pump(const Duration(milliseconds: 450));

    verifyNever(() => repository.setReaction(any(), any()));
    verifyNever(() => repository.clearReaction(any()));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a refused reaction puts the bar back', (tester) async {
    when(() => repository.setReaction(any(), any()))
        .thenThrow(const NetworkException());
    await pump(tester, [
      StoryGroup(userId: '7', stories: [story('a', '7', viewed: true)]),
    ]);

    await tester.tap(find.byKey(const Key('story_reaction_love')));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    verify(() => repository.setReaction('a', StoryReaction.love)).called(1);
    // Nothing is shown as chosen once the server said no.
    final scale = tester.widget<AnimatedScale>(find.descendant(
        of: find.byKey(const Key('story_reaction_love')),
        matching: find.byType(AnimatedScale)));
    expect(scale.scale, 1);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('your own story shows its views and its review status',
      (tester) async {
    await pump(tester, [
      StoryGroup(userId: '1', stories: [
        story('mine', '1',
            status: StoryStatus.pendingModeration, viewCount: 3),
      ]),
    ]);

    expect(find.text('3 views'), findsOneWidget);
    expect(find.byKey(const Key('story_status_notice')), findsOneWidget);
    expect(find.byKey(const Key('story_reply_field')), findsNothing);
    // The owner's own view is never counted.
    verifyNever(() => repository.recordView(any()));
  });

  testWidgets('opening your own story sends up what everyone gave it, once',
      (tester) async {
    await pump(tester, [
      StoryGroup(userId: '1', stories: [
        story('mine', '1',
            viewCount: 4,
            reactionCounts: {StoryReaction.love: 2, StoryReaction.wow: 1}),
      ]),
    ]);
    await tester.pump(const Duration(milliseconds: 16));

    // The counts under it, drawn with the same 3D pictures.
    expect(find.byKey(const Key('story_reaction_count_love')), findsOneWidget);
    expect(find.byKey(const Key('story_reaction_count_wow')), findsOneWidget);

    final footer = tester
        .state<FloatingReactionsState>(find.byType(FloatingReactions));
    // Three reactions, three copies — fewer than the cap, so one each.
    expect(footer.inFlight, 3);

    // Three copies: two gaps, then the longest flight. Well inside the
    // story's own length, which would otherwise end and close the viewer.
    await tester.pump(FloatingReactions.replayGap * 2 +
        const Duration(milliseconds: 1950));
    await tester.pump(const Duration(milliseconds: 16));
    expect(footer.inFlight, 0);
    // A rebuild does not play it again.
    await tester.pump(const Duration(milliseconds: 300));
    expect(footer.inFlight, 0);
  });

  testWidgets('your own story with no reactions sends nothing up',
      (tester) async {
    await pump(tester, [
      StoryGroup(userId: '1', stories: [story('mine', '1', viewCount: 2)]),
    ]);
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      tester
          .state<FloatingReactionsState>(find.byType(FloatingReactions))
          .inFlight,
      0,
    );
  });

  group('which reactions a replay sends', () {
    test('every one, when there are few', () {
      final picks = FloatingReactionsState.replayPicks(
          {StoryReaction.love: 2, StoryReaction.sad: 1}, Random(1));
      expect(picks, hasLength(3));
      expect(picks.where((r) => r == StoryReaction.love), hasLength(2));
    });

    test('at most the cap, in proportion, every kind at least once', () {
      final picks = FloatingReactionsState.replayPicks(
          {StoryReaction.love: 90, StoryReaction.like: 9, StoryReaction.sad: 1},
          Random(1));
      expect(picks, hasLength(FloatingReactions.maxReplay));
      expect(picks, contains(StoryReaction.sad));
      expect(picks, contains(StoryReaction.like));
      expect(picks.where((r) => r == StoryReaction.love).length,
          greaterThan(picks.length ~/ 2));
    });

    test('nothing for nothing', () {
      expect(FloatingReactionsState.replayPicks({}, Random(1)), isEmpty);
      expect(
          FloatingReactionsState.replayPicks(
              {StoryReaction.love: 0}, Random(1)),
          isEmpty);
    });
  });

  testWidgets('opens at the first story not seen yet', (tester) async {
    await pump(tester, [
      StoryGroup(userId: '7', stories: [
        story('old', '7', caption: 'seen already', viewed: true),
        story('new', '7', caption: 'not seen'),
      ], hasUnseen: true),
    ]);

    expect(find.text('not seen'), findsOneWidget);
    expect(find.text('seen already'), findsNothing);
  });
}
