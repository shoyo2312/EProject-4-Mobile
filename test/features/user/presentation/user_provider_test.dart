import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class MockUserRepository extends Mock implements UserRepository {}

UserProfileModel profile({int followerCount = 10}) => UserProfileModel(
      userId: 'u1',
      displayName: 'Jane',
      followerCount: followerCount,
      followingCount: 3,
    );

void main() {
  late MockUserRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockUserRepository();
    container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    when(() => repository.getProfile('u1')).thenAnswer((_) async => profile());
  });

  tearDown(() => container.dispose());

  Future<ProfileNotifier> loadedNotifier() async {
    await container.read(profileNotifierProvider('u1').future);
    return container.read(profileNotifierProvider('u1').notifier);
  }

  test('follow flips the flag and picks up the refreshed counters', () async {
    when(() => repository.follow('u1')).thenAnswer((_) async {});
    final notifier = await loadedNotifier();
    // The refresh that follows the action sees the incremented count.
    when(() => repository.getProfile('u1'))
        .thenAnswer((_) async => profile(followerCount: 11));

    await notifier.toggleFollow();

    final state = container.read(profileNotifierProvider('u1')).value!;
    expect(state.isFollowing, true);
    expect(state.profile.followerCount, 11);
  });

  test('unfollows when the flag is already set', () async {
    when(() => repository.follow('u1')).thenAnswer((_) async {});
    when(() => repository.unfollow('u1')).thenAnswer((_) async {});
    final notifier = await loadedNotifier();

    await notifier.toggleFollow();
    await notifier.toggleFollow();

    expect(container.read(profileNotifierProvider('u1')).value!.isFollowing, false);
    verify(() => repository.unfollow('u1')).called(1);
  });

  test('ALREADY_FOLLOWING means the server is right and the flag was stale',
      () async {
    // The flag starts unknown, so the first tap guesses "follow" — the server
    // says that already happened. Trust it rather than surfacing an error.
    when(() => repository.follow('u1'))
        .thenThrow(const ServerException(409, 'already', code: 'ALREADY_FOLLOWING'));
    final notifier = await loadedNotifier();

    await notifier.toggleFollow();

    expect(container.read(profileNotifierProvider('u1')).value!.isFollowing, true);
  });

  test('NOT_MUTED settles the flag to false', () async {
    when(() => repository.mute('u1'))
        .thenThrow(const ServerException(409, 'not muted', code: 'NOT_MUTED'));
    final notifier = await loadedNotifier();

    await notifier.toggleMute();

    expect(container.read(profileNotifierProvider('u1')).value!.isMuted, false);
  });

  test('an unrelated server error is not swallowed', () async {
    when(() => repository.block('u1'))
        .thenThrow(const ServerException(500, 'boom', code: 'INTERNAL_ERROR'));
    final notifier = await loadedNotifier();

    await expectLater(notifier.toggleBlock(), throwsA(isA<ServerException>()));
  });

  test('blocking keeps the last-known profile when the refresh 404s', () async {
    when(() => repository.block('u1')).thenAnswer((_) async {});
    final notifier = await loadedNotifier();
    // Blocking hides the profile, so re-reading it legitimately fails.
    when(() => repository.getProfile('u1'))
        .thenThrow(const ServerException(404, 'gone', code: 'USER_NOT_FOUND'));

    await notifier.toggleBlock();

    final state = container.read(profileNotifierProvider('u1')).value!;
    expect(state.isBlocked, true);
    expect(state.profile.followerCount, 10);
  });

  group('profile cache', () {
    test('loadMissing only asks for ids it does not hold yet', () async {
      when(() => repository.getProfiles(['u1', 'u2'])).thenAnswer(
        (_) async => {'u1': profile(), 'u2': profile()},
      );
      final cache = container.read(profileCacheProvider.notifier);

      await cache.loadMissing(['u1', 'u2', 'u1']);
      when(() => repository.getProfiles(['u3']))
          .thenAnswer((_) async => {'u3': profile()});
      await cache.loadMissing(['u1', 'u2', 'u3']);

      verify(() => repository.getProfiles(['u1', 'u2'])).called(1);
      verify(() => repository.getProfiles(['u3'])).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('a cached profile spares the per-user request', () async {
      when(() => repository.getProfiles(['u1']))
          .thenAnswer((_) async => {'u1': profile()});
      await container.read(profileCacheProvider.notifier).loadMissing(['u1']);

      final state = await container.read(profileNotifierProvider('u1').future);

      expect(state.profile.displayName, 'Jane');
      verifyNever(() => repository.getProfile('u1'));
    });

    test('an uncached profile is fetched once and then cached', () async {
      await container.read(profileNotifierProvider('u1').future);

      expect(container.read(profileCacheProvider)['u1'], profile());
    });
  });
}
