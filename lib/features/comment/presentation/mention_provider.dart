import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// How far each list is read. A page is at most 50 (user-service caps it).
const _pageSize = 50;
const _followingScanLimit = 1000;
const _followerScanLimit = 2000;

/// The people the viewer may tag in a comment: those they follow who follow
/// them back. user-service has no friends listing, so it is the
/// intersection of the viewer's following and followers, as the Friends tab
/// works it out. Kept five minutes after the last comment sheet closes, so
/// opening another video's comments does not read both lists again.
final mentionFriendsProvider =
    FutureProvider.autoDispose<List<UserProfileModel>>((ref) async {
      final me = await ref.watch(authStateProvider.future);
      if (me == null) return const [];
      final link = ref.keepAlive();
      Timer? expiry;
      ref.onCancel(() {
        expiry = Timer(const Duration(minutes: 5), link.close);
      });
      ref.onResume(() => expiry?.cancel());
      ref.onDispose(() => expiry?.cancel());

      final users = ref.read(userRepositoryProvider);
      final following = <UserProfileModel>[];
      for (var page = 0; following.length < _followingScanLimit; page++) {
        final result = await users.getFollowing(
          me.id,
          page: page,
          size: _pageSize,
        );
        following.addAll(result.content);
        if (result.last || result.content.isEmpty) break;
      }
      if (following.isEmpty) return const [];

      final followers = <String>{};
      for (var page = 0; followers.length < _followerScanLimit; page++) {
        final result = await users.getFollowers(
          me.id,
          page: page,
          size: _pageSize,
        );
        followers.addAll(result.content.map((p) => p.userId));
        if (result.last || result.content.isEmpty) break;
      }
      return [
        for (final p in following)
          if (p.userId != me.id && followers.contains(p.userId)) p,
      ];
    });
