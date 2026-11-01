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
      lastMessageContent: message.previewText,
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
    delivered(message);
  }

  /// A sticker is a message of its own; the draft in the composer is left as
  /// it was.
  Future<void> sendSticker(StickerModel sticker) async {
    final message = await ref.read(chatRepositoryProvider).sendSticker(
          conversationId,
          sticker.stickerId,
          clientRequestId: newClientRequestId(),
        );
    delivered(message);
  }

  /// The caller's own message, as the server stored it: into the thread, and
  /// to the top of the conversation list.
  void delivered(MessageModel message) {
    _receive(message);
    if (ref.exists(conversationsProvider)) {
      ref.read(conversationsProvider.notifier).sent(message);
    }
  }
}

/// An id the server uses to recognise a retried send: the same id answers
/// with the first message instead of posting a second one.
String newClientRequestId() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
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

  OutgoingImage copyWith({double? progress, String? error, bool clearError = false}) =>
      OutgoingImage(
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
    final known = startsWith([0xFF, 0xD8, 0xFF]) || // JPEG
        startsWith([0x89, 0x50, 0x4E, 0x47]) || // PNG
        startsWith([0x47, 0x49, 0x46, 0x38]); // GIF
    return known ? null : 'Only JPEG, PNG and GIF photos can be sent';
  }

  Future<void> send(Uint8List bytes, {required String filename, String? caption}) {
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
    state = [for (final i in state) if (i.localId != localId) i];
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
          if (total > 0) _update(localId, (i) => i.copyWith(progress: sent / total));
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
    } finally {
      keepAlive.close();
    }
  }

  void _update(String localId, OutgoingImage Function(OutgoingImage) change) {
    state = [for (final i in state) if (i.localId == localId) change(i) else i];
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
      'MESSAGE_REQUEST_NOT_ACCEPTED' ||
      'MESSAGE_REQUEST_LIMIT_REACHED' =>
        'You can send photos once they accept your message request',
      _ => e.message,
    };
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
