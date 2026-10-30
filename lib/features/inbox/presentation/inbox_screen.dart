import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';
import 'package:tiktok_mobile/features/notification/data/notification_model.dart';
import 'package:tiktok_mobile/features/notification/presentation/notification_provider.dart';

/// The activity list, from notification-service.
///
/// What actually arrives today is narrower than the tabs suggest: the service
/// only listens to `auth.user-events`, so a real account sees the welcome
/// notification and nothing else until consumers for likes, comments and
/// follows exist. The filters are written against the types the API already
/// defines, so they start working the moment those land.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

/// Label → the types it keeps. `null` is "everything".
const _filters = <String, Set<NotificationKind>?>{
  'All': null,
  'Likes': {NotificationKind.like},
  'Comments': {NotificationKind.comment},
  'Follows': {NotificationKind.newFollower},
};

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String _tab = 'All';

  Future<void> _markAllRead() async {
    try {
      await ref.read(inboxProvider.notifier).markAllRead();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Tapping a row clears its dot, and takes a follow notification to the
  /// follower's profile. The other types carry a videoId or a commentId in
  /// `referenceId` — opaque to the service and not yet produced by anything —
  /// so there is nothing to open without guessing which one it is.
  Future<void> _open(NotificationModel notification) async {
    if (notification.type == NotificationKind.newFollower &&
        notification.referenceId != null) {
      context.push('/profile/${notification.referenceId}');
    }
    try {
      await ref.read(inboxProvider.notifier).markRead(notification.id);
    } on AppException {
      // The row stays unread and the next tap retries; nothing to say.
    }
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(inboxProvider);
    final signedIn = ref.watch(authStateProvider).valueOrNull != null;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(inboxProvider),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 14,
          16,
          130,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Inbox', style: sora(size: 26, spacing: -0.6)),
              const SizedBox(width: 10),
              GestureDetector(
                key: const Key('inbox_open_messages'),
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/messages'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.send_outlined,
                      size: 18,
                      color: NowaColors.text.withValues(alpha: 0.7),
                    ),
                    if (ref.watch(unreadConversationsProvider) > 0)
                      Positioned(
                        key: const Key('inbox_messages_unread'),
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: NowaColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              if (inbox.valueOrNull?.any((n) => !n.read) ?? false)
                GestureDetector(
                  key: const Key('inbox_mark_all_read'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _markAllRead,
                  child: Text(
                    'Mark all read',
                    style: work(size: 12, height: 1, color: NowaColors.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final label in _filters.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip2(
                    label: label,
                    active: label == _tab,
                    onTap: () => setState(() => _tab = label),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (!signedIn)
            _Empty(
              message: 'Sign in to see your notifications',
              action: TextButton(
                onPressed: () => context.push('/login'),
                child: Text('Sign in',
                    style: work(size: 13, color: NowaColors.accent)),
              ),
            )
          else
            inbox.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: LoadingView(),
              ),
              error: (error, _) => ErrorView(message: error.toString()),
              data: (all) {
                final kinds = _filters[_tab];
                final rows = kinds == null
                    ? all
                    : [
                        for (final n in all)
                          if (kinds.contains(n.type)) n,
                      ];
                if (rows.isEmpty) {
                  return _Empty(
                    message: _tab == 'All'
                        ? 'Nothing here yet'
                        : 'No ${_tab.toLowerCase()} yet',
                  );
                }
                return Column(
                  children: [
                    for (final n in rows)
                      _Row(notification: n, onTap: () => _open(n)),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Text(
            message,
            style: work(size: 13, color: NowaColors.text.withValues(alpha: 0.45)),
          ),
          ?action,
        ],
      ),
    );
  }
}

const _badges = {
  NotificationKind.like: '♥',
  NotificationKind.comment: '💬',
  NotificationKind.share: '↗',
  NotificationKind.newFollower: '+',
  NotificationKind.system: '★',
};

class _Row extends StatelessWidget {
  const _Row({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final accent = n.type == NotificationKind.like ||
        n.type == NotificationKind.system;
    return GestureDetector(
      key: Key('inbox_row_${n.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const StripedPlaceholder(radius: 23, band: 5),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent ? NowaColors.accent : NowaColors.support,
                        shape: BoxShape.circle,
                        border: Border.all(color: NowaColors.bg, width: 2),
                      ),
                      child: Text(
                        _badges[n.type] ?? '★',
                        style: sora(size: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: sora(size: 13.5, height: 1.3)),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    style: work(
                      size: 12.5,
                      height: 1.4,
                      color: NowaColors.text.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              timeAgo(n.createdAt),
              style: work(
                size: 11,
                height: 1,
                color: NowaColors.text.withValues(alpha: 0.35),
              ),
            ),
            // The one thing the row has to say at a glance: read or not.
            if (!n.read) ...[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: NowaColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
