import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  /// Null means "my own profile" (route `/profile`).
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    final isOwnProfile = userId == null || userId == myId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'My Profile' : 'Profile'),
        actions: isOwnProfile
            ? [
                IconButton(
                  key: const Key('profile_edit_button'),
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/profile/edit'),
                ),
                IconButton(
                  key: const Key('profile_logout_button'),
                  icon: const Icon(Icons.logout),
                  onPressed: () => ref.read(authStateProvider.notifier).logout(),
                ),
              ]
            : null,
      ),
      body: isOwnProfile ? const _MyProfileBody() : _OtherProfileBody(userId: userId!),
    );
  }
}

class _MyProfileBody extends ConsumerWidget {
  const _MyProfileBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(myProfileProvider);
    return profileState.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(myProfileProvider),
      ),
      data: (profile) => _ProfileContent(
        profile: profile,
        onFollowersTap: () => context.push('/profile/${profile.userId}/followers'),
        onFollowingTap: () => context.push('/profile/${profile.userId}/following'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              key: const Key('profile_blocked_list_button'),
              onPressed: () => context.push('/me/blocked'),
              child: const Text('Blocked users'),
            ),
            TextButton(
              key: const Key('profile_muted_list_button'),
              onPressed: () => context.push('/me/muted'),
              child: const Text('Muted users'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherProfileBody extends ConsumerWidget {
  const _OtherProfileBody({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider(userId));
    return profileState.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(profileNotifierProvider(userId)),
      ),
      data: (state) {
        final notifier = ref.read(profileNotifierProvider(userId).notifier);
        return _ProfileContent(
          profile: state.profile,
          onFollowersTap: () => context.push('/profile/$userId/followers'),
          onFollowingTap: () => context.push('/profile/$userId/following'),
          trailing: Wrap(
            spacing: 8,
            children: [
              FilledButton(
                key: const Key('profile_follow_button'),
                onPressed: notifier.toggleFollow,
                child: Text(state.isFollowing == true ? 'Unfollow' : 'Follow'),
              ),
              OutlinedButton(
                key: const Key('profile_block_button'),
                onPressed: notifier.toggleBlock,
                child: Text(state.isBlocked == true ? 'Unblock' : 'Block'),
              ),
              OutlinedButton(
                key: const Key('profile_mute_button'),
                onPressed: notifier.toggleMute,
                child: Text(state.isMuted == true ? 'Unmute' : 'Mute'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onFollowersTap,
    required this.onFollowingTap,
    required this.trailing,
  });

  final UserProfileModel profile;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage:
                profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
            child: profile.avatarUrl == null ? const Icon(Icons.person, size: 48) : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            key: const Key('profile_display_name'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(profile.bio!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountTile(
                key: const Key('profile_followers_count'),
                label: 'Followers',
                count: profile.followerCount,
                onTap: onFollowersTap,
              ),
              const SizedBox(width: 32),
              _CountTile(
                key: const Key('profile_following_count'),
                label: 'Following',
                count: profile.followingCount,
                onTap: onFollowingTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          trailing,
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    super.key,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text('$count', style: Theme.of(context).textTheme.titleMedium),
          Text(label),
        ],
      ),
    );
  }
}
