import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

/// chat-service sends participant ids as JSON numbers; user-service sends the
/// same ids as strings. Keep the string form so a conversation row can be
/// matched against a profile without a 19-digit id round-tripping through a
/// double.
String _idFromJson(Object? value) => value.toString();

String? _nullableIdFromJson(Object? value) => value?.toString();

List<String> _idsFromJson(Object? value) =>
    [for (final id in value as List) id.toString()];

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
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  const ConversationModel._();

  /// The id of whoever is not [me]. Falls back to the first participant so a
  /// malformed row renders as somebody rather than crashing the list.
  String otherParticipant(String me) =>
      participantIds.firstWhere((id) => id != me,
          orElse: () => participantIds.first);
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
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  const MessageModel._();

  bool get recalled => recalledAt != null;

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
    'lastMessageContent':
        _previewPlaceholder(type: json['lastMessageType'], recalled: recalled),
  });
}

/// The kinds of `/user/queue/chat` frame this app acts on. The server sends
/// more (typing, receipts, reactions); those arrive as [other] and are
/// ignored.
enum ChatEventType { message, conversation, conversationRemoved, other }

/// One frame from the user's own chat queue. It reaches the user whatever
/// screen is open, which is what keeps the thread list current.
class ChatInboxEvent {
  const ChatInboxEvent({
    required this.type,
    required this.conversationId,
    this.message,
  });

  /// Reads a `ChatEvent` from chat-service. Null for a frame without a
  /// conversation, which nothing here could place.
  static ChatInboxEvent? fromServer(Map<String, dynamic> json) {
    final conversationId = json['conversationId'] as String?;
    if (conversationId == null) return null;
    final message = json['message'];
    final type = switch (json['type']) {
      'MESSAGE' when message is Map<String, dynamic> => ChatEventType.message,
      'CONVERSATION' => ChatEventType.conversation,
      'CONVERSATION_REMOVED' => ChatEventType.conversationRemoved,
      _ => ChatEventType.other,
    };
    return ChatInboxEvent(
      type: type,
      conversationId: conversationId,
      message: type == ChatEventType.message
          ? messageFromServer(message as Map<String, dynamic>)
          : null,
    );
  }

  final ChatEventType type;
  final String conversationId;

  /// Set on [ChatEventType.message] only.
  final MessageModel? message;
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
