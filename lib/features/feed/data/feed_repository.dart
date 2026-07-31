import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class FeedRepository {
  FeedRepository(this._remoteDatasource);

  final FeedRemoteDatasource _remoteDatasource;

  Future<FeedPage> fetchFeed({String? cursor}) async {
    try {
      return await _remoteDatasource.fetchFeed(cursor: cursor);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<VideoModel> toggleLike(String videoId) async {
    try {
      return await _remoteDatasource.toggleLike(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<VideoModel> toggleSave(String videoId) async {
    try {
      return await _remoteDatasource.toggleSave(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
