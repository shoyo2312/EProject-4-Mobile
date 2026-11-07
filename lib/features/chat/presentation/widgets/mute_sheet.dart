import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';

/// How long to mute a conversation for, or `null` if the sheet was dismissed.
/// Shared by the thread's menu and the long press on an Inbox row.
Future<MuteLength?> pickMuteLength(BuildContext context) {
  return showModalBottomSheet<MuteLength>(
    context: context,
    backgroundColor: NowaColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Mute notifications', style: sora(size: 14.5)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Messages still arrive. You just won\'t be alerted to them.',
              style: work(size: 12.5, color: NowaColors.dim),
            ),
          ),
          for (final length in MuteLength.values)
            ListTile(
              key: Key('chat_mute_${length.name}'),
              title: Text(length.label, style: work(size: 14)),
              onTap: () => Navigator.of(context).pop(length),
            ),
        ],
      ),
    ),
  );
}

/// "Muted until 14:30", or until turned back on, for a muted conversation.
String mutedLabel(ConversationModel conversation) {
  final until = conversation.mutedUntil?.toLocal();
  if (conversation.muteMode != MuteMode.timed || until == null) {
    return 'Muted until you turn it back on';
  }
  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(until.hour)}:${two(until.minute)}';
  final now = DateTime.now();
  final today =
      until.year == now.year &&
      until.month == now.month &&
      until.day == now.day;
  return today
      ? 'Muted until $time'
      : 'Muted until $time, ${until.day}/${until.month}';
}
