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
