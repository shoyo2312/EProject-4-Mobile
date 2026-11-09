import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/widgets/mute_sheet.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

enum _Action { pin, unpin, mute, unmute, block, profile }

const _pinLimitMessage =
    'You can pin up to ${ConversationModel.maxPins} conversations. '
    'Unpin one first.';

/// The long press on an Inbox row: pin (or unpin) the thread, mute (or
/// unmute) it, block the other person, or open their profile.
Future<void> showConversationActions(
  BuildContext context,
  WidgetRef ref, {
  required ConversationModel conversation,
  required String me,
}) async {
  final otherId = conversation.otherParticipant(me);
  final name =
      ref.read(profileCacheProvider)[otherId]?.displayName ?? 'this user';
  final muted = conversation.muted;
  final pinned = conversation.pinned;
  // Held now: every await below can outlive the row that was pressed.
  final toaster = NowaToast.of(context);
  void toast(String text, [ToastKind kind = ToastKind.error]) =>
      toaster.show(text, kind: kind);

  final action = await showModalBottomSheet<_Action>(
    context: context,
    backgroundColor: NowaColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sora(size: 14.5),
            ),
          ),
          ListTile(
            key: const Key('conversation_action_pin'),
            leading: Icon(
              pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: NowaColors.text,
            ),
            title: Text(pinned ? 'Unpin' : 'Pin to top', style: work(size: 14)),
            onTap: () =>
                Navigator.of(context).pop(pinned ? _Action.unpin : _Action.pin),
          ),
          ListTile(
            key: const Key('conversation_action_mute'),
            leading: Icon(
              muted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: NowaColors.text,
            ),
            title: Text(
              muted ? 'Unmute notifications' : 'Mute notifications',
              style: work(size: 14),
            ),
            subtitle: muted
                ? Text(
                    mutedLabel(conversation),
                    style: work(size: 12, color: NowaColors.dim),
                  )
                : null,
            onTap: () => Navigator.of(
              context,
            ).pop(muted ? _Action.unmute : _Action.mute),
          ),
          ListTile(
            key: const Key('conversation_action_profile'),
            leading: const Icon(Icons.person_outline, color: NowaColors.text),
            title: Text('View profile', style: work(size: 14)),
            onTap: () => Navigator.of(context).pop(_Action.profile),
          ),
          ListTile(
            key: const Key('conversation_action_block'),
            leading: const Icon(Icons.block, color: NowaColors.danger),
            title: Text(
              'Block',
              style: work(size: 14, color: NowaColors.danger),
            ),
            onTap: () => Navigator.of(context).pop(_Action.block),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _Action.profile:
      context.push('/profile/$otherId');
    case _Action.pin:
      // Full already: say so without a round trip the server would refuse.
      final rows = ref.read(conversationsProvider).valueOrNull ?? const [];
      if (rows.where((c) => c.pinned).length >= ConversationModel.maxPins) {
        toast(_pinLimitMessage, ToastKind.info);
        return;
      }
      try {
        await ref.read(conversationsProvider.notifier).pin(conversation.id);
        toast('Pinned to top', ToastKind.success);
      } on ServerException catch (e) {
        toast(e.code == 'PIN_LIMIT_REACHED' ? _pinLimitMessage : e.message);
      } on AppException catch (e) {
        toast(e.message);
      }
    case _Action.unpin:
      try {
        await ref.read(conversationsProvider.notifier).unpin(conversation.id);
        toast('Unpinned', ToastKind.success);
      } on AppException catch (e) {
        toast(e.message);
      }
    case _Action.mute:
      final length = await pickMuteLength(context);
      if (length == null) return;
      try {
        await ref
            .read(conversationsProvider.notifier)
            .mute(conversation.id, length);
        toast('Notifications muted', ToastKind.success);
      } on AppException catch (e) {
        toast(e.message);
      }
    case _Action.unmute:
      try {
        await ref.read(conversationsProvider.notifier).unmute(conversation.id);
        toast('Notifications turned on', ToastKind.success);
      } on AppException catch (e) {
        toast(e.message);
      }
    case _Action.block:
      if (!await _confirmBlock(context, name)) return;
      try {
        await ref.read(userRepositoryProvider).block(otherId);
      } on ServerException catch (e) {
        if (e.code != 'ALREADY_BLOCKED') {
          toast(e.message);
          return;
        }
      } on AppException catch (e) {
        toast(e.message);
        return;
      }
      // Whether the thread can still be written to depends on the block.
      ref.invalidate(conversationsProvider);
      ref.invalidate(profileNotifierProvider(otherId));
      toast('$name blocked', ToastKind.success);
  }
}

Future<bool> _confirmBlock(BuildContext context, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: NowaColors.surfaceHigh,
      title: Text('Block $name?', style: sora(size: 16)),
      content: Text(
        'They won\'t be able to message you. '
        'You can unblock them later from their profile.',
        style: work(size: 13, color: NowaColors.dim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Cancel', style: work(size: 14)),
        ),
        TextButton(
          key: const Key('conversation_block_confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Block', style: work(size: 14, color: NowaColors.danger)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
