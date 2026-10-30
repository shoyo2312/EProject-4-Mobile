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

/// One message. The same shape arrives two ways — as the answer to a send, and
/// over the socket when the other side sends one.
@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String conversationId,
    @JsonKey(fromJson: _idFromJson) required String senderId,
    required String content,
    required DateTime sentAt,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}

/// What a message or a conversation preview shows when the server sends no
/// text: a sticker, a shared video, or a message its sender took back. The
/// web client can send all three; this app only sends text, but has to read
/// what arrives.
String? _placeholderText({
  required Object? type,
  required bool recalled,
}) {
  if (recalled) return 'Message unsent';
  return switch (type) {
    'STICKER' => 'Sticker',
    'VIDEO' => 'Shared a video',
    _ => null,
  };
}

/// A server message as [MessageModel] reads it. `content` is null on a
/// sticker, a recalled message and a video with no note; the model keeps a
/// non-null `content`, so those are given the text to show instead.
MessageModel messageFromServer(Map<String, dynamic> json) {
  final recalled = json['recalledAt'] != null;
  final content = recalled ? null : json['content'] as String?;
  if (content != null && content.isNotEmpty) {
    return MessageModel.fromJson(json);
  }
  return MessageModel.fromJson({
    ...json,
    'content':
        _placeholderText(type: json['type'], recalled: recalled) ?? '',
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
        _placeholderText(type: json['lastMessageType'], recalled: recalled),
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
