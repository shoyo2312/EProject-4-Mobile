import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/video_viewer_screen.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/interaction/presentation/interaction_provider.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

/// Cover, avatar, stats, post grid — the design's profile page, filled from
/// user-service and video-service.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId, this.embedded = false});

  /// Null means "my own profile" (route `/profile`).
  final String? userId;

  /// True when the shell hosts this as a tab: no back button, and room is
  /// left at the bottom for the floating nav bar.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final isOwnProfile = userId == null || userId == me?.id;

    if (isOwnProfile && me == null) {
      return _SignedOut(embedded: embedded);
    }

    final body = isOwnProfile
        ? _MyProfileBody(handle: me?.username, embedded: embedded)
        : _OtherProfileBody(userId: userId!, embedded: embedded);

    if (embedded) return body;

    return Scaffold(
      backgroundColor: NowaColors.bg,
      body: Stack(
        children: [
          body,
          Positioned(
            left: 8,
            top: MediaQuery.of(context).padding.top + 6,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Glass(
                radius: 12,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut({required this.embedded});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 34,
              color: NowaColors.text.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 14),
            Text('Log in to see your profile', style: sora(size: 15)),
            const SizedBox(height: 18),
            SizedBox(
              width: 170,
              child: NowaButton(
                label: 'Log in',
                onTap: () => context.push('/login'),
              ),
            ),
          ],
        ),
      ),
    );
    return embedded
        ? content
        : Scaffold(backgroundColor: NowaColors.bg, body: content);
  }
}

class _MyProfileBody extends ConsumerWidget {
  const _MyProfileBody({required this.handle, required this.embedded});

  final String? handle;
  final bool embedded;

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
        handle: handle,
        isOwnProfile: true,
        embedded: embedded,
        onFollowersTap: () =>
            context.push('/profile/${profile.userId}/followers'),
        onFollowingTap: () =>
            context.push('/profile/${profile.userId}/following'),
        primaryAction: NowaButton(
          key: const Key('profile_edit_button'),
          label: 'Edit profile',
          onTap: () => context.push('/profile/edit'),
        ),
        iconActions: [
          _IconAction(
            buttonKey: const Key('profile_blocked_list_button'),
            icon: Icons.block,
            tooltip: 'Blocked users',
            onTap: () => context.push('/me/blocked'),
          ),
          _IconAction(
            buttonKey: const Key('profile_muted_list_button'),
            icon: Icons.volume_off_outlined,
            tooltip: 'Muted users',
            onTap: () => context.push('/me/muted'),
          ),
          _IconAction(
            buttonKey: const Key('profile_logout_button'),
            icon: Icons.logout,
            tooltip: 'Log out',
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _OtherProfileBody extends ConsumerWidget {
  const _OtherProfileBody({required this.userId, required this.embedded});

  final String userId;
  final bool embedded;

  /// Opens the thread with this person, creating it on the server if this is
  /// the first message. The id comes back from the server rather than being
  /// guessed: two people have exactly one conversation, and which document it
  /// is was decided the first time either of them tapped this.
  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conversationId =
          await ref.read(conversationsProvider.notifier).openWith(userId);
      if (context.mounted) context.push('/messages/$conversationId');
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

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
        final following = state.isFollowing == true;
        return _ProfileContent(
          profile: state.profile,
          isOwnProfile: false,
          embedded: embedded,
          onFollowersTap: () => context.push('/profile/$userId/followers'),
          onFollowingTap: () => context.push('/profile/$userId/following'),
          primaryAction: NowaButton(
            key: const Key('profile_follow_button'),
            label: following ? 'Following' : 'Follow',
            filled: !following,
            onTap: notifier.toggleFollow,
          ),
          iconActions: [
            _IconAction(
              buttonKey: const Key('profile_message_button'),
              icon: Icons.send_outlined,
              tooltip: 'Message',
              onTap: () => _openChat(context, ref),
            ),
            _IconAction(
              buttonKey: const Key('profile_block_button'),
              icon: Icons.block,
              tooltip: state.isBlocked == true ? 'Unblock' : 'Block',
              active: state.isBlocked == true,
              onTap: notifier.toggleBlock,
            ),
            _IconAction(
              buttonKey: const Key('profile_mute_button'),
              icon: Icons.volume_off_outlined,
              tooltip: state.isMuted == true ? 'Unmute' : 'Mute',
              active: state.isMuted == true,
              onTap: notifier.toggleMute,
            ),
          ],
        );
      },
    );
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent({
    required this.profile,
    required this.isOwnProfile,
    required this.embedded,
    required this.onFollowersTap,
    required this.onFollowingTap,
    required this.primaryAction,
    required this.iconActions,
    this.handle,
  });

  final UserProfileModel profile;
  final bool isOwnProfile;
  final bool embedded;
  final String? handle;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;
  final Widget primaryAction;
  final List<Widget> iconActions;

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  String _tab = 'Posts';

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // No cover-image field in UserProfileResponse — the striped
              // frame from the design stands in for it.
              const StripedPlaceholder(label: 'cover image', fontSize: 11),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [NowaColors.bg, Color(0x1A0B0A0D)],
                    stops: [0, 0.7],
                  ),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -46),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, widget.embedded ? 130 : 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: NowaColors.bg, width: 2),
                      ),
                      child: RemoteImage(
                        url: profile.avatarUrl,
                        radius: 28,
                        band: 6,
                        label: 'pfp',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              key: const Key('profile_display_name'),
                              style: sora(size: 19, spacing: -0.4),
                            ),
                            if (widget.handle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                '@${widget.handle}',
                                style: work(
                                  size: 12.5,
                                  height: 1.2,
                                  color: NowaColors.text.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  profile.bio?.isNotEmpty == true ? profile.bio! : 'No bio yet',
                  style: work(
                    size: 13,
                    height: 1.6,
                    color: NowaColors.text.withValues(
                      alpha: profile.bio?.isNotEmpty == true ? 0.7 : 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(
                      key: const Key('profile_following_count'),
                      value: compact(profile.followingCount),
                      label: 'Following',
                      onTap: widget.onFollowingTap,
                    ),
                    const SizedBox(width: 26),
                    _Stat(
                      key: const Key('profile_followers_count'),
                      value: compact(profile.followerCount),
                      label: 'Followers',
                      onTap: widget.onFollowersTap,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: widget.primaryAction),
                    for (final action in widget.iconActions) ...[
                      const SizedBox(width: 9),
                      action,
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (final t in ['Posts', 'Liked', 'Saved']) ...[
                      Chip2(
                        label: t,
                        active: t == _tab,
                        onTap: () => setState(() => _tab = t),
                        expand: true,
                      ),
                      if (t != 'Saved') const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (_tab == 'Posts')
                  _UserVideosGrid(
                    userId: profile.userId,
                    isOwnProfile: widget.isOwnProfile,
                  )
                // Likes and saves are private: interaction-service only ever
                // answers for "me", so there is nothing to show on someone
                // else's profile — not an empty list, no endpoint at all.
                else if (!widget.isOwnProfile)
                  _PrivateTab(tab: _tab)
                else
                  _HistoryVideosGrid(
                    history: _tab == 'Liked'
                        ? VideoHistory.liked
                        : VideoHistory.saved,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivateTab extends StatelessWidget {
  const _PrivateTab({required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          '$tab videos are private',
          style: work(size: 13, color: NowaColors.text.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

/// The caller's own Liked or Saved tab. Two hops behind it — ids from
/// interaction-service, videos from video-service — which is why a row can be
/// missing from a page: the video was deleted after it was liked.
class _HistoryVideosGrid extends ConsumerWidget {
  const _HistoryVideosGrid({required this.history});

  final VideoHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = historyVideosNotifierProvider(history);
    return ref.watch(provider).when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: LoadingView(),
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(provider),
          ),
          data: (videos) => videos.isEmpty
              ? const _EmptyVideos()
              : _VideoGrid(
                  videos: videos,
                  // Deleting is the owner's gesture on their own posts, not on
                  // a list of other people's videos they happened to like.
                  onLongPress: null,
                ),
        );
  }
}

/// The three-across thumbnail grid shared by every profile tab. Never scrolls
/// itself — it always sits inside the profile's own ListView.
class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.videos, required this.onLongPress});

  final List<VideoModel> videos;
  final void Function(VideoModel video)? onLongPress;

  /// Opens the tapped clip in the full-screen viewer. Only PUBLISHED videos
  /// carry an hlsUrl — the owner's own grid also holds PROCESSING/FAILED ones,
  /// which have nothing to play, so they are skipped here and in the swipe
  /// list behind them.
  void _openViewer(BuildContext context, VideoModel tapped) {
    final playable = videos.where((v) => v.hlsUrl != null).toList();
    final index = playable.indexWhere((v) => v.id == tapped.id);
    if (index == -1) return;
    VideoViewerScreen.open(context, videos: playable, initialIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 9 / 13,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return GestureDetector(
          key: Key('profile_video_${video.id}'),
          onTap: () => _openViewer(context, video),
          onLongPress:
              onLongPress == null ? null : () => onLongPress!(video),
          child: _VideoThumbnail(video: video),
        );
      },
    );
  }
}

/// `GET /videos/users/{userId}`. For your own id the server also returns
/// PROCESSING, PRIVATE, FAILED and TAKEN_DOWN videos — but only when the
/// token is sent; without it the response silently degrades to the public
/// view (video doc 3.4).
class _UserVideosGrid extends ConsumerWidget {
  const _UserVideosGrid({required this.userId, required this.isOwnProfile});

  final String userId;
  final bool isOwnProfile;

  /// The owner's menu for one of their own videos. Long-press rather than a
  /// visible button: the grid is three across and a per-tile overflow icon at
  /// that size is a mis-tap waiting to happen.
  Future<void> _openManageSheet(
    BuildContext context,
    WidgetRef ref,
    VideoModel video,
  ) async {
    final isPrivate = video.visibility == VideoVisibility.private;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NowaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _ManageTile(
              itemKey: const Key('manage_video_visibility'),
              icon: isPrivate ? Icons.public : Icons.lock_outline,
              label: isPrivate ? 'Make public' : 'Make private',
              onTap: () => Navigator.of(sheetContext).pop('visibility'),
            ),
            _ManageTile(
              itemKey: const Key('manage_video_comments'),
              icon: video.commentsDisabled
                  ? Icons.mode_comment_outlined
                  : Icons.comments_disabled_outlined,
              label: video.commentsDisabled
                  ? 'Turn comments on'
                  : 'Turn comments off',
              onTap: () => Navigator.of(sheetContext).pop('comments'),
            ),
            _ManageTile(
              itemKey: const Key('manage_video_delete'),
              icon: Icons.delete_outline,
              label: 'Delete',
              danger: true,
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    if (action == 'delete') {
      await _confirmDelete(context, ref, video);
      return;
    }
    final notifier = ref.read(userVideosNotifierProvider(userId).notifier);
    try {
      if (action == 'visibility') {
        await notifier.setVisibility(
          video.id,
          isPrivate ? VideoVisibility.public : VideoVisibility.private,
        );
      } else {
        await notifier.setCommentsDisabled(video.id, !video.commentsDisabled);
      }
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Deleting is a soft delete with no restore endpoint, and the gesture that
  /// starts it is a long-press on a scrolling grid — easy to trigger by
  /// accident. Ask first.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VideoModel video,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NowaColors.surfaceHigh,
        title: Text('Delete this video?', style: sora(size: 16)),
        content: Text(
          'It disappears everywhere and cannot be restored.',
          style: work(size: 13, color: NowaColors.dim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: work(size: 14, color: NowaColors.dim)),
          ),
          TextButton(
            key: const Key('confirm_delete_video'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: work(size: 14, color: NowaColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(userVideosNotifierProvider(userId).notifier)
          .delete(video.id);
    } on AppException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(userVideosNotifierProvider(userId));
    return videosState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: LoadingView(),
      ),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(userVideosNotifierProvider(userId)),
      ),
      data: (videos) => videos.isEmpty
          ? const _EmptyVideos()
          : _VideoGrid(
              videos: videos,
              // Only the owner may edit or delete their own videos.
              onLongPress: isOwnProfile
                  ? (video) => _openManageSheet(context, ref, video)
                  : null,
            ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.itemKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final Key itemKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? NowaColors.danger : NowaColors.text;
    return ListTile(
      key: itemKey,
      onTap: onTap,
      leading: Icon(icon, size: 20, color: color),
      title: Text(label, style: work(size: 14.5, color: color)),
    );
  }
}

class _EmptyVideos extends StatelessWidget {
  const _EmptyVideos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 34,
              color: NowaColors.text.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 14),
            Text('No videos yet', style: sora(size: 15)),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RemoteImage(url: video.thumbnailUrl, band: 6),
          // Anything other than PUBLISHED is visible to the owner only, so
          // labelling it explains why it can't be played.
          if (video.status != VideoStatus.published)
            ColoredBox(
              color: Colors.black45,
              child: Center(
                child: Text(switch (video.status) {
                  VideoStatus.processing => 'Processing',
                  VideoStatus.failed => 'Failed',
                  VideoStatus.takenDown => 'Taken down',
                  _ => '',
                }, style: sora(size: 10, weight: FontWeight.w500)),
              ),
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    compact(video.viewCount),
                    style: sora(size: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          if (video.visibility == VideoVisibility.private)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.lock, size: 13, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: sora(size: 17)),
          const SizedBox(height: 2),
          Text(
            label,
            style: work(
              size: 11.5,
              height: 1,
              color: NowaColors.text.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        key: buttonKey,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? NowaColors.accent.withValues(alpha: 0.18)
                : const Color(0xFF1A171F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? NowaColors.accent
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? NowaColors.accent : Colors.white,
          ),
        ),
      ),
    );
  }
}
