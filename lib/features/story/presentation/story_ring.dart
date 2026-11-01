import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/features/story/presentation/story_flow.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';

/// The border that says "this person has a story": in colour while some of
/// it is unseen, grey once it has all been watched.
class StoryRingBorder extends StatelessWidget {
  const StoryRingBorder({
    super.key,
    required this.child,
    required this.radius,
    this.unseen = true,
    this.width = 2.5,
  });

  final Widget child;

  /// Corner radius of the [child]; the ring follows it.
  final double radius;
  final bool unseen;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(width),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + width * 2),
        gradient: unseen
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [NowaColors.accent, NowaColors.support],
              )
            : null,
        color: unseen ? null : Colors.white.withValues(alpha: 0.28),
      ),
      child: Container(
        padding: EdgeInsets.all(width * 0.6),
        decoration: BoxDecoration(
          color: NowaColors.bg,
          borderRadius: BorderRadius.circular(radius + width),
        ),
        child: child,
      ),
    );
  }
}

/// A profile avatar that shows the account's story ring and opens the
/// stories when tapped. With no ring it is just [child], and [onTapNoStory]
/// (if any) takes the tap.
class StoryRingAvatar extends ConsumerWidget {
  const StoryRingAvatar({
    super.key,
    required this.userId,
    required this.child,
    required this.radius,
    this.onTapNoStory,
  });

  final String userId;
  final Widget child;
  final double radius;
  final VoidCallback? onTapNoStory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A failed ring lookup is no reason to break the profile: no ring.
    final ring = ref.watch(storyRingProvider(userId)).valueOrNull;
    if (ring == null) {
      return GestureDetector(onTap: onTapNoStory, child: child);
    }
    return GestureDetector(
      key: const Key('story_ring_avatar'),
      onTap: () => openUserStories(context, ref, userId),
      child: StoryRingBorder(
        radius: radius,
        unseen: ring.hasUnseen,
        child: child,
      ),
    );
  }
}
