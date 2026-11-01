import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
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
    await tester.pump();
    verify(() => repository.setReaction('a', StoryReaction.love)).called(1);

    await tester.tap(find.byKey(const Key('story_reaction_love')));
    await tester.pump();
    verify(() => repository.clearReaction('a')).called(1);
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
