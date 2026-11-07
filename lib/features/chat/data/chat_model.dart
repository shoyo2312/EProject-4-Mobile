import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

/// chat-service sends participant ids as JSON numbers; user-service sends the
/// same ids as strings. Keep the string form so a conversation row can be
/// matched against a profile without a 19-digit id round-tripping through a
/// double.
String _idFromJson(Object? value) => value.toString();

String? _nullableIdFromJson(Object? value) => value?.toString();

List<String> _idsFromJson(Object? value) => [
  for (final id in value as List) id.toString(),
];

/// One 1:1 thread. There are always exactly two [participantIds] — the API has
/// no group conversations — so the other person is the id that is not yours.
@freezed
class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required String id,
    @JsonKey(fromJson: _idsFromJson) required List<String> participantIds,
    String? lastMessageContent,
    @JsonKey(fromJson: _nullableIdFromJson) String? lastMessageSenderId,
    DateTime? lastMessageAt,
    required DateTime createdAt,
    @Default(false) bool hasUnread,

    /// The viewer's own choice, as of when the server answered. A timed mute
    /// that has since run out is still TIMED here — [mutedAt] reads the clock.
    @JsonKey(unknownEnumValue: MuteMode.none)
    @Default(MuteMode.none)
    MuteMode muteMode,
    DateTime? mutedUntil,

    /// When the viewer pinned it; `null` when not pinned. A later pin sits
    /// above an earlier one.
    DateTime? pinnedAt,

    /// `null` for an ordinary conversation; set while it is a message request
    /// (started by someone the other side does not follow back).
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    MessageRequestState? requestState,

    /// Who opened the thread; `null` on conversations older than requests.
    @JsonKey(fromJson: _nullableIdFromJson) String? initiatorId,

    /// What the viewer may send right now, decided by the server for them.
    @JsonKey(unknownEnumValue: SendPermission.allowed)
    @Default(SendPermission.allowed)
    SendPermission sendPermission,

    /// While the viewer's own request message waits: when they may send one
    /// more.
    DateTime? retryAvailableAt,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  const ConversationModel._();

  /// Whether new messages here should stay quiet at [now]. Messages still
  /// arrive and the row still updates; only the nudge is held back.
  bool mutedAt(DateTime now) => switch (muteMode) {
    MuteMode.indefinite => true,
    MuteMode.timed => mutedUntil != null && mutedUntil!.isAfter(now),
    MuteMode.none => false,
  };

  bool get muted => mutedAt(DateTime.now());

  bool get pinned => pinnedAt != null;

  /// How long a request message waits before its sender may send one more
  /// (chat-service `SendPolicy.RETRY_AFTER`).
  static const requestRetryAfter = Duration(days: 15);

  /// A request somebody else opened and [me] has not answered yet.
  bool isIncomingRequest(String me) =>
      requestState == MessageRequestState.pending &&
      initiatorId != null &&
      initiatorId != me;

  /// The same conversation once [me]'s own message, sent at [sentAt], is in.
  /// A request's one message is spent, and writing into a request the viewer
  /// deleted opens it — what the server says too, without the wait for it.
  ConversationModel afterOwnMessage(DateTime sentAt) => switch (sendPermission) {
    SendPermission.firstMessageOnly => copyWith(
      sendPermission: SendPermission.requestSent,
      retryAvailableAt: sentAt.add(requestRetryAfter),
    ),
    SendPermission.reopenOnSend => copyWith(
      requestState: null,
      sendPermission: SendPermission.allowed,
      retryAvailableAt: null,
    ),
    _ => this,
  };

  /// How many conversations one person can keep pinned (chat-service
  /// `ChatUserPrefs.MAX_PINS`).
  static const maxPins = 5;

  /// chat-service's one ordering of the thread list: pinned first, the latest
  /// pin on top; then by newest message; the id breaks ties.
  static int compare(ConversationModel a, ConversationModel b) {
    int newestFirst(DateTime? x, DateTime? y) {
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    }

    final byPin = newestFirst(a.pinnedAt, b.pinnedAt);
    if (byPin != 0) return byPin;
    final byMessage = newestFirst(a.lastMessageAt, b.lastMessageAt);
    if (byMessage != 0) return byMessage;
    return b.id.compareTo(a.id);
  }

  /// The id of whoever is not [me]. Falls back to the first participant so a
  /// malformed row renders as somebody rather than crashing the list.
  String otherParticipant(String me) => participantIds.firstWhere(
    (id) => id != me,
    orElse: () => participantIds.first,
  );
}

/// Whether the viewer silenced a conversation, and for how long.
enum MuteMode {
  @JsonValue('NONE')
  none,

  /// Until `mutedUntil`.
  @JsonValue('TIMED')
  timed,

  /// Until the viewer turns it back on.
  @JsonValue('INDEFINITE')
  indefinite,
}

/// Where a conversation stands as a message request. Accepting one clears the
/// state, so `null` is the only meaning of "both sides may chat".
enum MessageRequestState {
  /// Waiting for the recipient to accept or delete it.
  @JsonValue('PENDING')
  pending,

  /// The recipient deleted it. The sender is not told.
  @JsonValue('DECLINED')
  declined,
}

/// What the viewer may do in a conversation right now (chat-service
/// `SendPermission`). The composer is drawn from this, never guessed.
enum SendPermission {
  /// An ordinary conversation.
  @JsonValue('ALLOWED')
  allowed,

  /// The viewer opened a request and has its one message left.
  @JsonValue('FIRST_MESSAGE_ONLY')
  firstMessageOnly,

  /// The viewer's request message is waiting; see `retryAvailableAt`.
  @JsonValue('REQUEST_SENT')
  requestSent,

  /// The viewer received the request and has to accept it before replying.
  @JsonValue('AWAITING_ACCEPT')
  awaitingAccept,

  /// The viewer deleted this request; sending a message reopens it.
  @JsonValue('REOPEN_ON_SEND')
  reopenOnSend,
}

/// The lengths chat-service offers. The server works out the end itself, on
/// its own clock.
enum MuteLength {
  oneHour('ONE_HOUR', 'For 1 hour'),
  eightHours('EIGHT_HOURS', 'For 8 hours'),
  oneDay('TWENTY_FOUR_HOURS', 'For 24 hours'),
  indefinite('INDEFINITE', 'Until I turn it back on');

  const MuteLength(this.wire, this.label);

  final String wire;
  final String label;
}

/// What a message is. Older messages carry no type and are text.
enum MessageType {
  @JsonValue('TEXT')
  text,
  @JsonValue('STICKER')
  sticker,

  /// A video from the app shared into the chat, not an uploaded file.
  @JsonValue('VIDEO')
  video,
  @JsonValue('STORY_REPLY')
  storyReply,
  @JsonValue('IMAGE')
  image,

  /// A type this build does not know yet: drawn as its text, never a crash.
  unknown,
}

/// One sticker from chat-service's catalog. [url] is public — the bucket's
/// `stickers/` prefix is readable by anyone — so it loads like any image.
@freezed
class StickerModel with _$StickerModel {
  const factory StickerModel({
    required String stickerId,
    required String name,
    required String url,
    @Default(0) int width,
    @Default(0) int height,
  }) = _StickerModel;

  factory StickerModel.fromJson(Map<String, dynamic> json) =>
      _$StickerModelFromJson(json);
}

@freezed
class StickerPack with _$StickerPack {
  const factory StickerPack({
    required String packId,
    required String name,
    @Default([]) List<StickerModel> stickers,
  }) = _StickerPack;

  factory StickerPack.fromJson(Map<String, dynamic> json) =>
      _$StickerPackFromJson(json);
}

/// A picture sent in a chat. Unlike a sticker it is private: [url] is a path
/// under the gateway that answers only with the viewer's token, so it is
/// fetched through the API client, never handed to an image widget as-is.
/// [width] and [height] are the display size (EXIF rotation applied), so the
/// space can be reserved before the bytes arrive.
@freezed
class ChatImageModel with _$ChatImageModel {
  const factory ChatImageModel({
    required String imageId,
    required String url,
    String? mime,
    @Default(0) int width,
    @Default(0) int height,
    @Default(0) int size,
  }) = _ChatImageModel;

  factory ChatImageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatImageModelFromJson(json);
}

/// One message. The same shape arrives two ways — as the answer to a send, and
/// over the socket when the other side sends one.
///
/// [content] is always the text to show: a caption on a picture (possibly
/// empty), or a stand-in for a message with no text of its own — see
/// [messageFromServer].
@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String conversationId,
    @JsonKey(fromJson: _idFromJson) required String senderId,
    required String content,
    required DateTime sentAt,
    @JsonKey(unknownEnumValue: MessageType.unknown)
    @Default(MessageType.text)
    MessageType type,
    StickerModel? sticker,
    ChatImageModel? image,
    DateTime? recalledAt,

    /// Orders updates to this message: one is applied only if it is newer.
    @Default(0) int revision,

    /// A message of the caller's still on its way to the server: drawn at
    /// once, with "Sending…", and swapped for the server's copy when it lands.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool pending,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  const MessageModel._();

  bool get recalled => recalledAt != null;

  /// This message with [update] applied, or unchanged when the update is not
  /// newer. A recall takes the content with it, as it does on the server.
  MessageModel applying(MessageUpdate update) {
    if (update.revision <= revision) return this;
    final recalledAt = update.recalledAt;
    if (recalledAt == null) return copyWith(revision: update.revision);
    return copyWith(
      revision: update.revision,
      recalledAt: recalledAt,
      content: _messagePlaceholder(type: null, recalled: true)!,
      sticker: null,
      image: null,
    );
  }

  /// What the conversation list shows for this message. A picture's caption
  /// stays out of it, the same rule the server applies to its own preview.
  String get previewText =>
      type == MessageType.image && !recalled ? 'Photo' : content;
}

/// What a message shows when the server sends no text: a sticker, a shared
/// video, or a message its sender took back. A picture's missing caption is
/// just empty — the picture is the message.
String? _messagePlaceholder({required Object? type, required bool recalled}) {
  if (recalled) return 'Message unsent';
  return switch (type) {
    'STICKER' => 'Sticker',
    'VIDEO' => 'Shared a video',
    _ => null,
  };
}

/// The same for a conversation preview, which never carries a picture's
/// caption — the server leaves it out so a recall cannot leave it behind.
String? _previewPlaceholder({required Object? type, required bool recalled}) {
  if (type == 'IMAGE' && !recalled) return 'Photo';
  return _messagePlaceholder(type: type, recalled: recalled);
}

/// A server message as [MessageModel] reads it. `content` is null on a
/// sticker, a picture without a caption, a recalled message and a video with
/// no note; the model keeps a non-null `content`, so those are given the text
/// to show instead.
MessageModel messageFromServer(Map<String, dynamic> json) {
  final recalled = json['recalledAt'] != null;
  final content = recalled ? null : json['content'] as String?;
  if (content != null && content.isNotEmpty) {
    return MessageModel.fromJson(json);
  }
  return MessageModel.fromJson({
    ...json,
    'content':
        _messagePlaceholder(type: json['type'], recalled: recalled) ?? '',
  });
}

/// A server conversation as [ConversationModel] reads it, with the preview
/// filled in the same way as [messageFromServer].
ConversationModel conversationFromServer(Map<String, dynamic> json) {
  final recalled = json['lastMessageRecalled'] == true;
  final content = recalled ? null : json['lastMessageContent'] as String?;
  if (content != null && content.isNotEmpty) {
    return ConversationModel.fromJson(json);
  }
  return ConversationModel.fromJson({
    ...json,
    'lastMessageContent': _previewPlaceholder(
      type: json['lastMessageType'],
      recalled: recalled,
    ),
  });
}

/// A place in a thread that one participant's client has reached: the
/// newest message of the other side it covers. Messages are ordered by
/// `(sentAt, id)`, so [covers] compares by position — never by when the mark
/// was recorded, which is only what "Seen 5 min ago" is read from ([at]).
class ReceiptMark {
  const ReceiptMark({
    required this.messageId,
    required this.sentAt,
    required this.at,
  });

  static ReceiptMark? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['messageId'] as String?;
    final sentAt = json['sentAt'] as String?;
    if (id == null || sentAt == null) return null;
    final at = json['at'] as String?;
    return ReceiptMark(
      messageId: id,
      sentAt: DateTime.parse(sentAt),
      at: at == null ? null : DateTime.parse(at),
    );
  }

  final String messageId;
  final DateTime sentAt;
  final DateTime? at;

  /// Whether [message] is at or before this mark in thread order.
  bool covers(MessageModel message) {
    final bySentAt = sentAt.compareTo(message.sentAt);
    return bySentAt > 0 ||
        (bySentAt == 0 && messageId.compareTo(message.id) >= 0);
  }

  /// Marks only ever move forward; of two, the later position wins.
  static ReceiptMark? later(ReceiptMark? a, ReceiptMark? b) {
    if (a == null) return b;
    if (b == null) return a;
    final bySentAt = a.sentAt.compareTo(b.sentAt);
    if (bySentAt != 0) return bySentAt > 0 ? a : b;
    return a.messageId.compareTo(b.messageId) >= 0 ? a : b;
  }
}

/// How far one participant has got in a conversation. Seeing implies
/// receiving, so [delivered] is never behind [read].
class ReceiptView {
  const ReceiptView({
    required this.conversationId,
    this.userId,
    this.delivered,
    this.read,
  });

  factory ReceiptView.fromJson(Map<String, dynamic> json) => ReceiptView(
    conversationId: json['conversationId'] as String,
    userId: json['userId']?.toString(),
    delivered: ReceiptMark.fromJson(json['delivered']),
    read: ReceiptMark.fromJson(json['read']),
  );

  final String conversationId;
  final String? userId;
  final ReceiptMark? delivered;
  final ReceiptMark? read;

  /// The further of the two for each mark, so a frame that overtakes a fetch
  /// can never move the view backwards.
  ReceiptView merge(ReceiptView other) => ReceiptView(
    conversationId: conversationId,
    userId: userId ?? other.userId,
    delivered: ReceiptMark.later(delivered, other.delivered),
    read: ReceiptMark.later(read, other.read),
  );

  /// Where one of the caller's own messages stands, from the other side's
  /// marks.
  MessageStatus statusOf(MessageModel message) {
    if (message.pending) return MessageStatus.sending;
    if (read?.covers(message) ?? false) return MessageStatus.seen;
    if (delivered?.covers(message) ?? false) return MessageStatus.delivered;
    return MessageStatus.sent;
  }
}

enum MessageStatus {
  sending('Sending…'),
  sent('Sent'),
  delivered('Delivered'),
  seen('Seen');

  const MessageStatus(this.label);

  final String label;
}

/// What changed about a message already in a thread — a recall, or its
/// reactions. Carries no content, so it is the same for both participants.
class MessageUpdate {
  const MessageUpdate({
    required this.messageId,
    required this.conversationId,
    required this.revision,
    this.recalledAt,
  });

  factory MessageUpdate.fromJson(Map<String, dynamic> json) => MessageUpdate(
    messageId: json['messageId'] as String,
    conversationId: json['conversationId'] as String,
    revision: (json['revision'] as num?)?.toInt() ?? 0,
    recalledAt: json['recalledAt'] == null
        ? null
        : DateTime.parse(json['recalledAt'] as String),
  );

  final String messageId;
  final String conversationId;
  final int revision;
  final DateTime? recalledAt;
}

/// The kinds of `/user/queue/chat` frame this app acts on. The server sends
/// more (typing); those arrive as [other] and are ignored.
enum ChatEventType {
  message,
  conversation,
  conversationRemoved,

  /// A recall or a reaction on a message: [ChatInboxEvent.update].
  messageUpdated,

  /// The caller deleted a message from their own side, on some device:
  /// [ChatInboxEvent.messageId].
  messageHidden,

  /// The other participant received or read the thread:
  /// [ChatInboxEvent.receipt].
  receipt,
  other,
}

/// One frame from the user's own chat queue. It reaches the user whatever
/// screen is open, which is what keeps the thread list current.
class ChatInboxEvent {
  const ChatInboxEvent({
    required this.type,
    required this.conversationId,
    this.message,
    this.update,
    this.messageId,
    this.receipt,
  });

  /// Reads a `ChatEvent` from chat-service. Null for a frame without a
  /// conversation, which nothing here could place.
  static ChatInboxEvent? fromServer(Map<String, dynamic> json) {
    final conversationId = json['conversationId'] as String?;
    if (conversationId == null) return null;
    final message = json['message'];
    final update = json['update'];
    final receipt = json['receipt'];
    final messageId = json['messageId'];
    final type = switch (json['type']) {
      'MESSAGE' when message is Map<String, dynamic> => ChatEventType.message,
      'CONVERSATION' => ChatEventType.conversation,
      'CONVERSATION_REMOVED' => ChatEventType.conversationRemoved,
      'MESSAGE_UPDATED' when update is Map<String, dynamic> =>
        ChatEventType.messageUpdated,
      'MESSAGE_HIDDEN' when messageId is String => ChatEventType.messageHidden,
      'RECEIPT' when receipt is Map<String, dynamic> => ChatEventType.receipt,
      _ => ChatEventType.other,
    };
    return ChatInboxEvent(
      type: type,
      conversationId: conversationId,
      message: type == ChatEventType.message
          ? messageFromServer(message as Map<String, dynamic>)
          : null,
      update: type == ChatEventType.messageUpdated
          ? MessageUpdate.fromJson(update as Map<String, dynamic>)
          : null,
      messageId: type == ChatEventType.messageHidden
          ? messageId as String
          : null,
      receipt: type == ChatEventType.receipt
          ? ReceiptView.fromJson(receipt as Map<String, dynamic>)
          : null,
    );
  }

  final ChatEventType type;
  final String conversationId;

  /// Set on [ChatEventType.message] only.
  final MessageModel? message;

  /// Set on [ChatEventType.messageUpdated] only.
  final MessageUpdate? update;

  /// Set on [ChatEventType.messageHidden] only.
  final String? messageId;

  /// Set on [ChatEventType.receipt] only.
  final ReceiptView? receipt;
}

/// One page of a thread, newest first — the order the server sorts in, which
/// is also the order a chat is scrolled through (bottom to top).
class MessagePage {
  const MessagePage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<MessageModel> items;
  final bool hasMore;
  final String? nextCursor;
}
