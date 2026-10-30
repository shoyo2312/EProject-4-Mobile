import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/user/data/user_profile_model.dart';

class UserRemoteDatasource {
  UserRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<UserProfileModel> getMyProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/users/me');
    return _unwrap(response.data!, UserProfileModel.fromJson);
  }

  // Server does true partial update: only keys present in [changes] are
  // touched. Callers must omit fields the user didn't edit rather than
  // sending the full form (see doc section 3.2).
  Future<UserProfileModel> updateMyProfile(Map<String, dynamic> changes) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/users/me',
      data: changes,
    );
    return _unwrap(response.data!, UserProfileModel.fromJson);
  }

  /// The only way to set an avatar. `PATCH /me` takes an `avatarUrl`, but it
  /// is validated against the server's own allow-list, so a client has no URL
  /// it is permitted to send until something has already stored the bytes —
  /// which is this call (user doc 3.2b).
  ///
  /// Answers the whole profile, exactly as `PATCH /me` does, so the caller
  /// refreshes from one response either way.
  Future<UserProfileModel> uploadAvatar(
    File file, {
    required String contentType,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/users/me/avatar',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          contentType: DioMediaType.parse(contentType),
        ),
      }),
    );
    return _unwrap(response.data!, UserProfileModel.fromJson);
  }

  Future<UserProfileModel> getProfile(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/users/$userId');
    return _unwrap(response.data!, UserProfileModel.fromJson);
  }

  /// Many profiles in one request. The array can come back **shorter** than
  /// [ids] — ids that do not exist, or that a block relation hides, are simply
  /// dropped — so callers must key the result by `userId` and never zip it
  /// against [ids] by position (user doc 3.3b). At most 100 ids per call.
  Future<List<UserProfileModel>> getProfiles(List<String> ids) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users',
      queryParameters: {'ids': ids.join(',')},
    );
    final body = ApiResponse<List<dynamic>>.fromJson(
      response.data!,
      (json) => json as List<dynamic>,
    ).data!;
    return body
        .map((e) => UserProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /users/search` — accounts whose handle or display name contains
  /// [query], most-followed first. Needs a token. Blocked accounts are left
  /// out by the server, and a blank [query] is an empty page.
  Future<PageResponse<UserProfileModel>> searchUsers(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/search',
      queryParameters: {'q': query, 'page': page, 'size': size},
    );
    return _unwrapPage(response.data!);
  }

  Future<void> follow(String userId) {
    return _apiClient.post<void>('/users/$userId/follow');
  }

  Future<void> unfollow(String userId) {
    return _apiClient.delete<void>('/users/$userId/follow');
  }

  Future<PageResponse<UserProfileModel>> getFollowers(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/$userId/followers',
      queryParameters: {'page': page, 'size': size},
    );
    return _unwrapPage(response.data!);
  }

  Future<PageResponse<UserProfileModel>> getFollowing(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/$userId/following',
      queryParameters: {'page': page, 'size': size},
    );
    return _unwrapPage(response.data!);
  }

  Future<void> block(String userId) {
    return _apiClient.post<void>('/users/$userId/block');
  }

  Future<void> unblock(String userId) {
    return _apiClient.delete<void>('/users/$userId/block');
  }

  Future<PageResponse<UserProfileModel>> getBlocked({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/me/blocked',
      queryParameters: {'page': page, 'size': size},
    );
    return _unwrapPage(response.data!);
  }

  Future<void> mute(String userId) {
    return _apiClient.post<void>('/users/$userId/mute');
  }

  Future<void> unmute(String userId) {
    return _apiClient.delete<void>('/users/$userId/mute');
  }

  Future<PageResponse<UserProfileModel>> getMuted({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/me/muted',
      queryParameters: {'page': page, 'size': size},
    );
    return _unwrapPage(response.data!);
  }

  T _unwrap<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final envelope = ApiResponse<T>.fromJson(
      body,
      (json) => fromJson(json as Map<String, dynamic>),
    );
    return envelope.data!;
  }

  PageResponse<UserProfileModel> _unwrapPage(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(data, UserProfileModel.fromJson);
  }
}
