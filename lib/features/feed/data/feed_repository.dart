import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class FeedRepository {
  FeedRepository(this._remoteDatasource);

  final FeedRemoteDatasource _remoteDatasource;

  Future<VideoPage> fetchFeed({String? cursor, int size = 20}) async {
    try {
      return await _remoteDatasource.fetchFeed(cursor: cursor, size: size);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<PageResponse<VideoModel>> getUserVideos(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      return await _remoteDatasource.getUserVideos(userId, page: page, size: size);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<VideoModel> getVideo(String videoId) async {
    try {
      return await _remoteDatasource.getVideo(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deleteVideo(String videoId) async {
    try {
      await _remoteDatasource.deleteVideo(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
