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

  /// The personalised feed: rank, then hydrate, in two calls.
  ///
  /// Two failure shapes matter to the caller and neither is an error here —
  /// an empty ranking (the 30-minute window is spent), and a shorter list than
  /// the ranking asked for (an id was deleted in between). Both mean "fall
  /// back to the chronological feed", which [FeedNotifier] does.
  Future<List<VideoModel>> fetchRankedFeed({int limit = 10}) async {
    try {
      final ids = await _remoteDatasource.fetchRankedIds(limit: limit);
      if (ids.isEmpty) return [];
      return await _remoteDatasource.fetchByIds(ids);
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
