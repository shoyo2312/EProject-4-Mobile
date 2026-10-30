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

/// The one chat socket. Opens on the first live stream and closes with the
/// last, so a signed-out app holds nothing open.
@Riverpod(keepAlive: true)
ChatSocket chatSocket(Ref ref) {
  final socket = ChatSocket(ref.watch(apiClientProvider).validAccessToken);
  ref.onDispose(socket.dispose);
  return socket;
}

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) => ChatRepository(
      ChatRemoteDatasource(ref.watch(apiClientProvider)),
      ref.watch(chatSocketProvider),
    );

/// The thread list, most recently active first, kept current over the socket.
///
/// Signed out there is nothing to list — every endpoint here needs a token —
/// so a guest gets an empty list rather than a 401 behind the screen.
@riverpod
class Conversations extends _$Conversations {
  @override
  FutureOr<List<ConversationModel>> build() async {
    final me = await ref.watch(authStateProvider.future);
    if (me == null) return [];
    final repository = ref.read(chatRepositoryProvider);

    // Listening before the fetch, so a message sent while the list loads is
    // not lost between the two.
    final live = repository.inboxEvents().listen((event) {
      switch (event.type) {
        case ChatEventType.message:
          _arrived(event.message!, me.id);
        case ChatEventType.conversation:
        case ChatEventType.conversationRemoved:
          // A request accepted, a thread deleted or a preview recalled: the
          // server's view of the row is what to show, so ask for it.
          ref.invalidateSelf();
        case ChatEventType.other:
          break;
      }
    });
    ref.onDispose(live.cancel);

    final rows = await repository.listConversations();
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

  /// A message in one of [me]'s threads: that row takes the message as its
  /// preview and moves to the top. A thread the list does not have yet —
  /// somebody writing for the first time — is fetched with the whole list,
  /// since a message alone does not say who the other participant is.
  void _arrived(MessageModel message, String me) {
    final rows = state.valueOrNull;
    if (rows == null) return;
    final index = rows.indexWhere((c) => c.id == message.conversationId);
    if (index < 0) {
      ref.invalidateSelf();
      return;
    }
    // An open thread marks itself read as messages land in it.
    final onScreen = ref.exists(threadProvider(message.conversationId));
    final row = rows[index];
    final updated = row.copyWith(
      lastMessageContent: message.content,
      lastMessageSenderId: message.senderId,
      lastMessageAt: message.sentAt,
      hasUnread: message.senderId != me && !onScreen,
    );
    state = AsyncData([
      updated,
      for (final c in rows)
        if (c.id != message.conversationId) c,
    ]);
  }

  /// The caller's own message, once the server has it. chat-service does not
  /// send a text message back to its sender's queue, so the list is moved
  /// from here instead.
  void sent(MessageModel message) {
    final me = ref.read(authStateProvider).valueOrNull?.id;
    if (me != null) _arrived(message, me);
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

    // Seen as it lands: otherwise the thread comes back unread the next time
    // the list is fetched, for a message that was read on arrival.
    final me = ref.read(authStateProvider).valueOrNull?.id;
    if (me != null && message.senderId != me) {
      ref
          .read(chatRepositoryProvider)
          .markRead(conversationId)
          .catchError((Object _) {});
    }
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
    if (ref.exists(conversationsProvider)) {
      ref.read(conversationsProvider.notifier).sent(message);
    }
  }
}

/// Threads with something the user has not read — the dot on the Inbox tab
/// and its Messages shortcut. Watching it keeps the conversation list, and so
/// the inbox socket, alive while the app is up.
@riverpod
int unreadConversations(Ref ref) =>
    ref
        .watch(conversationsProvider)
        .valueOrNull
        ?.where((c) => c.hasUnread)
        .length ??
    0;
