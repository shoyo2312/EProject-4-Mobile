import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';

/// chat-service (`/api/v1/conversations`). Every endpoint takes the caller
/// from the token and refuses a thread they are not in with
/// `NOT_CONVERSATION_PARTICIPANT` — there is no way to read somebody else's
/// messages by guessing an id.
class ChatRemoteDatasource {
  ChatRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// The caller's threads, most recently active first.
  Future<List<ConversationModel>> listConversations() async {
    final response =
        await _apiClient.get<Map<String, dynamic>>('/conversations');
    return (response.data!['data'] as List)
        .map((e) => conversationFromServer(e as Map<String, dynamic>))
        .toList();
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
    final response = await _apiClient
        .get<Map<String, dynamic>>('/conversations/$conversationId');
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
  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      data: {'content': content},
    );
    return ApiResponse<MessageModel>.fromJson(
      response.data!,
      (json) => messageFromServer(json as Map<String, dynamic>),
    ).data!;
  }

  /// The sticker catalog. Every pack the server offers; a sticker that is no
  /// longer offered still renders in old messages, from the message itself.
  Future<List<StickerPack>> listStickerPacks() async {
    final response =
        await _apiClient.get<Map<String, dynamic>>('/conversations/stickers');
    return (response.data!['data'] as List)
        .map((e) => StickerPack.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A sticker is its own message, with no text. [clientRequestId] makes a
  /// retry after a lost response answer with the first message instead of
  /// posting a second one.
  Future<MessageModel> sendSticker(
    String conversationId,
    String stickerId, {
    required String clientRequestId,
  }) =>
      _send(conversationId, {
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
  }) =>
      _send(conversationId, {
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

  /// 204, no body. Clears this thread's unread flag for the caller only.
  Future<void> markRead(String conversationId) {
    return _apiClient.post<void>('/conversations/$conversationId/messages/read');
  }

  ConversationModel _unwrapConversation(Map<String, dynamic> body) {
    return ApiResponse<ConversationModel>.fromJson(
      body,
      (json) => conversationFromServer(json as Map<String, dynamic>),
    ).data!;
  }
}
