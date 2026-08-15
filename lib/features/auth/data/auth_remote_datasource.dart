import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/features/auth/data/social_login_response.dart';
import 'package:tiktok_mobile/features/auth/data/token_response.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'username': username, 'email': email, 'password': password},
    );
    return _unwrap(response.data!, UserModel.fromJson);
  }

  Future<TokenResponse> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'usernameOrEmail': usernameOrEmail, 'password': password},
    );
    return _unwrap(response.data!, TokenResponse.fromJson);
  }

  /// Token exchange: the provider's SDK already signed the user in, this trades
  /// its token for a session of ours. One endpoint per provider — an unknown
  /// provider is a 404 from the router, not a parse error.
  Future<SocialLoginResponse> oauthGoogle(String idToken) =>
      _oauth('google', idToken);

  Future<SocialLoginResponse> oauthFacebook(String accessToken) =>
      _oauth('facebook', accessToken);

  Future<SocialLoginResponse> _oauth(String provider, String token) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/oauth/$provider',
      data: {'token': token},
    );
    return _unwrap(response.data!, SocialLoginResponse.fromJson);
  }

  /// Binds an address to an account created through a provider. Requires the
  /// access token from the social login, and only starts the claim — the
  /// address is not usable until the OTP that follows is verified.
  Future<void> addEmail(String email) {
    return _apiClient.post<void>('/auth/email', data: {'email': email});
  }

  Future<TokenResponse> refresh(String refreshToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return _unwrap(response.data!, TokenResponse.fromJson);
  }

  Future<void> logout(String refreshToken) {
    return _apiClient.post<void>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<UserModel> me() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/auth/me');
    return _unwrap(response.data!, UserModel.fromJson);
  }

  Future<void> verifyEmail({required String email, required String otp}) {
    return _apiClient.post<void>(
      '/auth/verify-email',
      data: {'email': email, 'otp': otp},
    );
  }

  Future<void> resendVerification(String email) {
    return _apiClient.post<void>(
      '/auth/resend-verification',
      data: {'email': email},
    );
  }

  Future<void> forgotPassword(String email) {
    return _apiClient.post<void>(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _apiClient.post<void>(
      '/auth/reset-password',
      data: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
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
}
