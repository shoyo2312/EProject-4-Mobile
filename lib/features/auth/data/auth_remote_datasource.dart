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
    required String turnstileToken,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'turnstileToken': turnstileToken,
      },
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
  Future<SocialLoginResponse> oauth(String provider, String token) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/oauth/$provider',
      data: {'token': token},
    );
    return _unwrap(response.data!, SocialLoginResponse.fromJson);
  }

  /// Answers a 409 SOCIAL_LINK_VERIFICATION_REQUIRED: the same provider token
  /// plus the code the server mailed to the address. Both are required — the
  /// token is verified again here, so the code on its own proves only that
  /// someone can read the mailbox.
  ///
  /// Returns a session for the *existing* account, with the provider now
  /// linked to it. No second account is created.
  Future<SocialLoginResponse> linkOauth(
    String provider,
    String token,
    String otp,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/oauth/$provider/link',
      data: {'token': token, 'otp': otp},
    );
    return _unwrap(response.data!, SocialLoginResponse.fromJson);
  }

  /// Binds an address to an account created through a provider. Requires the
  /// access token from the social login, and only starts the claim — the
  /// address is not usable until the OTP that follows is verified.
  ///
  /// Returns the resend ticket for `/resend-verification` to this address.
  Future<String?> addEmail(String email, {required String turnstileToken}) {
    return _sendCode('/auth/email', email, turnstileToken: turnstileToken);
  }

  /// Every call that mails a code carries a Turnstile token, or the
  /// `resendTicket` an earlier send to the same address in the same flow
  /// returned (auth doc §3). Returns the ticket to keep for the next resend;
  /// it can be null, and then the next send needs Turnstile again.
  Future<String?> _sendCode(
    String path,
    String email, {
    String? turnstileToken,
    String? resendTicket,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      path,
      data: {
        'email': email,
        'turnstileToken': ?turnstileToken,
        'resendTicket': ?resendTicket,
      },
    );
    final data = response.data?['data'];
    return data is Map<String, dynamic> ? data['resendTicket'] as String? : null;
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

  Future<String?> resendVerification(
    String email, {
    String? turnstileToken,
    String? resendTicket,
  }) {
    return _sendCode(
      '/auth/resend-verification',
      email,
      turnstileToken: turnstileToken,
      resendTicket: resendTicket,
    );
  }

  Future<String?> forgotPassword(
    String email, {
    String? turnstileToken,
    String? resendTicket,
  }) {
    return _sendCode(
      '/auth/forgot-password',
      email,
      turnstileToken: turnstileToken,
      resendTicket: resendTicket,
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
