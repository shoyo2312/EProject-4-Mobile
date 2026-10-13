import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/notification/data/notification_model.dart';
import 'package:tiktok_mobile/features/notification/data/notification_remote_datasource.dart';
import 'package:tiktok_mobile/features/notification/data/notification_repository.dart';

part 'notification_provider.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) => NotificationRepository(
      NotificationRemoteDatasource(ref.watch(apiClientProvider)),
    );

/// The caller's inbox, newest first.
///
/// Signed out there is nothing to read — the endpoint would 401 — so a guest
/// gets an empty list rather than an error page behind the Inbox tab.
@riverpod
class Inbox extends _$Inbox {
  @override
  FutureOr<List<NotificationModel>> build() async {
    final me = await ref.watch(authStateProvider.future);
    if (me == null) return [];
    return ref.read(notificationRepositoryProvider).list();
  }

  /// Marks one row read, on screen first. The badge is recomputed from the
  /// server rather than decremented here: the same account may be reading the
  /// inbox on another device.
  Future<void> markRead(String id) async {
    final current = state.value ?? [];
    final index = current.indexWhere((n) => n.id == id);
    if (index == -1 || current[index].read) return;

    state = AsyncData([
      ...current.take(index),
      current[index].copyWith(read: true),
      ...current.skip(index + 1),
    ]);
    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
    } on AppException {
      state = AsyncData(current);
      rethrow;
    }
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllRead() async {
    final current = state.value ?? [];
    if (current.every((n) => n.read)) return;

    state = AsyncData([for (final n in current) n.copyWith(read: true)]);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
    } on AppException {
      state = AsyncData(current);
      rethrow;
    }
    ref.invalidate(unreadCountProvider);
  }
}

/// The nav bar badge. Its own request on purpose: the Inbox tab is not built
/// until it is opened, so reading the count off [Inbox] would mean pulling the
/// whole inbox down to draw a number.
@riverpod
class UnreadCount extends _$UnreadCount {
  @override
  FutureOr<int> build() async {
    final me = await ref.watch(authStateProvider.future);
    if (me == null) return 0;
    return ref.read(notificationRepositoryProvider).unreadCount();
  }
}
