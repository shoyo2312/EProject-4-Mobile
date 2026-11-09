import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/utils/paging.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_remote_datasource.dart';
import 'package:tiktok_mobile/features/chat/data/chat_repository.dart';
import 'package:tiktok_mobile/features/chat/data/chat_socket.dart';
import 'package:tiktok_mobile/features/chat/presentation/typing_sender.dart';
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
        case ChatEventType.messageUpdated:
        case ChatEventType.messageHidden:
        case ChatEventType.receipt:
        case ChatEventType.typing:
        case ChatEventType.other:
          // An open thread applies these itself; a preview one of them
          // changes arrives as a CONVERSATION frame of its own.
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
    if (message.senderId != me) {
      // This device now holds it: the sender's "Delivered". An open thread
      // goes on to mark it read when it is actually on screen.
      ref
          .read(chatRepositoryProvider)
          .markDelivered(message.conversationId, [message.id])
          .catchError((Object _) {});
    }
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
    var updated = row.copyWith(
      lastMessageContent: message.previewText,
      lastMessageSenderId: message.senderId,
      lastMessageAt: message.sentAt,
      hasUnread: message.senderId != me && !onScreen,
    );
    // A request's one message spent, or a deleted request written into.
    if (message.senderId == me) {
      updated = updated.afterOwnMessage(message.sentAt);
    }
    // The server's order: an unpinned thread moves to the top of the
    // unpinned ones, a pinned one keeps its place among the pins.
    state = AsyncData(
      [
        for (final c in rows) c.id == message.conversationId ? updated : c,
      ]..sort(ConversationModel.compare),
    );
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
    final conversation = await ref
        .read(chatRepositoryProvider)
        .openConversation(participantId);
    ref.invalidateSelf();
    return conversation.id;
  }

  /// Silences new-message alerts from one thread, for the caller only. The
  /// thread keeps updating as before; it just stops counting towards the
  /// unread badge.
  Future<void> mute(String conversationId, MuteLength length) async {
    _replace(
      await ref.read(chatRepositoryProvider).mute(conversationId, length),
    );
  }

  Future<void> unmute(String conversationId) async {
    _replace(await ref.read(chatRepositoryProvider).unmute(conversationId));
  }

  /// Pins a thread above the others, the newest pin on top. Past
  /// [ConversationModel.maxPins] the server refuses with
  /// `PIN_LIMIT_REACHED` and nothing is unpinned on the caller's behalf.
  Future<void> pin(String conversationId) async {
    _replace(await ref.read(chatRepositoryProvider).pin(conversationId));
  }

  Future<void> unpin(String conversationId) async {
    _replace(await ref.read(chatRepositoryProvider).unpin(conversationId));
  }

  /// The server's copy of one row, put where the server's order places it —
  /// a pin or an unpin moves the row; a mute leaves it where it is.
  void _replace(ConversationModel conversation) {
    final rows = state.valueOrNull;
    if (rows == null) return;
    if (!rows.any((c) => c.id == conversation.id)) {
      // A message request, muted from inside it: that box shows it.
      ref.invalidate(messageRequestsProvider);
      return;
    }
    state = AsyncData(
      [
        for (final c in rows) c.id == conversation.id ? conversation : c,
      ]..sort(ConversationModel.compare),
    );
  }
}

/// Message requests waiting on the caller: threads opened by people they do
/// not follow back, each holding the one message its sender was allowed. Not
/// part of [Conversations] until accepted; opening one reads it but does not
/// answer it.
@riverpod
class MessageRequests extends _$MessageRequests {
  @override
  FutureOr<List<ConversationModel>> build() async {
    final me = await ref.watch(authStateProvider.future);
    if (me == null) return [];
    final repository = ref.read(chatRepositoryProvider);

    final live = repository.inboxEvents().listen((event) {
      switch (event.type) {
        case ChatEventType.message:
          _arrived(event.message!, me.id);
        case ChatEventType.conversation:
        case ChatEventType.conversationRemoved:
          // A request arrived, was answered elsewhere, or its sender's
          // allowance came back.
          ref.invalidateSelf();
        case ChatEventType.messageUpdated:
        case ChatEventType.messageHidden:
        case ChatEventType.receipt:
        case ChatEventType.typing:
        case ChatEventType.other:
          break;
      }
    });
    ref.onDispose(live.cancel);

    final rows = await repository.listRequests();
    try {
      await ref
          .read(profileCacheProvider.notifier)
          .loadMissing(rows.map((c) => c.otherParticipant(me.id)));
    } on AppException {
      // A row with a placeholder avatar still reads fine.
    }
    return rows;
  }

  /// A message from someone: a request's row takes it as its preview. One in
  /// a thread neither list has is probably a new request, so the box is
  /// fetched again; one in an ordinary thread is none of its business.
  void _arrived(MessageModel message, String me) {
    if (message.senderId == me) return;
    final rows = state.valueOrNull;
    if (rows == null) return;
    final index = rows.indexWhere((c) => c.id == message.conversationId);
    if (index < 0) {
      final inbox = ref.read(conversationsProvider).valueOrNull;
      if (inbox == null || !inbox.any((c) => c.id == message.conversationId)) {
        ref.invalidateSelf();
      }
      return;
    }
    final onScreen = ref.exists(threadProvider(message.conversationId));
    final updated = rows[index].copyWith(
      lastMessageContent: message.previewText,
      lastMessageSenderId: message.senderId,
      lastMessageAt: message.sentAt,
      hasUnread: !onScreen,
    );
    state = AsyncData([
      updated,
      for (final c in rows)
        if (c.id != message.conversationId) c,
    ]);
  }

  /// The caller opened it: no longer new, still waiting for an answer.
  void opened(String conversationId) {
    final rows = state.valueOrNull;
    if (rows == null) return;
    state = AsyncData([
      for (final c in rows)
        c.id == conversationId ? c.copyWith(hasUnread: false) : c,
    ]);
  }

  /// Turns the request into an ordinary conversation, which moves to the
  /// inbox. Answers it as the caller now sees it.
  Future<ConversationModel> accept(String conversationId) async {
    final accepted = await ref
        .read(chatRepositoryProvider)
        .acceptRequest(conversationId);
    _remove(conversationId);
    ref.invalidate(conversationsProvider);
    return accepted;
  }

  /// Removes the request from the box. Its sender is not told and cannot
  /// write again until their wait is over.
  Future<void> decline(String conversationId) async {
    await ref.read(chatRepositoryProvider).declineRequest(conversationId);
    _remove(conversationId);
  }

  void _remove(String conversationId) {
    final rows = state.valueOrNull;
    if (rows == null) return;
    state = AsyncData([
      for (final c in rows)
        if (c.id != conversationId) c,
    ]);
  }
}

/// How many requests wait on the caller ([pending]) and how many of those
/// they have not opened yet ([unread]). Neither counts messages. A muted
/// request still waits, but does not count as unread.
typedef RequestCounts = ({int pending, int unread});

@riverpod
RequestCounts requestCounts(Ref ref) {
  final rows = ref.watch(messageRequestsProvider).valueOrNull ?? const [];
  return (
    pending: rows.length,
    unread: rows.where((c) => c.hasUnread && !c.muted).length,
  );
}

/// One conversation as the caller sees it, for the thread screen: its header,
/// its menu and what stands where the composer goes. Taken from the inbox or
/// the request box when either has it, so the three agree; fetched otherwise
/// (a request the caller deleted is in neither).
@riverpod
class ConversationDetail extends _$ConversationDetail {
  @override
  FutureOr<ConversationModel?> build(String conversationId) async {
    ConversationModel? find(List<ConversationModel>? rows) =>
        rows?.where((c) => c.id == conversationId).firstOrNull;
    final known =
        find(ref.watch(conversationsProvider).valueOrNull) ??
        find(ref.watch(messageRequestsProvider).valueOrNull);
    if (known != null) return known;
    try {
      final fetched = await ref
          .read(chatRepositoryProvider)
          .getConversation(conversationId);
      // Neither list loaded this person, so their name comes from here.
      final me = ref.read(authStateProvider).valueOrNull?.id;
      if (me != null) {
        try {
          await ref
              .read(profileCacheProvider.notifier)
              .loadMissing([fetched.otherParticipant(me)]);
        } on AppException {
          // The header says "Messages" until it is known.
        }
      }
      return fetched;
    } on AppException {
      // The thread still works; it just draws an ordinary composer.
      return null;
    }
  }

  /// The caller's own message is in: a request's one message is spent, or a
  /// deleted request is open again. The server agrees once it is asked.
  void ownMessageSent(MessageModel message) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.afterOwnMessage(message.sentAt));
  }

  /// The server's answer to something done here (an accept), shown at once.
  void show(ConversationModel conversation) =>
      state = AsyncData(conversation);
}

/// The server refused a send because the request changed under the caller —
/// accepted or deleted elsewhere, or the one message already used. Its view
/// of the conversation is fetched again rather than trusting the screen's.
void _recheckPermission(Ref ref, String conversationId, AppException e) {
  const changed = {
    'MESSAGE_REQUEST_LIMIT_REACHED',
    'MESSAGE_REQUEST_NOT_ACCEPTED',
    'MESSAGE_REQUEST_NOT_PENDING',
  };
  if (e is! ServerException || !changed.contains(e.code)) return;
  ref.invalidate(conversationsProvider);
  ref.invalidate(conversationDetailProvider(conversationId));
}

/// The server's refusals around message requests, in words.
String? requestErrorMessage(AppException e) =>
    switch (e is ServerException ? e.code : null) {
      'MESSAGE_REQUEST_LIMIT_REACHED' =>
        'You can send more messages once this request is accepted',
      'MESSAGE_REQUEST_NOT_ACCEPTED' =>
        'Accept this message request before replying',
      'NOT_REQUEST_RECIPIENT' =>
        'Only the person who received this request can answer it',
      'MESSAGE_REQUEST_NOT_PENDING' => 'This request has already been answered',
      _ => null,
    };

const _pageSize = 30;

/// The id a message has while it is still on its way: never one the server
/// would hand out, so it cannot collide with a real one.
String _localId(String clientRequestId) => 'local-$clientRequestId';

/// One thread: a page of history, plus everything that arrives while it is on
/// screen.
///
/// Newest first, which is the order the server sorts in and the order the view
/// renders (a reversed list, so index 0 sits at the bottom).
@riverpod
class Thread extends _$Thread {
  String? _cursor;
  final _more = LoadMoreGuard();

  /// Whether the app is in front of the user. A message that arrives while it
  /// is not is only delivered; it is marked read when the user comes back.
  bool _foreground = true;
  String? _unseen;

  @override
  FutureOr<List<MessageModel>> build(String conversationId) async {
    final repository = ref.read(chatRepositoryProvider);

    // The socket carries the sender's own message back too, so every arrival
    // is de-duplicated by id rather than appended blindly.
    final subscription = repository
        .liveMessages(conversationId)
        .listen(_receive);
    ref.onDispose(subscription.cancel);

    // Recalls, and messages deleted for the caller on another device.
    final events = repository
        .inboxEvents()
        .where((e) => e.conversationId == conversationId)
        .listen(_onEvent);
    ref.onDispose(events.cancel);

    _cursor = null;
    final page = await repository.listMessages(conversationId, size: _pageSize);
    _more.done = !page.hasMore;
    _cursor = page.nextCursor;

    // Reading the thread is what clears its unread flag; failing to say so is
    // not worth an error on screen.
    try {
      await repository.markRead(conversationId);
      ref.invalidate(conversationsProvider);
      // Reading a request is not answering it: it only stops being new.
      if (ref.exists(messageRequestsProvider)) {
        ref.read(messageRequestsProvider.notifier).opened(conversationId);
      }
    } on AppException {
      // ignore — see above
    }
    return page.items;
  }

  void _onEvent(ChatInboxEvent event) {
    switch (event.type) {
      case ChatEventType.messageUpdated:
        _apply(event.update!);
      case ChatEventType.messageHidden:
        _drop(event.messageId!);
      default:
        break;
    }
  }

  void _receive(MessageModel message) {
    final current = state.value;
    if (current == null || current.any((m) => m.id == message.id)) return;
    final me = ref.read(authStateProvider).valueOrNull?.id;
    final mine = me != null && message.senderId == me;

    // The caller's own message, echoed by the socket before its send
    // answered: it takes the place of the row drawn for it while it went.
    final placeholder = mine ? _pendingFor(current, message) : -1;
    if (placeholder < 0) {
      state = AsyncData([message, ...current]);
    } else {
      state = AsyncData([...current]..[placeholder] = message);
    }

    // Seen as it lands: otherwise the thread comes back unread the next time
    // the list is fetched, for a message that was read on arrival.
    if (me != null && !mine) _seen(message.id);
  }

  /// The oldest row still on its way that [message] is the server's copy of.
  static int _pendingFor(List<MessageModel> rows, MessageModel message) {
    for (var i = rows.length - 1; i >= 0; i--) {
      final row = rows[i];
      if (row.pending &&
          row.type == message.type &&
          row.content == message.content &&
          row.sticker?.stickerId == message.sticker?.stickerId) {
        return i;
      }
    }
    return -1;
  }

  void _seen(String messageId) {
    if (!_foreground) {
      _unseen = messageId;
      return;
    }
    ref
        .read(chatRepositoryProvider)
        .markRead(conversationId, messageId: messageId)
        .catchError((Object _) {});
  }

  /// Told by the screen when the app goes to the background and comes back.
  /// What arrived in between is marked read only now, when it can be seen.
  void setForeground(bool foreground) {
    _foreground = foreground;
    final unseen = _unseen;
    if (!foreground || unseen == null) return;
    _unseen = null;
    _seen(unseen);
  }

  /// Older messages, one page at a time. A failed page keeps what is on screen
  /// and lets the next scroll retry.
  Future<void> loadMore() => _more.run(() async {
    final current = state.value ?? [];
    final page = await ref
        .read(chatRepositoryProvider)
        .listMessages(conversationId, cursor: _cursor, size: _pageSize);
    _more.done = !page.hasMore;
    _cursor = page.nextCursor;
    final seen = current.map((m) => m.id).toSet();
    state = AsyncData([...current, ...page.items.where((m) => seen.add(m.id))]);
  });

  /// Draws the message at once, marked as sending, then swaps in the server's
  /// copy. A failed send takes the row away again and rethrows, so the
  /// composer can put the text back.
  Future<void> send(String content) => _sendWith(
    (requestId) => MessageModel(
      id: _localId(requestId),
      conversationId: conversationId,
      senderId: _me ?? '',
      content: content,
      sentAt: DateTime.now(),
      pending: true,
    ),
    (repository, requestId) => repository.sendMessage(
      conversationId,
      content,
      clientRequestId: requestId,
    ),
  );

  /// A sticker is a message of its own; the draft in the composer is left as
  /// it was.
  Future<void> sendSticker(StickerModel sticker) => _sendWith(
    (requestId) => MessageModel(
      id: _localId(requestId),
      conversationId: conversationId,
      senderId: _me ?? '',
      // What the server's copy of a sticker carries as its text.
      content: 'Sticker',
      sentAt: DateTime.now(),
      type: MessageType.sticker,
      sticker: sticker,
      pending: true,
    ),
    (repository, requestId) => repository.sendSticker(
      conversationId,
      sticker.stickerId,
      clientRequestId: requestId,
    ),
  );

  String? get _me => ref.read(authStateProvider).valueOrNull?.id;

  Future<void> _sendWith(
    MessageModel Function(String requestId) draft,
    Future<MessageModel> Function(ChatRepository, String requestId) post,
  ) async {
    final requestId = newClientRequestId();
    final current = state.value;
    if (current != null) state = AsyncData([draft(requestId), ...current]);
    try {
      final message = await post(ref.read(chatRepositoryProvider), requestId);
      _settle(_localId(requestId), message);
    } catch (e) {
      _drop(_localId(requestId));
      if (e is AppException) _recheckPermission(ref, conversationId, e);
      rethrow;
    }
  }

  /// The server's copy of a row drawn while it was sending: in that row's
  /// place, unless the socket already brought it.
  void _settle(String localId, MessageModel message) {
    final current = state.value ?? const <MessageModel>[];
    final at = current.indexWhere((m) => m.id == localId);
    final arrived = current.any((m) => m.id == message.id);
    if (at < 0) {
      if (!arrived) _receive(message);
    } else {
      state = AsyncData(
        arrived ? ([...current]..removeAt(at)) : ([...current]..[at] = message),
      );
    }
    _ownSent(message);
  }

  /// The caller's own message, as the server stored it: into the thread, and
  /// to the top of the conversation list.
  void delivered(MessageModel message) {
    _receive(message);
    _ownSent(message);
  }

  /// What the caller sending something changes outside the thread: the list's
  /// preview, and what the composer may do next (a request's one message is
  /// now spent).
  void _ownSent(MessageModel message) {
    if (ref.exists(conversationsProvider)) {
      ref.read(conversationsProvider.notifier).sent(message);
    }
    final detail = conversationDetailProvider(conversationId);
    if (ref.exists(detail)) {
      ref.read(detail.notifier).ownMessageSent(message);
    }
  }

  /// Takes one of the caller's messages back for everyone. Once the other
  /// side has read it the server refuses (`MESSAGE_ALREADY_SEEN`); their
  /// marks are then fetched again, so the menu stops offering it.
  Future<void> recall(String messageId) async {
    try {
      _apply(
        await ref
            .read(chatRepositoryProvider)
            .recall(conversationId, messageId),
      );
    } on ServerException catch (e) {
      if (e.code == 'MESSAGE_ALREADY_SEEN') {
        ref.invalidate(peerReceiptProvider(conversationId));
      }
      rethrow;
    }
  }

  /// Deletes a message from the caller's side only.
  Future<void> hide(String messageId) async {
    final newest = state.value?.firstOrNull?.id == messageId;
    await ref.read(chatRepositoryProvider).hide(conversationId, messageId);
    _drop(messageId);
    // The preview in the list was that message; the server's says what now.
    if (newest) ref.invalidate(conversationsProvider);
  }

  void _apply(MessageUpdate update) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final m in current)
        m.id == update.messageId ? m.applying(update) : m,
    ]);
  }

  void _drop(String messageId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final m in current)
        if (m.id != messageId) m,
    ]);
  }
}

/// How far the other participant has got in one thread — what turns the
/// caller's messages into Delivered and Seen. Fetched once, then moved along
/// by the RECEIPT frames the server sends as they receive and read.
@riverpod
class PeerReceipt extends _$PeerReceipt {
  /// A frame that arrived while the first fetch was still out.
  ReceiptView? _early;

  @override
  FutureOr<ReceiptView?> build(String conversationId) async {
    _early = null;
    final repository = ref.read(chatRepositoryProvider);
    final live = repository
        .inboxEvents()
        .where(
          (e) =>
              e.type == ChatEventType.receipt &&
              e.conversationId == conversationId,
        )
        .listen((e) => _moved(e.receipt!));
    ref.onDispose(live.cancel);

    try {
      final fetched = await repository.receipts(conversationId);
      final early = _early;
      return early == null ? fetched : fetched.merge(early);
    } on AppException {
      // No status line is better than an error for it; frames still fill in.
      return _early;
    }
  }

  void _moved(ReceiptView receipt) {
    if (state.isLoading && !state.hasValue) {
      _early = _early?.merge(receipt) ?? receipt;
      return;
    }
    state = AsyncData(state.valueOrNull?.merge(receipt) ?? receipt);
  }
}

/// Whether the other participant is typing in one thread right now.
///
/// On with each TYPING frame from them, off when they say they stopped, when
/// a message from them lands (they sent what they were typing), when the
/// connection drops (nothing said over it can be trusted any more), and on
/// its own [typingPeerTtl] after the last frame, so a frame lost on the way
/// never leaves the dots up.
@riverpod
class PeerTyping extends _$PeerTyping {
  Timer? _expiry;

  @override
  bool build(String conversationId) {
    final repository = ref.read(chatRepositoryProvider);
    final events = repository
        .inboxEvents()
        .where((e) => e.conversationId == conversationId)
        .listen(_onEvent);
    final lost = repository.connectionLost().listen((_) => _show(false));
    ref.onDispose(() {
      events.cancel();
      lost.cancel();
      _expiry?.cancel();
    });
    return false;
  }

  void _onEvent(ChatInboxEvent event) {
    final me = ref.read(authStateProvider).valueOrNull?.id;
    switch (event.type) {
      case ChatEventType.typing when event.typingUserId != me:
        _show(event.typing!);
      case ChatEventType.message when event.message!.senderId != me:
        _show(false);
      default:
        break;
    }
  }

  void _show(bool on) {
    _expiry?.cancel();
    _expiry = on ? Timer(typingPeerTtl, () => state = false) : null;
    state = on;
  }
}

/// An id the server uses to recognise a retried send: the same id answers
/// with the first message instead of posting a second one.
String newClientRequestId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// The sticker catalog, fetched once per session — it changes with a server
/// release, not while the app is open.
@Riverpod(keepAlive: true)
Future<List<StickerPack>> stickerPacks(Ref ref) =>
    ref.watch(chatRepositoryProvider).listStickerPacks();

/// A chat picture's bytes, fetched with the viewer's token.
@riverpod
Future<Uint8List> chatImageBytes(Ref ref, ChatImageModel image) =>
    ref.watch(chatRepositoryProvider).imageBytes(image);

/// A picture on its way out: shown in the thread at once, with its progress,
/// and kept with its bytes if it fails so it can be sent again.
class OutgoingImage {
  const OutgoingImage({
    required this.localId,
    required this.bytes,
    required this.filename,
    this.caption,
    this.progress = 0,
    this.error,
  });

  /// Doubles as the clientRequestId: a retry after a lost response returns
  /// the message the first attempt made.
  final String localId;
  final Uint8List bytes;
  final String filename;
  final String? caption;

  /// 0..1 while the bytes go up.
  final double progress;

  /// Set when the send failed; the row offers Retry and Remove.
  final String? error;

  bool get failed => error != null;

  OutgoingImage copyWith({
    double? progress,
    String? error,
    bool clearError = false,
  }) => OutgoingImage(
    localId: localId,
    bytes: bytes,
    filename: filename,
    caption: caption,
    progress: progress ?? this.progress,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Pictures being sent into one thread, oldest first. Kept alive while one is
/// in flight, so leaving the thread does not cancel it.
@riverpod
class OutgoingImages extends _$OutgoingImages {
  @override
  List<OutgoingImage> build(String conversationId) => const [];

  /// The server's own limits, checked before spending the upload: it reads
  /// the type from the bytes and takes JPEG, PNG and GIF up to 5 MB.
  static const maxBytes = 5 * 1024 * 1024;

  static String? problemWith(Uint8List bytes) {
    if (bytes.length > maxBytes) return 'Photos can be up to 5 MB';
    bool startsWith(List<int> magic) =>
        bytes.length >= magic.length &&
        Iterable.generate(magic.length).every((i) => bytes[i] == magic[i]);
    final known =
        startsWith([0xFF, 0xD8, 0xFF]) || // JPEG
        startsWith([0x89, 0x50, 0x4E, 0x47]) || // PNG
        startsWith([0x47, 0x49, 0x46, 0x38]); // GIF
    return known ? null : 'Only JPEG, PNG and GIF photos can be sent';
  }

  Future<void> send(
    Uint8List bytes, {
    required String filename,
    String? caption,
  }) {
    final item = OutgoingImage(
      localId: newClientRequestId(),
      bytes: bytes,
      filename: filename,
      caption: caption,
    );
    state = [...state, item];
    return _run(item.localId);
  }

  Future<void> retry(String localId) {
    _update(localId, (i) => i.copyWith(progress: 0, clearError: true));
    return _run(localId);
  }

  void remove(String localId) {
    state = [
      for (final i in state)
        if (i.localId != localId) i,
    ];
  }

  Future<void> _run(String localId) async {
    final item = state.where((i) => i.localId == localId).firstOrNull;
    if (item == null) return;
    final keepAlive = ref.keepAlive();
    final repository = ref.read(chatRepositoryProvider);
    try {
      final problem = problemWith(item.bytes);
      if (problem != null) throw UnknownException(problem);
      final uploaded = await repository.uploadImage(
        conversationId,
        bytes: item.bytes,
        filename: item.filename,
        onProgress: (sent, total) {
          if (total > 0) {
            _update(localId, (i) => i.copyWith(progress: sent / total));
          }
        },
      );
      repository.rememberImage(uploaded.imageId, item.bytes);
      final message = await repository.sendImage(
        conversationId,
        uploaded.imageId,
        caption: item.caption,
        clientRequestId: localId,
      );
      remove(localId);
      if (ref.exists(threadProvider(conversationId))) {
        ref.read(threadProvider(conversationId).notifier).delivered(message);
      } else if (ref.exists(conversationsProvider)) {
        ref.read(conversationsProvider.notifier).sent(message);
      }
    } on AppException catch (e) {
      _update(localId, (i) => i.copyWith(error: _imageError(e)));
      _recheckPermission(ref, conversationId, e);
    } finally {
      keepAlive.close();
    }
  }

  void _update(String localId, OutgoingImage Function(OutgoingImage) change) {
    state = [
      for (final i in state)
        if (i.localId == localId) change(i) else i,
    ];
  }

  /// The server's refusal in words; its codes are stable, its messages are
  /// not meant for people.
  static String _imageError(AppException e) {
    final code = e is ServerException ? e.code : null;
    return switch (code) {
      'IMAGE_TOO_LARGE' => 'Photos can be up to 5 MB',
      'IMAGE_UNSUPPORTED_TYPE' => 'Only JPEG, PNG and GIF photos can be sent',
      'IMAGE_DIMENSIONS' => 'This photo is too large to send',
      'IMAGE_CORRUPT' => 'This photo could not be read',
      'MESSAGING_BLOCKED' => 'You can\'t message this account',
      'MESSAGE_REQUEST_NOT_ACCEPTED' || 'MESSAGE_REQUEST_LIMIT_REACHED' =>
        'You can send photos once they accept your message request',
      _ => e.message,
    };
  }
}

/// Threads with something the user has not read — the dot on the Inbox tab
/// and its Messages shortcut — plus message requests not opened yet, so a
/// request is noticed from anywhere. A muted thread is left out: its
/// messages still arrive and its row still turns bold, but it does not
/// nudge. Watching it keeps both lists, and so the inbox socket, alive while
/// the app is up.
@riverpod
int unreadConversations(Ref ref) {
  final rows = [
    ...?ref.watch(conversationsProvider).valueOrNull,
    ...?ref.watch(messageRequestsProvider).valueOrNull,
  ];
  final now = DateTime.now();
  // A timed mute runs out on its own, with nothing from the server to say so:
  // count again when the first one ends.
  final ends = [
    for (final c in rows)
      if (c.muteMode == MuteMode.timed && c.mutedAt(now)) c.mutedUntil!,
  ];
  if (ends.isNotEmpty) {
    final next = ends.reduce((a, b) => a.isBefore(b) ? a : b);
    final timer = Timer(
      next.difference(now) + const Duration(seconds: 1),
      ref.invalidateSelf,
    );
    ref.onDispose(timer.cancel);
  }
  return rows.where((c) => c.hasUnread && !c.mutedAt(now)).length;
}
