import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
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

  Future<CommentModel> postComment(String videoId, String text) async {
    try {
      return await _remoteDatasource.postComment(videoId, text);
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
}
