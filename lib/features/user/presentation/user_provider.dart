import 'dart:async';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/user/data/follow_models.dart';
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
    // Rebuild whenever the signed-in account changes, so one account's profile
    // can never be served to the next one that logs in on this device.
    ref.watch(authStateProvider.select((s) => s.valueOrNull?.id));
    return ref.read(userRepositoryProvider).getMyProfile();
  }

  Future<void> updateProfile(Map<String, dynamic> changes) async {
    final updated = await ref
        .read(userRepositoryProvider)
        .updateMyProfile(changes);
    _publish(updated);
  }

  /// Uploads the picked file and takes the profile the server answers with —
  /// including the avatar URL it chose, which is the only one the allow-list
  /// will accept back on a later `PATCH`.
  Future<void> uploadAvatar(File file, {required String contentType}) async {
    final updated = await ref
        .read(userRepositoryProvider)
        .uploadAvatar(file, contentType: contentType);
    _publish(updated);
  }

  void _publish(UserProfileModel profile) {
    ref.read(profileCacheProvider.notifier).put(profile);
    state = AsyncData(profile);
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
    state = {
      ...state,
      ...await ref.read(userRepositoryProvider).getProfiles(missing),
    };
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

    /// A follow request is waiting for this private account to approve it.
    bool? isRequested,
    bool? isBlocked,
    bool? isMuted,
  }) = _ProfileState;
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  bool _disposed = false;

  @override
  FutureOr<ProfileState> build(String userId) async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Read, not watch: `put` below writes to the cache, and watching it here
    // would rebuild this provider straight back over its own result.
    final cached = ref.read(profileCacheProvider)[userId];
    final profile =
        cached ?? await ref.read(userRepositoryProvider).getProfile(userId);
    if (cached == null) ref.read(profileCacheProvider.notifier).put(profile);
    // Not awaited: the card or page shows at once, and the button settles to
    // Following / Requested a moment later.
    unawaited(_seedFollowState());
    return ProfileState(profile: profile);
  }

  /// One `GET /friendship` for the Follow button (user doc 3.17). Only for
  /// someone else and only when signed in — the endpoint needs a token.
  Future<void> _seedFollowState() async {
    final me = ref.read(authStateProvider).valueOrNull;
    if (me == null || me.id == userId) return;
    try {
      final friendship = await ref
          .read(userRepositoryProvider)
          .getFriendship(userId);
      final current = state.valueOrNull;
      if (_disposed || current == null) return;
      // A tap that already answered wins over this older read.
      if (current.isFollowing != null || current.isRequested != null) return;
      state = AsyncData(
        current.copyWith(
          isFollowing: friendship.following,
          isRequested: friendship.requested,
        ),
      );
    } on AppException {
      // The button stays "Follow"; a tap still gets the server's answer.
    }
  }

  /// Follow, or — when following or a request is waiting — unfollow, which on
  /// the server also withdraws a request (user doc 3.5).
  Future<void> toggleFollow() async {
    final existing = state.valueOrNull;
    if (existing == null) return;
    final active =
        (existing.isFollowing ?? false) || (existing.isRequested ?? false);
    final repo = ref.read(userRepositoryProvider);
    try {
      if (active) {
        await repo.unfollow(userId);
        state = AsyncData(
          existing.copyWith(isFollowing: false, isRequested: false),
        );
      } else {
        final status = await repo.follow(userId);
        state = AsyncData(
          existing.copyWith(
            isFollowing: status != FollowStatus.requested,
            isRequested: status == FollowStatus.requested,
          ),
        );
      }
    } on ServerException catch (e) {
      switch (e.code) {
        case 'ALREADY_FOLLOWING':
          state = AsyncData(
            existing.copyWith(isFollowing: true, isRequested: false),
          );
        case 'ALREADY_REQUESTED':
          state = AsyncData(
            existing.copyWith(isFollowing: false, isRequested: true),
          );
        case 'NOT_FOLLOWING':
          state = AsyncData(
            existing.copyWith(isFollowing: false, isRequested: false),
          );
        default:
          rethrow;
      }
    }
    await _refreshProfile(repo);
  }

  Future<void> toggleBlock() => _toggle(
    current: (s) => s.isBlocked,
    // Blocking also ends any follow or request between the two.
    apply: (s, value) => s.copyWith(
      isBlocked: value,
      isFollowing: value ? false : s.isFollowing,
      isRequested: value ? false : s.isRequested,
    ),
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
    required Future<void> Function(UserRepository repo, bool wasActive)
    doAction,
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
    await _refreshProfile(repo);
  }

  // Follow/block both affect counters on both sides; block also hides the
  // profile entirely (doc 3.8) so refreshing may legitimately 404 — that's
  // fine, just keep the last-known counts rather than surfacing an error.
  Future<void> _refreshProfile(UserRepository repo) async {
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

enum UserListType { followers, following, blocked, muted, followRequests }

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
      case UserListType.followRequests:
        return repo.getFollowRequests(page: page);
    }
  }

  /// Drops a row once it has been dealt with — an approved or declined
  /// follow request — without reloading the list.
  void remove(String userId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final u in current)
        if (u.userId != userId) u,
    ]);
  }
}
