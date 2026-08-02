import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/user/data/page_response.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';
import 'package:tiktok_mobile/features/user/data/user_remote_datasource.dart';

class UserRepository {
  UserRepository(this._remoteDatasource);

  final UserRemoteDatasource _remoteDatasource;

  // Profile creation happens asynchronously via Kafka right after
  // register/login, so GET /me can 404 with USER_PROFILE_NOT_FOUND for a
  // short window. Retry lightly instead of surfacing a hard error
  // (doc section 3.1).
  Future<UserProfileModel> getMyProfile() async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _remoteDatasource.getMyProfile();
      } on DioException catch (e) {
        final exception = AppException.fromDioException(e);
        final isMissingProfile = exception is ServerException &&
            exception.statusCode == 404 &&
            exception.code == 'USER_PROFILE_NOT_FOUND';
        if (!isMissingProfile || attempt == maxAttempts) {
          throw exception;
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    throw StateError('unreachable');
  }

  Future<UserProfileModel> updateMyProfile(Map<String, dynamic> changes) async {
    try {
      return await _remoteDatasource.updateMyProfile(changes);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<UserProfileModel> getProfile(String userId) async {
    try {
      return await _remoteDatasource.getProfile(userId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> follow(String userId) async {
    try {
      await _remoteDatasource.follow(userId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> unfollow(String userId) async {
    try {
      await _remoteDatasource.unfollow(userId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<PageResponse<UserProfileModel>> getFollowers(
    String userId, {
    int page = 0,
  }) async {
    try {
      return await _remoteDatasource.getFollowers(userId, page: page);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<PageResponse<UserProfileModel>> getFollowing(
    String userId, {
    int page = 0,
  }) async {
    try {
      return await _remoteDatasource.getFollowing(userId, page: page);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> block(String userId) async {
    try {
      await _remoteDatasource.block(userId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> unblock(String userId) async {
    try {
      await _remoteDatasource.unblock(userId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<PageResponse<UserProfileModel>> getBlocked({int page = 0}) async {
    try {
      return await _remoteDatasource.getBlocked(page: page);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> mute(String userId) async {
    try {
      await _remoteDatasource.mute(userId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> unmute(String userId) async {
    try {
      await _remoteDatasource.unmute(userId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<PageResponse<UserProfileModel>> getMuted({int page = 0}) async {
    try {
      return await _remoteDatasource.getMuted(page: page);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
