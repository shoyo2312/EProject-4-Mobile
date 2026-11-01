import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/presentation/story_flow.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_ring.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

const _avatarSize = 58.0;
const _avatarRadius = 21.0;

/// "Your story" first, then everyone followed who has something to watch.
/// Nothing at all while signed out — the tray is built from the follow list.
class StoryTrayRow extends ConsumerWidget {
  const StoryTrayRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    if (me == null) return const SizedBox.shrink();

    final tray = ref.watch(storyTrayProvider);
    final profiles = ref.watch(profileCacheProvider);
    final groups = tray.valueOrNull ?? const <StoryGroup>[];
    StoryGroup? own;
    final others = <StoryGroup>[];
    for (final g in groups) {
      g.userId == me.id ? own = g : others.add(g);
    }
    final myProfile =
        profiles[me.id] ?? ref.watch(myProfileProvider).valueOrNull;

    return SizedBox(
      height: 98,
      child: ListView.builder(
        key: const Key('story_tray'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: others.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final mine = own;
            return _Bubble(
              key: const Key('story_tray_mine'),
              avatarUrl: myProfile?.avatarUrl,
              label: 'Your story',
              // Grey while nothing of yours is live yet (under review).
              ring: mine?.stories.any((s) => s.status == StoryStatus.active),
              showAdd: true,
              onTap: mine == null
                  ? () => startStoryFlow(context)
                  : () => _open(context, ref, me.id, mine: true),
              onAdd: () => startStoryFlow(context),
            );
          }
          final group = others[index - 1];
          final profile = profiles[group.userId];
          return _Bubble(
            key: Key('story_tray_${group.userId}'),
            avatarUrl: profile?.avatarUrl,
            label: profile?.displayName ?? '…',
            ring: group.hasUnseen,
            onTap: () => _open(context, ref, me.id, userId: group.userId),
          );
        },
      ),
    );
  }
}

/// Plays from a fresh tray (signed URLs expire), starting at the bubble that
/// was tapped. Your own story plays alone; everyone else's play in a row.
Future<void> _open(
  BuildContext context,
  WidgetRef ref,
  String meId, {
  bool mine = false,
  String? userId,
}) async {
  final List<StoryGroup> groups;
  try {
    groups = await ref.read(storyTrayProvider.notifier).fresh();
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stories could not be loaded')),
      );
    }
    return;
  }
  if (!context.mounted) return;
  if (mine) {
    final own = groups.where((g) => g.userId == meId).toList();
    return openStoryViewer(context, own);
  }
  final others = groups.where((g) => g.userId != meId).toList();
  final start = others.indexWhere((g) => g.userId == userId);
  if (start < 0) return;
  return openStoryViewer(context, others, initialGroup: start);
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.avatarUrl,
    required this.label,
    required this.ring,
    required this.onTap,
    this.showAdd = false,
    this.onAdd,
  });

  final String? avatarUrl;
  final String label;

  /// Null: no ring at all. Otherwise whether it is in colour (unseen).
  final bool? ring;
  final VoidCallback onTap;
  final bool showAdd;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final avatar = NowaAvatar(
      url: avatarUrl,
      size: _avatarSize,
      radius: _avatarRadius,
      border: false,
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            SizedBox(
              width: _avatarSize + 10,
              height: _avatarSize + 10,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (ring == null)
                    avatar
                  else
                    StoryRingBorder(
                      radius: _avatarRadius,
                      unseen: ring!,
                      child: SizedBox(
                        width: _avatarSize - 6,
                        height: _avatarSize - 6,
                        child: NowaAvatar(
                          url: avatarUrl,
                          size: _avatarSize - 6,
                          radius: _avatarRadius - 3,
                          border: false,
                        ),
                      ),
                    ),
                  if (showAdd)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        key: const Key('story_tray_add'),
                        onTap: onAdd,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: NowaColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: NowaColors.bg, width: 2),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: work(size: 11.5, color: NowaColors.dim),
            ),
          ],
        ),
      ),
    );
  }
}
