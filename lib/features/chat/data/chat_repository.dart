import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/data/chat_remote_datasource.dart';
import 'package:tiktok_mobile/features/chat/data/chat_socket.dart';

class ChatRepository {
  ChatRepository(this._remoteDatasource, this._socket);

  final ChatRemoteDatasource _remoteDatasource;
  final ChatSocket _socket;

  Future<List<ConversationModel>> listConversations() async {
    try {
      return await _remoteDatasource.listConversations();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<ConversationModel> openConversation(String participantId) async {
    try {
      return await _remoteDatasource.openConversation(participantId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<ConversationModel> getConversation(String conversationId) async {
    try {
      return await _remoteDatasource.getConversation(conversationId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<MessagePage> listMessages(
    String conversationId, {
    String? cursor,
    int size = 30,
  }) async {
    try {
      return await _remoteDatasource.listMessages(
        conversationId,
        cursor: cursor,
        size: size,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<MessageModel> sendMessage(String conversationId, String content) async {
    try {
      return await _remoteDatasource.sendMessage(conversationId, content);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> markRead(String conversationId) async {
    try {
      await _remoteDatasource.markRead(conversationId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// Live messages for one thread. Not an HTTP call, so nothing to translate —
  /// a socket that cannot connect simply produces nothing.
  Stream<MessageModel> liveMessages(String conversationId) =>
      _socket.messages(conversationId);
}
