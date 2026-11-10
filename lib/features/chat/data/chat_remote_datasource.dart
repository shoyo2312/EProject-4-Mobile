import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/sticker_suggestions.dart';

/// chat-service (`/api/v1/conversations`). Every endpoint takes the caller
/// from the token and refuses a thread they are not in with
/// `NOT_CONVERSATION_PARTICIPANT` — there is no way to read somebody else's
/// messages by guessing an id.
class ChatRemoteDatasource {
  ChatRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// The caller's threads, most recently active first.
  Future<List<ConversationModel>> listConversations() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations',
    );
    return (response.data!['data'] as List)
        .map((e) => conversationFromServer(e as Map<String, dynamic>))
        .toList();
  }

  /// Message requests waiting on the caller, newest first. They are not part
  /// of [listConversations] until accepted.
  Future<List<ConversationModel>> listRequests() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/requests',
    );
    return (response.data!['data'] as List)
        .map((e) => conversationFromServer(e as Map<String, dynamic>))
        .toList();
  }

  /// Recipient only. Safe to repeat: accepting an accepted request answers it
  /// unchanged. `MESSAGE_REQUEST_NOT_PENDING` once it was deleted.
  Future<ConversationModel> acceptRequest(String conversationId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/conversations/$conversationId/accept',
    );
    return _unwrapConversation(response.data!);
  }

  /// Recipient only. The thread and its message are kept; only the request
  /// goes, and the sender is not told.
  Future<ConversationModel> declineRequest(String conversationId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/conversations/$conversationId/decline',
    );
    return _unwrapConversation(response.data!);
  }

  /// Get-or-create: asking twice for the same person answers the same thread
  /// rather than making a second one. Messaging yourself is
  /// `CANNOT_MESSAGE_SELF`.
  Future<ConversationModel> openConversation(String participantId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/conversations',
      data: {'participantId': int.parse(participantId)},
    );
    return _unwrapConversation(response.data!);
  }

  Future<ConversationModel> getConversation(String conversationId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/$conversationId',
    );
    return _unwrapConversation(response.data!);
  }

  /// Newest first, cursor-paged. The cursor is an opaque server string — pass
  /// it back verbatim; `hasMore == false` is the stop condition.
  Future<MessagePage> listMessages(
    String conversationId, {
    String? cursor,
    int size = 30,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      queryParameters: {'cursor': ?cursor, 'size': size},
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    return MessagePage(
      items: (body['items'] as List)
          .map((e) => messageFromServer(e as Map<String, dynamic>))
          .toList(),
      hasMore: body['hasMore'] as bool,
      nextCursor: body['nextCursor'] as String?,
    );
  }

  /// The REST half of sending. The socket carries the same message back to
  /// everyone subscribed, sender included, so a client that is connected sees
  /// its own message twice unless it de-duplicates by id.
  ///
  /// [clientRequestId] makes a retry after a lost response answer with the
  /// first message instead of posting a second one.
  Future<MessageModel> sendMessage(
    String conversationId,
    String content, {
    String? clientRequestId,
  }) => _send(conversationId, {
    'content': content,
    'clientRequestId': ?clientRequestId,
  });

  /// The sticker catalog. Every pack the server offers; a sticker that is no
  /// longer offered still renders in old messages, from the message itself.
  Future<List<StickerPack>> listStickerPacks() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/stickers',
    );
    return (response.data!['data'] as List)
        .map((e) => StickerPack.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GIPHY stickers through chat-service, which holds the API key: trending
  /// for a blank [query], a search otherwise. Each id is `giphy:<id>` and is
  /// sent like any other sticker.
  Future<List<StickerModel>> searchGiphyStickers(String query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/stickers/giphy',
      queryParameters: {'limit': 24, if (query.isNotEmpty) 'q': query},
    );
    return (response.data!['data'] as List)
        .map((e) => StickerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The words that earn a sticker suggestion while typing.
  Future<List<SuggestionTopic>> suggestionTopics() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/stickers/suggestions/topics',
    );
    return (response.data!['data'] as List)
        .map((e) => SuggestionTopic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A few stickers for one topic; an unknown topic gives none.
  Future<List<StickerModel>> stickerSuggestions(String topicId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/stickers/suggestions/${Uri.encodeComponent(topicId)}',
    );
    return (response.data!['data'] as List)
        .map((e) => StickerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A sticker is its own message, with no text. [clientRequestId] makes a
  /// retry after a lost response answer with the first message instead of
  /// posting a second one.
  Future<MessageModel> sendSticker(
    String conversationId,
    String stickerId, {
    required String clientRequestId,
  }) => _send(conversationId, {
    'type': 'STICKER',
    'stickerId': stickerId,
    'clientRequestId': clientRequestId,
  });

  /// A reply to somebody's story, delivered to their direct messages. The
  /// server finds (or opens) the thread itself, so the conversation id comes
  /// back on the message. `STORY_NOT_AVAILABLE` when the story is gone or the
  /// caller may no longer see it.
  Future<MessageModel> sendStoryReply({
    required String storyId,
    required String content,
    required String clientRequestId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/conversations/story-replies',
      data: {
        'storyId': storyId,
        'content': content,
        'clientRequestId': clientRequestId,
      },
    );
    return ApiResponse<MessageModel>.fromJson(
      response.data!,
      (json) => messageFromServer(json as Map<String, dynamic>),
    ).data!;
  }

  /// Step one of sending a picture: the bytes go up on their own and come
  /// back as an id. The server reads the type from the bytes — JPEG, PNG and
  /// GIF only, 5 MB — and refuses anything else with `IMAGE_*` codes. An
  /// upload no message claims expires after an hour.
  Future<ChatImageModel> uploadImage(
    String conversationId, {
    required List<int> bytes,
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/conversations/$conversationId/images',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
      onSendProgress: onProgress,
    );
    return ApiResponse<ChatImageModel>.fromJson(
      response.data!,
      (json) => ChatImageModel.fromJson(json as Map<String, dynamic>),
    ).data!;
  }

  /// Step two: an IMAGE message claims the upload by id. Only its uploader can
  /// claim it, only in this conversation, only once.
  Future<MessageModel> sendImage(
    String conversationId,
    String imageId, {
    String? caption,
    required String clientRequestId,
  }) => _send(conversationId, {
    'type': 'IMAGE',
    'imageId': imageId,
    if (caption != null && caption.isNotEmpty) 'content': caption,
    'clientRequestId': clientRequestId,
  });

  /// A chat picture's bytes. [url] is the path the server put in the message
  /// (`/api/v1/conversations/...`), which answers only with the viewer's
  /// token — so it goes through the API client, and a 401 refreshes like any
  /// other call.
  Future<Uint8List> downloadImage(String url) async {
    final response = await _apiClient.dio.getUri<List<int>>(
      Uri.parse(Env.apiBaseUrl).replace(path: url),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<MessageModel> _send(
    String conversationId,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      data: body,
    );
    return ApiResponse<MessageModel>.fromJson(
      response.data!,
      (json) => messageFromServer(json as Map<String, dynamic>),
    ).data!;
  }

  /// The caller has looked at the thread up to [messageId], the newest
  /// message of the other side on screen. Without one, the server reads
  /// through the other side's newest message as of now. Clears the unread
  /// flag, and moves the delivered mark along with the read one.
  Future<void> markRead(String conversationId, {String? messageId}) {
    return _apiClient.post<void>(
      '/conversations/$conversationId/messages/read',
      data: messageId == null ? null : {'messageId': messageId},
    );
  }

  /// The caller's client now holds these messages of the other side. The
  /// server moves the delivered mark only across messages that are all
  /// named, so acknowledging a later one never covers one never received.
  Future<void> markDelivered(String conversationId, List<String> messageIds) {
    return _apiClient.post<void>(
      '/conversations/$conversationId/messages/delivered',
      data: {'messageIds': messageIds},
    );
  }

  /// How far the other participant has got: what turns the caller's own
  /// messages into Delivered and Seen.
  Future<ReceiptView> receipts(String conversationId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/$conversationId/messages/receipts',
    );
    return ReceiptView.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Takes one of the caller's messages back for everyone. Refused with
  /// `MESSAGE_ALREADY_SEEN` once the other side has read it, and with
  /// `NOT_MESSAGE_AUTHOR` for somebody else's.
  Future<MessageUpdate> recall(String conversationId, String messageId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/conversations/$conversationId/messages/$messageId/recall',
    );
    return MessageUpdate.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  /// Deletes a message from the caller's side only; the other person keeps
  /// it. 204.
  Future<void> hide(String conversationId, String messageId) {
    return _apiClient.post<void>(
      '/conversations/$conversationId/messages/$messageId/hide',
    );
  }

  /// Silences the conversation for the caller. Calling again changes the
  /// length. Answers with the conversation as the caller now sees it.
  Future<ConversationModel> mute(
    String conversationId,
    MuteLength length,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/conversations/$conversationId/mute',
      data: {'duration': length.wire},
    );
    return _unwrapConversation(response.data!);
  }

  Future<ConversationModel> unmute(String conversationId) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '/conversations/$conversationId/mute',
    );
    return _unwrapConversation(response.data!);
  }

  /// Pins the conversation above the caller's others. 409
  /// `PIN_LIMIT_REACHED` when [ConversationModel.maxPins] are already pinned;
  /// pinning a pinned one changes nothing.
  Future<ConversationModel> pin(String conversationId) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/conversations/$conversationId/pin',
    );
    return _unwrapConversation(response.data!);
  }

  Future<ConversationModel> unpin(String conversationId) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '/conversations/$conversationId/pin',
    );
    return _unwrapConversation(response.data!);
  }

  /// Removes the conversation from the caller's side only; the other person
  /// keeps their copy, and a new message starts a fresh thread here.
  Future<void> deleteForMe(String conversationId) async {
    await _apiClient.delete<void>('/conversations/$conversationId');
  }

  /// A report filed from a conversation (admin-service). Who is reported and
  /// what each message said are read by the server from the conversation;
  /// the client names only the messages. [requestId] makes a resubmit after a
  /// lost response the same report.
  Future<void> reportConversation({
    required String conversationId,
    required String reason,
    required List<String> messageIds,
    required String requestId,
  }) {
    return _apiClient.post<void>(
      '/admin/reports/direct-message',
      data: {
        'conversationId': conversationId,
        'reason': reason,
        'messageIds': messageIds,
        'requestId': requestId,
      },
    );
  }

  ConversationModel _unwrapConversation(Map<String, dynamic> body) {
    return ApiResponse<ConversationModel>.fromJson(
      body,
      (json) => conversationFromServer(json as Map<String, dynamic>),
    ).data!;
  }
}
