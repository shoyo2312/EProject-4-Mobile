import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/features/user/data/page_response.dart';
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

  Future<UserProfileModel> getProfile(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/users/$userId');
    return _unwrap(response.data!, UserProfileModel.fromJson);
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
