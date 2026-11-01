import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/presentation/story_media_picker.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_viewer_screen.dart';

/// Pick → compose → share, from anywhere that offers "new story". Resolves
/// true once the story exists.
///
/// [source] skips the "gallery / photo / video" sheet when the caller already
/// knows (the camera's shutter, say).
Future<bool> startStoryFlow(
  BuildContext context, {
  StoryMediaSource? source,
  ImagePicker? picker,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final pick = source == null
      ? pickStoryDraft(context, picker: picker)
      : pickStoryDraftFrom(context, source, picker: picker);
  final draft = await pick;
  if (draft == null) return false;

  final posted = await router.push<bool>('/stories/new', extra: draft);
  if (posted != true) return false;
  messenger.showSnackBar(const SnackBar(
    content: Text(
      'Story shared — it appears after a quick review and lasts 24 hours',
    ),
  ));
  return true;
}

/// Opens the player on [groups], starting at [initialGroup].
Future<void> openStoryViewer(
  BuildContext context,
  List<StoryGroup> groups, {
  int initialGroup = 0,
}) async {
  if (groups.isEmpty) return;
  await GoRouter.of(context).push(
    '/stories/view',
    extra: StoryViewerArgs(groups: groups, initialGroup: initialGroup),
  );
}

/// One account's stories, fetched fresh — the signed URLs on a cached list
/// may have run out. Used by profile avatars.
Future<void> openUserStories(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final group = await ref.refresh(userStoryGroupProvider(userId).future);
    if (!context.mounted) return;
    if (group == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No stories to show right now')),
      );
      return;
    }
    await openStoryViewer(context, [group]);
  } on AppException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(storyErrorMessage(e))));
  } finally {
    // Watched stories turn the ring grey.
    if (context.mounted) ref.invalidate(storyRingProvider(userId));
  }
}
