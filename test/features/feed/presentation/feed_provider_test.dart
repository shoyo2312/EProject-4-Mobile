import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

class MockUserRepository extends Mock implements UserRepository {}

/// The feed resolves the authors of every page it loads through the profile
/// cache; without this override that reaches for a real ApiClient.
Override authorOverride() {
  final userRepository = MockUserRepository();
  when(() => userRepository.getProfiles(any()))
      .thenAnswer((_) async => <String, UserProfileModel>{});
  return userRepositoryProvider.overrideWithValue(userRepository);
}

VideoModel makeVideo(String id) => VideoModel(
      id: id,
      userId: '123',
      title: 'title $id',
      hlsUrl: 'https://cdn.test/$id.m3u8',
      status: VideoStatus.published,
      visibility: VideoVisibility.public,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime(2026, 8, 12),
    );

VideoPage feedPage(List<String> ids, {String? nextCursor}) =>
    VideoPage(items: ids.map(makeVideo).toList(), nextCursor: nextCursor);

PageResponse<VideoModel> pageOf(
  List<String> ids, {
  required int number,
  required int totalPages,
}) =>
    PageResponse(
      content: ids.map(makeVideo).toList(),
      size: 20,
      number: number,
      totalElements: totalPages * 20,
      totalPages: totalPages,
    );

class _SignedOutAuthState extends AuthState {
  @override
  FutureOr<UserModel?> build() => null;
}

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
  late MockFeedRepository feedRepository;
  late ProviderContainer container;

  /// Rebuilds the container against a session. Ranking is per-account, so a
  /// signed-out viewer never reaches recommendation-service at all.
  void signIn() {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_SignedInAuthState.new),
        feedRepositoryProvider.overrideWithValue(feedRepository),
        authorOverride(),
      ],
    );
  }

  setUp(() {
    feedRepository = MockFeedRepository();
    container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_SignedOutAuthState.new),
        feedRepositoryProvider.overrideWithValue(feedRepository),
        authorOverride(),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('build() loads the first page', () async {
    when(() => feedRepository.fetchFeed(cursor: null, size: any(named: 'size')))
        .thenAnswer((_) async => feedPage(['v1']));

    final result = await container.read(feedNotifierProvider.future);

    expect(result.map((v) => v.id), ['v1']);
  });

  test('loadMore() drops videos already on screen', () async {
    // The cursor anchors on the last item, but a repeated id must still never
    // reach the list twice.
    when(() => feedRepository.fetchFeed(cursor: null, size: any(named: 'size')))
        .thenAnswer((_) async => feedPage(['v1', 'v2'], nextCursor: 'c1'));
    when(() => feedRepository.fetchFeed(cursor: 'c1', size: any(named: 'size')))
        .thenAnswer((_) async => feedPage(['v2', 'v3']));
    await container.read(feedNotifierProvider.future);

    await container.read(feedNotifierProvider.notifier).loadMore();

    final result = container.read(feedNotifierProvider).value!;
    expect(result.map((v) => v.id), ['v1', 'v2', 'v3']);
  });

  test('loadMore() stops once nextCursor comes back null', () async {
    when(() => feedRepository.fetchFeed(cursor: null, size: any(named: 'size')))
        .thenAnswer((_) async => feedPage(['v1']));
    await container.read(feedNotifierProvider.future);

    await container.read(feedNotifierProvider.notifier).loadMore();

    // Only the initial load happened; loadMore made no second request.
    verify(() => feedRepository.fetchFeed(cursor: null, size: any(named: 'size')))
        .called(1);
    verifyNoMoreInteractions(feedRepository);
  });

  test('a signed-in viewer gets the ranked feed, in the order it ranked',
      () async {
    signIn();
    when(() => feedRepository.fetchRankedFeed(limit: any(named: 'limit')))
        .thenAnswer((_) async => ['v3', 'v1'].map(makeVideo).toList());

    final result = await container.read(feedNotifierProvider.future);

    expect(result.map((v) => v.id), ['v3', 'v1']);
    verifyNever(() => feedRepository.fetchFeed(
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        ));
  });

  test('recommendation-service being down does not take the feed with it',
      () async {
    signIn();
    when(() => feedRepository.fetchRankedFeed(limit: any(named: 'limit')))
        .thenThrow(const NetworkException());
    when(() => feedRepository.fetchFeed(cursor: null, size: any(named: 'size')))
        .thenAnswer((_) async => feedPage(['v1']));

    final result = await container.read(feedNotifierProvider.future);

    expect(result.map((v) => v.id), ['v1']);
  });

  test('an exhausted ranking falls back, once, and stays fallen back',
      () async {
    signIn();
    when(() => feedRepository.fetchRankedFeed(limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => feedRepository.fetchFeed(cursor: null, size: any(named: 'size')))
        .thenAnswer((_) async => feedPage(['v1'], nextCursor: 'c1'));
    when(() => feedRepository.fetchFeed(cursor: 'c1', size: any(named: 'size')))
        .thenAnswer((_) async => feedPage(['v2']));
    await container.read(feedNotifierProvider.future);

    await container.read(feedNotifierProvider.notifier).loadMore();

    expect(
      container.read(feedNotifierProvider).value!.map((v) => v.id),
      ['v1', 'v2'],
    );
    // Asked once, on the page that ran dry — never again on this feed.
    verify(() => feedRepository.fetchRankedFeed(limit: any(named: 'limit')))
        .called(1);
  });

  test('a ranked page of videos already on screen keeps looking', () async {
    signIn();
    // First page ranks v1; the second ranks nothing new, which would leave the
    // list the same length and stall the PageView for good.
    var call = 0;
    when(() => feedRepository.fetchRankedFeed(limit: any(named: 'limit')))
        .thenAnswer((_) async {
      call++;
      return call == 1
          ? [makeVideo('v1')]
          : call == 2
              ? [makeVideo('v1')]
              : [makeVideo('v2')];
    });
    await container.read(feedNotifierProvider.future);

    await container.read(feedNotifierProvider.notifier).loadMore();

    expect(
      container.read(feedNotifierProvider).value!.map((v) => v.id),
      ['v1', 'v2'],
    );
  });

  test('deleting one of my videos removes it from the list', () async {
    when(() => feedRepository.getUserVideos('123')).thenAnswer(
      (_) async => pageOf(['v1', 'v2'], number: 0, totalPages: 1),
    );
    when(() => feedRepository.deleteVideo('v1')).thenAnswer((_) async {});
    await container.read(userVideosNotifierProvider('123').future);

    await container.read(userVideosNotifierProvider('123').notifier).delete('v1');

    final result = container.read(userVideosNotifierProvider('123')).value!;
    expect(result.map((v) => v.id), ['v2']);
  });
}
