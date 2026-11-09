import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
);

/// The owner's menu for one of their own videos — pin, edit, delete. Opened
/// by a long-press, on the profile grid or on the video while it plays.
///
/// [onDeleted] runs after a delete went through, for a screen that has to
/// leave once its video is gone (the viewer, a deep link).
Future<void> showVideoManageMenu(
  BuildContext context,
  WidgetRef ref,
  VideoModel video, {
  VoidCallback? onDeleted,
}) async {
  final isPrivate = video.visibility == VideoVisibility.private;
  final pinned = video.pinnedAt != null;
  // video-service pins only a published video that is not private; one
  // already pinned can always be unpinned.
  final pinnable =
      pinned || (video.status == VideoStatus.published && !isPrivate);
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: NowaColors.surface,
    shape: _sheetShape,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (pinnable)
            _ManageTile(
              itemKey: const Key('manage_video_pin'),
              icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
              label: pinned ? 'Unpin' : 'Pin to top',
              onTap: () => Navigator.of(sheetContext).pop('pin'),
            ),
          _ManageTile(
            itemKey: const Key('manage_video_edit'),
            icon: Icons.edit_outlined,
            label: 'Edit video',
            onTap: () => Navigator.of(sheetContext).pop('edit'),
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

  switch (action) {
    case 'edit':
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: NowaColors.surface,
        shape: _sheetShape,
        builder: (_) => _EditVideoSheet(video: video),
      );
    case 'delete':
      await _confirmDelete(context, ref, video, onDeleted);
    case 'pin':
      final toast = NowaToast.of(context);
      try {
        await ref.read(videoEditorProvider).setPinned(video.id, !pinned);
        toast.success(
          pinned ? 'Unpinned' : 'Pinned to the top of your profile',
        );
      } on AppException catch (e) {
        toast.error(_errorText(e));
      }
  }
}

String _errorText(AppException e) {
  if (e is ServerException) {
    switch (e.code) {
      case 'PIN_LIMIT_REACHED':
        return 'You can pin up to 3 videos. Unpin one first.';
      case 'VIDEO_NOT_PINNABLE':
        return 'Only a published video that is not private can be pinned.';
    }
  }
  return e.message;
}

/// Deleting is a soft delete with no restore endpoint, and the gesture that
/// starts it is a long-press — easy to trigger by accident. Ask first.
Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  VideoModel video,
  VoidCallback? onDeleted,
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
  if (confirmed != true || !context.mounted) return;

  final toast = NowaToast.of(context);
  try {
    await ref.read(videoEditorProvider).delete(video);
    onDeleted?.call();
  } on AppException catch (e) {
    toast.error(e.message);
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

/// "Edit video": who can watch, and whether comments are on. Each change is
/// saved the moment it is made, and the sheet then shows the copy the server
/// answered with.
class _EditVideoSheet extends ConsumerStatefulWidget {
  const _EditVideoSheet({required this.video});

  final VideoModel video;

  @override
  ConsumerState<_EditVideoSheet> createState() => _EditVideoSheetState();
}

class _EditVideoSheetState extends ConsumerState<_EditVideoSheet> {
  static const _options = [
    (
      value: VideoVisibility.public,
      icon: Icons.public,
      label: 'Public',
      note: 'Everyone can watch',
    ),
    (
      value: VideoVisibility.friends,
      icon: Icons.people_outline,
      label: 'Friends',
      note: 'Followers you follow back',
    ),
    (
      value: VideoVisibility.private,
      icon: Icons.lock_outline,
      label: 'Private',
      note: 'Only you',
    ),
  ];

  late VideoModel _video = widget.video;
  bool _saving = false;

  Future<void> _run(
    Future<VideoModel> Function(VideoEditor editor) edit,
  ) async {
    if (_saving) return;
    final toast = NowaToast.of(context);
    setState(() => _saving = true);
    try {
      final updated = await edit(ref.read(videoEditorProvider));
      if (mounted) setState(() => _video = updated);
    } on AppException catch (e) {
      toast.error(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Edit video', style: sora(size: 16))),
                if (_saving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NowaColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionLabel('WHO CAN WATCH'),
            const SizedBox(height: 4),
            for (final option in _options)
              ListTile(
                key: Key('edit_video_visibility_${option.value.name}'),
                contentPadding: EdgeInsets.zero,
                enabled: !_saving,
                leading: Icon(option.icon, size: 20, color: NowaColors.text),
                title: Text(option.label, style: work(size: 14.5)),
                subtitle: Text(
                  option.note,
                  style: work(size: 12, color: NowaColors.dim),
                ),
                trailing: video.visibility == option.value
                    ? const Icon(Icons.check, color: NowaColors.accent)
                    : null,
                onTap: video.visibility == option.value
                    ? null
                    : () => _run((e) => e.setVisibility(video.id, option.value)),
              ),
            const SizedBox(height: 8),
            const SectionLabel('COMMENTS'),
            SwitchListTile(
              key: const Key('edit_video_comments'),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: NowaColors.accent,
              title: Text('Allow comments', style: work(size: 14.5)),
              subtitle: Text(
                'Turning this off stops new comments. Existing ones stay.',
                style: work(size: 12, color: NowaColors.dim),
              ),
              value: !video.commentsDisabled,
              onChanged: _saving
                  ? null
                  : (on) => _run((e) => e.setCommentsDisabled(video.id, !on)),
            ),
          ],
        ),
      ),
    );
  }
}
