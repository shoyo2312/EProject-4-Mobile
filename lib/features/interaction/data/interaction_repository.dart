import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_model.dart';
import 'package:tiktok_mobile/features/interaction/data/interaction_remote_datasource.dart';

class InteractionRepository {
  InteractionRepository(this._remoteDatasource);

  final InteractionRemoteDatasource _remoteDatasource;

  Future<LikeStatus> like(String videoId) async {
    try {
      return await _remoteDatasource.like(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<LikeStatus> unlike(String videoId) async {
    try {
      return await _remoteDatasource.unlike(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<LikeStatus> getLikeStatus(String videoId) async {
    try {
      return await _remoteDatasource.getLikeStatus(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> recordView(String videoId, {required String playId}) async {
    try {
      await _remoteDatasource.recordView(videoId, playId: playId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> recordWatch(
    String videoId, {
    required int watchedMs,
    required int durationMs,
  }) async {
    try {
      await _remoteDatasource.recordWatch(
        videoId,
        watchedMs: watchedMs,
        durationMs: durationMs,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<InteractionCounts> getCounts(String videoId) async {
    try {
      return await _remoteDatasource.getCounts(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> share(String videoId) async {
    try {
      await _remoteDatasource.share(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
