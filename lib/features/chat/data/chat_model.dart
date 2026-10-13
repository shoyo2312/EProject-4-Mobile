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
