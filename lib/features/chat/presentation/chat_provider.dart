import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_remote_datasource.dart';
import 'package:tiktok_mobile/features/chat/data/chat_repository.dart';
import 'package:tiktok_mobile/features/chat/data/chat_socket.dart';
import 'package:tiktok_mobile/features/user/presentation/user_provider.dart';

part 'chat_provider.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) => ChatRepository(
      ChatRemoteDatasource(ref.watch(apiClientProvider)),
      ChatSocket(ref.watch(tokenStorageProvider)),
    );

/// The thread list, most recently active first.
///
/// Signed out there is nothing to list — every endpoint here needs a token —
/// so a guest gets an empty list rather than a 401 behind the screen.
@riverpod
class Conversations extends _$Conversations {
  @override
  FutureOr<List<ConversationModel>> build() async {
    final me = await ref.watch(authStateProvider.future);
    if (me == null) return [];
    final rows = await ref.read(chatRepositoryProvider).listConversations();
    // Resolve every name and avatar in one request instead of one per row.
    try {
      await ref
          .read(profileCacheProvider.notifier)
          .loadMissing(rows.map((c) => c.otherParticipant(me.id)));
    } on AppException {
      // A row with a placeholder avatar still reads fine.
    }
    return rows;
  }

  /// Opens (or reuses) the thread with [participantId] and returns its id.
  /// Asking twice answers the same conversation — the server keys it on the
  /// pair, not on who asked.
  Future<String> openWith(String participantId) async {
    final conversation =
        await ref.read(chatRepositoryProvider).openConversation(participantId);
    ref.invalidateSelf();
    return conversation.id;
  }
}

const _pageSize = 30;

/// One thread: a page of history, plus everything that arrives while it is on
/// screen.
///
/// Newest first, which is the order the server sorts in and the order the view
/// renders (a reversed list, so index 0 sits at the bottom).
@riverpod
class Thread extends _$Thread {
  String? _cursor;
  final _more = LoadMoreGuard();

  @override
  FutureOr<List<MessageModel>> build(String conversationId) async {
    final repository = ref.read(chatRepositoryProvider);

    // The socket carries the sender's own message back too, so every arrival
    // is de-duplicated by id rather than appended blindly.
    final subscription =
        repository.liveMessages(conversationId).listen(_receive);
    ref.onDispose(subscription.cancel);

    _cursor = null;
    final page = await repository.listMessages(conversationId, size: _pageSize);
    _more.done = !page.hasMore;
    _cursor = page.nextCursor;

    // Reading the thread is what clears its unread flag; failing to say so is
    // not worth an error on screen.
    try {
      await repository.markRead(conversationId);
      ref.invalidate(conversationsProvider);
    } on AppException {
      // ignore — see above
    }
    return page.items;
  }

  void _receive(MessageModel message) {
    final current = state.value;
    if (current == null || current.any((m) => m.id == message.id)) return;
    state = AsyncData([message, ...current]);
  }

  /// Older messages, one page at a time. A failed page keeps what is on screen
  /// and lets the next scroll retry.
  Future<void> loadMore() => _more.run(() async {
        final current = state.value ?? [];
        final page = await ref.read(chatRepositoryProvider).listMessages(
              conversationId,
              cursor: _cursor,
              size: _pageSize,
            );
        _more.done = !page.hasMore;
        _cursor = page.nextCursor;
        final seen = current.map((m) => m.id).toSet();
        state = AsyncData([
          ...current,
          ...page.items.where((m) => seen.add(m.id)),
        ]);
      });

  /// Sends, then lets the server's copy land. No optimistic row: the socket
  /// echoes the message back within the same round trip, and a temporary id
  /// would only have to be reconciled against the real one a moment later.
  Future<void> send(String content) async {
    final message =
        await ref.read(chatRepositoryProvider).sendMessage(conversationId, content);
    _receive(message);
    ref.invalidate(conversationsProvider);
  }
}
