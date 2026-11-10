import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';

class CommentRepository {
  CommentRepository(this._remoteDatasource);

  final CommentRemoteDatasource _remoteDatasource;

  Future<CommentPage> fetchComments(String videoId, {String? cursor}) async {
    try {
      return await _remoteDatasource.fetchComments(videoId, cursor: cursor);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<CommentPage> fetchReplies(
    String videoId,
    String parentId, {
    String? cursor,
  }) async {
    try {
      return await _remoteDatasource.fetchReplies(
        videoId,
        parentId,
        cursor: cursor,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<CommentModel> postComment(
    String videoId,
    String text, {
    String? parentId,
    String? stickerId,
  }) async {
    try {
      return await _remoteDatasource.postComment(
        videoId,
        text,
        parentId: parentId,
        stickerId: stickerId,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<CommentModel> editComment(
    String videoId,
    String commentId,
    String text,
  ) async {
    try {
      return await _remoteDatasource.editComment(videoId, commentId, text);
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

  Future<CommentLikeResult> likeComment(
    String videoId,
    String commentId,
  ) async {
    try {
      return await _remoteDatasource.likeComment(videoId, commentId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<CommentLikeResult> unlikeComment(
    String videoId,
    String commentId,
  ) async {
    try {
      return await _remoteDatasource.unlikeComment(videoId, commentId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deleteComment(String videoId, String commentId) async {
    try {
      await _remoteDatasource.deleteComment(videoId, commentId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> removeCommentAsAdmin(
    String videoId,
    String commentId,
    String reason,
  ) async {
    try {
      await _remoteDatasource.removeCommentAsAdmin(videoId, commentId, reason);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> reportComment(
    String videoId,
    String commentId,
    String reason,
  ) async {
    try {
      await _remoteDatasource.reportComment(videoId, commentId, reason);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
