import 'dart:typed_data';

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

  Future<List<StickerPack>> listStickerPacks() async {
    try {
      return await _remoteDatasource.listStickerPacks();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<MessageModel> sendSticker(
    String conversationId,
    String stickerId, {
    required String clientRequestId,
  }) async {
    try {
      return await _remoteDatasource.sendSticker(
        conversationId,
        stickerId,
        clientRequestId: clientRequestId,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<ChatImageModel> uploadImage(
    String conversationId, {
    required List<int> bytes,
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      return await _remoteDatasource.uploadImage(
        conversationId,
        bytes: bytes,
        filename: filename,
        onProgress: onProgress,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<MessageModel> sendImage(
    String conversationId,
    String imageId, {
    String? caption,
    required String clientRequestId,
  }) async {
    try {
      return await _remoteDatasource.sendImage(
        conversationId,
        imageId,
        caption: caption,
        clientRequestId: clientRequestId,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// Recently drawn pictures, so scrolling back up a thread does not fetch
  /// them again (the server answers `no-store`). Bounded: a picture is up to
  /// 5 MB, and a long thread could otherwise hold all of them.
  final _images = <String, Uint8List>{};
  static const _imageCacheSize = 24;

  Future<Uint8List> imageBytes(ChatImageModel image) async {
    final cached = _images.remove(image.imageId);
    if (cached != null) return _images[image.imageId] = cached;
    try {
      final bytes = await _remoteDatasource.downloadImage(image.url);
      _images[image.imageId] = bytes;
      if (_images.length > _imageCacheSize) _images.remove(_images.keys.first);
      return bytes;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// Something the caller just sent, so their own picture draws from memory
  /// instead of being downloaded right back.
  void rememberImage(String imageId, Uint8List bytes) {
    _images[imageId] = bytes;
    if (_images.length > _imageCacheSize) _images.remove(_images.keys.first);
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

  /// What the other side does in the caller's threads — new messages, threads
  /// that changed or went away. What keeps the conversation list and its
  /// unread dots current.
  Stream<ChatInboxEvent> inboxEvents() => _socket.inbox();
}
