import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_model.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/interaction/presentation/interaction_provider.dart';

class MockInteractionRepository extends Mock implements InteractionRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

class _SignedInAuthState extends AuthState {
  @override
  Future<UserModel?> build() async => UserModel(
        id: '1',
        username: 'jane',
        email: 'jane@test.com',
        role: UserRole.user,
        status: UserStatus.active,
        emailVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );
}

class _SignedOutAuthState extends AuthState {
  @override
  Future<UserModel?> build() async => null;
}

VideoModel video(String id) => VideoModel(
      id: id,
      userId: '123',
      title: 'title $id',
      status: VideoStatus.published,
      visibility: VideoVisibility.public,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime(2026, 8, 12),
    );

LikeStatus status({required bool liked, required int likeCount}) =>
    LikeStatus(videoId: 'v1', liked: liked, likeCount: likeCount);

void main() {
  late MockInteractionRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockInteractionRepository();
    container = ProviderContainer(
      overrides: [interactionRepositoryProvider.overrideWithValue(repository)],
    );
    when(() => repository.getLikeStatus('v1'))
        .thenAnswer((_) async => status(liked: false, likeCount: 5));
  });

  tearDown(() => container.dispose());

  test('the server count replaces the optimistic guess', () async {
    // Someone else liked it in between, so the real count is not 5 + 1.
    when(() => repository.like('v1'))
        .thenAnswer((_) async => status(liked: true, likeCount: 9));
    await container.read(likeNotifierProvider('v1').future);

    await container.read(likeNotifierProvider('v1').notifier).toggle();

    final result = container.read(likeNotifierProvider('v1')).value!;
    expect(result.liked, isTrue);
    expect(result.likeCount, 9);
  });

  test('a failed write puts the heart back', () async {
    when(() => repository.like('v1')).thenThrow(const NetworkException());
    await container.read(likeNotifierProvider('v1').future);

    await container.read(likeNotifierProvider('v1').notifier).toggle();

    final result = container.read(likeNotifierProvider('v1')).value!;
    expect(result.liked, isFalse);
    expect(result.likeCount, 5);
  });

  test('double-tapping an already-liked video sends nothing', () async {
    when(() => repository.getLikeStatus('v1'))
        .thenAnswer((_) async => status(liked: true, likeCount: 5));
    await container.read(likeNotifierProvider('v1').future);

    await container.read(likeNotifierProvider('v1').notifier).like();

    verifyNever(() => repository.like(any()));
    verifyNever(() => repository.unlike(any()));
  });

  test('a video the feed already batched costs no request of its own', () async {
    when(() => repository.getLikeStatuses(['v1']))
        .thenAnswer((_) async => [status(liked: true, likeCount: 7)]);
    await container
        .read(likeStatusCacheProvider.notifier)
        .loadMissing(['v1']);

    final result = await container.read(likeNotifierProvider('v1').future);

    expect(result.liked, isTrue);
    expect(result.likeCount, 7);
    verifyNever(() => repository.getLikeStatus(any()));
  });

  test('the cache asks only for the ids it does not hold', () async {
    when(() => repository.getLikeStatuses(any()))
        .thenAnswer((_) async => [status(liked: false, likeCount: 1)]);
    final cache = container.read(likeStatusCacheProvider.notifier);
    await cache.loadMissing(['v1']);

    await cache.loadMissing(['v1', 'v2']);

    verify(() => repository.getLikeStatuses(['v1'])).called(1);
    verify(() => repository.getLikeStatuses(['v2'])).called(1);
  });

  test('a toggled heart survives the clip scrolling off screen', () async {
    when(() => repository.like('v1'))
        .thenAnswer((_) async => status(liked: true, likeCount: 6));
    await container.read(likeNotifierProvider('v1').future);
    await container.read(likeNotifierProvider('v1').notifier).toggle();

    // Nothing watches the notifier any more, so it is disposed and rebuilt.
    container.invalidate(likeNotifierProvider('v1'));
    final result = await container.read(likeNotifierProvider('v1').future);

    expect(result.liked, isTrue);
    expect(result.likeCount, 6);
  });

  group('save', () {
    late ProviderContainer signedIn;

    setUp(() {
      signedIn = ProviderContainer(overrides: [
        interactionRepositoryProvider.overrideWithValue(repository),
        authStateProvider.overrideWith(_SignedInAuthState.new),
      ]);
      when(() => repository.getSaveStatus('v1'))
          .thenAnswer((_) async => const SaveStatus(videoId: 'v1', saved: false));
    });

    tearDown(() => signedIn.dispose());

    test('the bookmark fills before the server answers', () async {
      final completer = Completer<SaveStatus>();
      when(() => repository.save('v1')).thenAnswer((_) => completer.future);
      await signedIn.read(saveNotifierProvider('v1').future);

      final pending = signedIn.read(saveNotifierProvider('v1').notifier).toggle();

      expect(signedIn.read(saveNotifierProvider('v1')).value!.saved, isTrue);
      completer.complete(const SaveStatus(videoId: 'v1', saved: true));
      await pending;
      expect(signedIn.read(saveNotifierProvider('v1')).value!.saved, isTrue);
    });

    test('a failed write empties the bookmark again', () async {
      when(() => repository.save('v1')).thenThrow(const NetworkException());
      await signedIn.read(saveNotifierProvider('v1').future);

      await signedIn.read(saveNotifierProvider('v1').notifier).toggle();

      expect(signedIn.read(saveNotifierProvider('v1')).value!.saved, isFalse);
    });

    test('a guest is answered locally, never over the network', () async {
      final guest = ProviderContainer(overrides: [
        interactionRepositoryProvider.overrideWithValue(repository),
        authStateProvider.overrideWith(_SignedOutAuthState.new),
      ]);
      addTearDown(guest.dispose);

      final result = await guest.read(saveNotifierProvider('v1').future);

      expect(result.saved, isFalse);
      verifyNever(() => repository.getSaveStatus(any()));
    });
  });

  group('history', () {
    late MockFeedRepository feedRepository;
    late ProviderContainer history;

    setUp(() {
      feedRepository = MockFeedRepository();
      history = ProviderContainer(overrides: [
        interactionRepositoryProvider.overrideWithValue(repository),
        feedRepositoryProvider.overrideWithValue(feedRepository),
      ]);
    });

    tearDown(() => history.dispose());

    test('ids from interaction-service are hydrated by video-service', () async {
      when(() => repository.getLikedVideoIds(cursor: null, size: any(named: 'size')))
          .thenAnswer((_) async =>
              const VideoIdPage(videoIds: ['v1', 'v2'], hasMore: false));
      when(() => feedRepository.fetchByIds(['v1', 'v2']))
          .thenAnswer((_) async => [video('v1'), video('v2')]);

      final result = await history
          .read(historyVideosNotifierProvider(VideoHistory.liked).future);

      expect(result.map((v) => v.id), ['v1', 'v2']);
    });

    test('a page whose ids all vanished keeps paging instead of stopping',
        () async {
      // Every id on page 1 was deleted since it was liked, so hydration is
      // empty while `hasMore` still says there is more.
      when(() => repository.getSavedVideoIds(cursor: null, size: any(named: 'size')))
          .thenAnswer((_) async =>
              const VideoIdPage(videoIds: ['gone'], hasMore: true, nextCursor: 'c1'));
      when(() => repository.getSavedVideoIds(cursor: 'c1', size: any(named: 'size')))
          .thenAnswer((_) async =>
              const VideoIdPage(videoIds: ['v2'], hasMore: false));
      when(() => feedRepository.fetchByIds(['gone'])).thenAnswer((_) async => []);
      when(() => feedRepository.fetchByIds(['v2']))
          .thenAnswer((_) async => [video('v2')]);
      await history
          .read(historyVideosNotifierProvider(VideoHistory.saved).future);

      await history
          .read(historyVideosNotifierProvider(VideoHistory.saved).notifier)
          .loadMore();

      expect(
        history
            .read(historyVideosNotifierProvider(VideoHistory.saved))
            .value!
            .map((v) => v.id),
        ['v2'],
      );
    });
  });
}
