import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

class AuthTokens {
  const AuthTokens({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserModel user;
  final String accessToken;
  final String refreshToken;
}

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parseTokens(response.data!);
  }

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password, 'username': username},
    );
    return _parseTokens(response.data!);
  }

  AuthTokens _parseTokens(Map<String, dynamic> data) {
    final body = data['data'] as Map<String, dynamic>;
    return AuthTokens(
      user: UserModel.fromJson(body['user'] as Map<String, dynamic>),
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
    );
  }
}
