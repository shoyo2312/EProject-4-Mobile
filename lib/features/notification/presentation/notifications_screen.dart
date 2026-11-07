import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/utils/time_ago.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_app_bar.dart';
import 'package:tiktok_mobile/features/notification/data/notification_model.dart';
import 'package:tiktok_mobile/features/notification/presentation/notification_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_flow.dart';

/// The activity list, from notification-service — opened from the "Activity"
/// entry at the top of the Inbox tab.
///
/// What actually arrives today is narrower than the tabs suggest: the service
/// only listens to `auth.user-events`, so a real account sees the welcome
/// notification and nothing else until consumers for likes, comments and
/// follows exist. The filters are written against the types the API already
/// defines, so they start working the moment those land.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

/// Label → the types it keeps. `null` is "everything".
const _filters = <String, Set<NotificationKind>?>{
  'All': null,
  'Likes': {NotificationKind.like},
  'Comments': {NotificationKind.comment},
  'Follows': {
    NotificationKind.newFollower,
    NotificationKind.followRequest,
    NotificationKind.followRequestAccepted,
  },
};

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _tab = 'All';

  Future<void> _markAllRead() async {
    try {
      await ref.read(inboxProvider.notifier).markAllRead();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Tapping a row clears its dot and opens what it is about: a follower's
  /// profile, a story owner's stories, or — for a comment or a reply, whose
  /// `referenceId` is the videoId — that video with its comments open.
  Future<void> _open(NotificationModel notification) async {
    if ((notification.type == NotificationKind.newFollower ||
            notification.type == NotificationKind.followRequestAccepted) &&
        notification.referenceId != null) {
      context.push('/profile/${notification.referenceId}');
    } else if (notification.type == NotificationKind.followRequest) {
      // The list, not the requester: it is the source of truth on what is
      // still waiting (user doc 3.16).
      context.push('/me/follow-requests');
    } else if (notification.type == NotificationKind.screenTime) {
      final week = notification.referenceId;
      context.push(
        week == null
            ? '/settings/screen-time/summary'
            : '/settings/screen-time/summary?week=$week',
      );
    } else if (notification.type == NotificationKind.story &&
        notification.referenceId != null) {
      // The owner's stories, fetched fresh: the one announced may have
      // expired, been deleted, or been joined by newer ones.
      unawaited(openUserStories(context, ref, notification.referenceId!));
    } else if (notification.type == NotificationKind.comment &&
        notification.referenceId != null) {
      context.push('/video/${notification.referenceId}?comments=1');
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
    final anyUnread = inbox.valueOrNull?.any((n) => !n.read) ?? false;

    return Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: NowaAppBar(
        title: 'Activity',
        actions: [
          if (anyUnread)
            TextButton(
              key: const Key('notifications_mark_all_read'),
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: work(size: 12, height: 1, color: NowaColors.accent),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(inboxProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              sliver: SliverToBoxAdapter(
                child: Row(
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
              ),
            ),
            ...inbox.when(
              loading: () => const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: LoadingView(),
                  ),
                ),
              ],
              error: (error, _) => [
                SliverToBoxAdapter(
                  child: ErrorView(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(inboxProvider),
                  ),
                ),
              ],
              data: (all) {
                final kinds = _filters[_tab];
                final rows = kinds == null
                    ? all
                    : [
                        for (final n in all)
                          if (kinds.contains(n.type)) n,
                      ];
                if (rows.isEmpty) {
                  return [
                    SliverToBoxAdapter(
                      child: _Empty(
                        message: _tab == 'All'
                            ? 'Nothing here yet'
                            : 'No ${_tab.toLowerCase()} yet',
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    sliver: SliverList.builder(
                      itemCount: rows.length,
                      itemBuilder: (_, i) => _Row(
                        notification: rows[i],
                        onTap: () => _open(rows[i]),
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          style: work(size: 13, color: NowaColors.text.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

const _badges = {
  NotificationKind.like: '♥',
  NotificationKind.comment: '💬',
  NotificationKind.share: '↗',
  NotificationKind.newFollower: '+',
  NotificationKind.story: '◎',
  NotificationKind.followRequest: '+',
  NotificationKind.followRequestAccepted: '✓',
  NotificationKind.screenTime: '◷',
  NotificationKind.system: '★',
};

class _Row extends StatelessWidget {
  const _Row({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final accent =
        n.type == NotificationKind.like || n.type == NotificationKind.system;
    return GestureDetector(
      key: Key('notification_row_${n.id}'),
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
