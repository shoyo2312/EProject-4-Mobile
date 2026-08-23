import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_remote_datasource.dart';
import 'package:tiktok_mobile/features/user/data/user_repository.dart';

part 'user_provider.freezed.dart';
part 'user_provider.g.dart';

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) =>
    UserRepository(UserRemoteDatasource(ref.watch(apiClientProvider)));

@riverpod
class MyProfile extends _$MyProfile {
  @override
  FutureOr<UserProfileModel> build() {
    return ref.read(userRepositoryProvider).getMyProfile();
  }

  Future<void> updateProfile(Map<String, dynamic> changes) async {
    final updated = await ref.read(userRepositoryProvider).updateMyProfile(changes);
    ref.read(profileCacheProvider.notifier).put(updated);
    state = AsyncData(updated);
  }
}

/// Profiles already fetched, keyed by `userId`.
///
/// One place so a screen that already knows a list of ids — a feed page, a
/// page of comments — resolves them in a single `GET /users?ids=` instead of
/// one request per row: the gateway allows 20 req/s per IP, and a feed page
/// alone would spend the lot (user doc 3.3b).
@Riverpod(keepAlive: true)
class ProfileCache extends _$ProfileCache {
  @override
  Map<String, UserProfileModel> build() => const {};

  /// Fetches only the ids not held yet. Ids the server omits (missing, or
  /// blocked either way) stay absent — callers show a placeholder for those,
  /// and asking again on the next page is cheap enough not to track them.
  Future<void> loadMissing(Iterable<String> ids) async {
    final missing = [
      for (final id in ids.toSet())
        if (!state.containsKey(id)) id,
    ];
    if (missing.isEmpty) return;
    state = {...state, ...await ref.read(userRepositoryProvider).getProfiles(missing)};
  }

  void put(UserProfileModel profile) =>
      state = {...state, profile.userId: profile};
}

/// Relationship flags aren't part of `UserProfileResponse` (the backend has
/// no "am I following/blocking/muting this user" field) — the client tracks
/// them locally, seeded to unknown (`null`) and set from action results.
///
/// Freezed rather than a hand-written copyWith: the flags are nullable, and a
/// `field ?? this.field` copyWith silently cannot put one back to "unknown".
@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    required UserProfileModel profile,
    bool? isFollowing,
    bool? isBlocked,
    bool? isMuted,
  }) = _ProfileState;
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  FutureOr<ProfileState> build(String userId) async {
    // Read, not watch: `put` below writes to the cache, and watching it here
    // would rebuild this provider straight back over its own result.
    final cached = ref.read(profileCacheProvider)[userId];
    if (cached != null) return ProfileState(profile: cached);

    final profile = await ref.read(userRepositoryProvider).getProfile(userId);
    ref.read(profileCacheProvider.notifier).put(profile);
    return ProfileState(profile: profile);
  }

  Future<void> toggleFollow() => _toggle(
        current: (s) => s.isFollowing,
        apply: (s, value) => s.copyWith(isFollowing: value),
        doAction: (repo, wasActive) =>
            wasActive ? repo.unfollow(userId) : repo.follow(userId),
        alreadyCode: 'ALREADY_FOLLOWING',
        notActiveCode: 'NOT_FOLLOWING',
      );

  Future<void> toggleBlock() => _toggle(
        current: (s) => s.isBlocked,
        apply: (s, value) => s.copyWith(isBlocked: value),
        doAction: (repo, wasActive) =>
            wasActive ? repo.unblock(userId) : repo.block(userId),
        alreadyCode: 'ALREADY_BLOCKED',
        notActiveCode: 'NOT_BLOCKED',
      );

  Future<void> toggleMute() => _toggle(
        current: (s) => s.isMuted,
        apply: (s, value) => s.copyWith(isMuted: value),
        doAction: (repo, wasActive) =>
            wasActive ? repo.unmute(userId) : repo.mute(userId),
        alreadyCode: 'ALREADY_MUTED',
        notActiveCode: 'NOT_MUTED',
      );

  Future<void> _toggle({
    required bool? Function(ProfileState) current,
    required ProfileState Function(ProfileState, bool) apply,
    required Future<void> Function(UserRepository repo, bool wasActive) doAction,
    required String alreadyCode,
    required String notActiveCode,
  }) async {
    final existing = state.valueOrNull;
    if (existing == null) return;
    final wasActive = current(existing) ?? false;
    final repo = ref.read(userRepositoryProvider);
    try {
      await doAction(repo, wasActive);
      state = AsyncData(apply(existing, !wasActive));
    } on ServerException catch (e) {
      if (e.code == alreadyCode) {
        state = AsyncData(apply(existing, true));
      } else if (e.code == notActiveCode) {
        state = AsyncData(apply(existing, false));
      } else {
        rethrow;
      }
    }
    // Follow/block both affect counters on both sides; block also hides the
    // profile entirely (doc 3.8) so refreshing may legitimately 404 — that's
    // fine, just keep the last-known counts rather than surfacing an error.
    try {
      final refreshed = await repo.getProfile(userId);
      ref.read(profileCacheProvider.notifier).put(refreshed);
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData(latest.copyWith(profile: refreshed));
      }
    } on AppException {
      // ignore — see comment above
    }
    ref.invalidate(myProfileProvider);
  }
}

enum UserListType { followers, following, blocked, muted }

class UserListArgs {
  const UserListArgs(this.type, [this.userId]);

  final UserListType type;
  final String? userId;

  @override
  bool operator ==(Object other) =>
      other is UserListArgs && other.type == type && other.userId == userId;

  @override
  int get hashCode => Object.hash(type, userId);
}

@riverpod
class UserListNotifier extends _$UserListNotifier {
  int _page = 0;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<UserProfileModel>> build(UserListArgs args) async {
    _page = 0;
    final page = await _fetchPage(0);
    _more.done = page.last;
    return page.content;
  }

  Future<void> loadMore() => _more.run(() async {
        final nextPage = _page + 1;
        final page = await _fetchPage(nextPage);
        _page = nextPage;
        _more.done = page.last;
        final current = state.value ?? [];
        state = AsyncData([...current, ...page.content]);
      });

  Future<PageResponse<UserProfileModel>> _fetchPage(int page) {
    final repo = ref.read(userRepositoryProvider);
    switch (args.type) {
      case UserListType.followers:
        return repo.getFollowers(args.userId!, page: page);
      case UserListType.following:
        return repo.getFollowing(args.userId!, page: page);
      case UserListType.blocked:
        return repo.getBlocked(page: page);
      case UserListType.muted:
        return repo.getMuted(page: page);
    }
  }
}
