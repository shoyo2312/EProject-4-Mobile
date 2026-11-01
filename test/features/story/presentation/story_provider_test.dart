import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockStoryRepository extends Mock implements StoryRepository {}

class MockUserRepository extends Mock implements UserRepository {}

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

class _SignedOut extends AuthState {
  @override
  FutureOr<UserModel?> build() => null;
}

StoryModel story(String id, String userId, {bool viewed = false}) => StoryModel(
      id: id,
      userId: userId,
      mediaUrl: 'https://cdn.test/$id.jpg',
      mediaType: StoryMediaType.image,
      visibility: StoryVisibility.public,
      viewedByMe: viewed,
      createdAt: DateTime(2026, 11, 1),
      expiresAt: DateTime(2026, 11, 2),
    );

PageResponse<UserProfileModel> profiles(List<String> ids) => PageResponse(
      content: [
        for (final id in ids)
          UserProfileModel(
            userId: id,
            displayName: 'user $id',
            followerCount: 0,
            followingCount: 0,
          ),
      ],
      size: 100,
      number: 0,
      totalElements: ids.length,
      totalPages: 1,
    );

void main() {
  late MockStoryRepository stories;
  late MockUserRepository users;

  setUpAll(() {
    registerFallbackValue(File('x'));
    registerFallbackValue(StoryVisibility.public);
  });

  setUp(() {
    stories = MockStoryRepository();
    users = MockUserRepository();
    when(() => users.getProfiles(any()))
        .thenAnswer((_) async => <String, UserProfileModel>{});
  });

  ProviderContainer container({bool signedIn = true}) {
    final c = ProviderContainer(overrides: [
      authStateProvider
          .overrideWith(signedIn ? _SignedIn.new : _SignedOut.new),
      storyRepositoryProvider.overrideWithValue(stories),
      userRepositoryProvider.overrideWithValue(users),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('tray', () {
    test('asks for the stories of everyone followed', () async {
      when(() => users.getFollowing('1',
              page: any(named: 'page'), size: any(named: 'size')))
          .thenAnswer((_) async => profiles(['7', '9']));
      when(() => stories.feed(['7', '9'])).thenAnswer((_) async => [
            StoryGroup(userId: '7', stories: [story('a', '7')], hasUnseen: true),
          ]);

      final groups = await container().read(storyTrayProvider.future);

      expect(groups.single.userId, '7');
    });

    test('signed out there is no tray and nothing is asked', () async {
      final groups =
          await container(signedIn: false).read(storyTrayProvider.future);

      expect(groups, isEmpty);
      verifyNever(() => stories.feed(any()));
    });

    test('a watched story greys the ring once nothing is left unseen',
        () async {
      when(() => users.getFollowing('1',
              page: any(named: 'page'), size: any(named: 'size')))
          .thenAnswer((_) async => profiles(['7']));
      when(() => stories.feed(['7'])).thenAnswer((_) async => [
            StoryGroup(
              userId: '7',
              stories: [story('a', '7'), story('b', '7')],
              hasUnseen: true,
            ),
          ]);
      final c = container();
      await c.read(storyTrayProvider.future);
      final tray = c.read(storyTrayProvider.notifier);

      tray.markViewed('a');
      expect(c.read(storyTrayProvider).value!.single.hasUnseen, isTrue);

      tray.markViewed('b');
      expect(c.read(storyTrayProvider).value!.single.hasUnseen, isFalse);
    });

    test('deleting the last story of a group drops the group', () async {
      when(() => users.getFollowing('1',
              page: any(named: 'page'), size: any(named: 'size')))
          .thenAnswer((_) async => profiles([]));
      when(() => stories.feed([])).thenAnswer((_) async => [
            StoryGroup(userId: '1', stories: [story('mine', '1')]),
          ]);
      final c = container();
      await c.read(storyTrayProvider.future);

      c.read(storyTrayProvider.notifier).remove('mine');

      expect(c.read(storyTrayProvider).value, isEmpty);
    });
  });

  group('upload', () {
    final draft = StoryDraft(file: File('/tmp/a.jpg'), contentType: 'image/jpeg');

    test('a finished upload ends on done with the new story', () async {
      when(() => stories.uploadAndCreate(
            file: any(named: 'file'),
            contentType: 'image/jpeg',
            caption: 'hello',
            visibility: StoryVisibility.friends,
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => story('new', '1'));
      final c = container();

      await c.read(storyUploadProvider.notifier).start(
            draft: draft,
            caption: 'hello',
            visibility: StoryVisibility.friends,
          );

      final state = c.read(storyUploadProvider);
      expect(state.phase, StoryUploadPhase.done);
      expect(state.story!.id, 'new');
    });

    test('a refused caption is said in words, not as a code', () async {
      when(() => stories.uploadAndCreate(
            file: any(named: 'file'),
            contentType: any(named: 'contentType'),
            caption: any(named: 'caption'),
            visibility: any(named: 'visibility'),
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(const ServerException(
        422,
        'caption rejected',
        code: 'STORY_CAPTION_REJECTED',
      ));
      final c = container();

      await c.read(storyUploadProvider.notifier).start(
            draft: draft,
            caption: 'bad',
            visibility: StoryVisibility.public,
          );

      final state = c.read(storyUploadProvider);
      expect(state.phase, StoryUploadPhase.failed);
      expect(state.error, 'The caption contains words that are not allowed');
    });
  });

  test('viewers page by the last viewedAt and stop on a short page', () async {
    final first = [
      for (var i = 0; i < 20; i++)
        StoryViewer(viewerId: '$i', viewedAt: DateTime(2026, 11, 1, 10, 59 - i)),
    ];
    when(() => stories.viewers('s', before: null))
        .thenAnswer((_) async => first);
    when(() => stories.viewers('s', before: first.last.viewedAt))
        .thenAnswer((_) async => [
              StoryViewer(viewerId: 'x', viewedAt: DateTime(2026, 11, 1, 9)),
            ]);
    final c = container();
    await c.read(storyViewersProvider('s').future);

    await c.read(storyViewersProvider('s').notifier).loadMore();
    await c.read(storyViewersProvider('s').notifier).loadMore();

    expect(c.read(storyViewersProvider('s')).value, hasLength(21));
    verify(() => stories.viewers('s', before: first.last.viewedAt)).called(1);
  });
}
