import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:tiktok_mobile/features/auth/data/social_login_response.dart';
import 'package:tiktok_mobile/features/auth/data/social_sign_in.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

/// Outcome of a social login: the signed-in user, plus whether the account
/// still needs an email address bound to it.
typedef SocialLoginOutcome = ({UserModel user, bool requiresEmail});

class AuthRepository {
  AuthRepository({
    required AuthRemoteDatasource remoteDatasource,
    required TokenStorage tokenStorage,
    required SocialSignIn socialSignIn,
  })  : _remoteDatasource = remoteDatasource,
        _tokenStorage = tokenStorage,
        _socialSignIn = socialSignIn;

  final AuthRemoteDatasource _remoteDatasource;
  final TokenStorage _tokenStorage;
  final SocialSignIn _socialSignIn;

  // /register returns the created user only (no tokens) and the account is
  // NOT usable yet: emailVerified is false, so logging in here would always
  // fail with 403 EMAIL_NOT_VERIFIED. The flow is register -> OTP screen ->
  // verify-email -> login (auth doc 3.1).
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      return await _remoteDatasource.register(
        email: email,
        password: password,
        username: username,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  // Backend /login returns tokens only (no user); fetch the profile via
  // /me right after so the caller still gets a UserModel back.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final tokens = await _remoteDatasource.login(
        usernameOrEmail: email,
        password: password,
      );
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresInMillis: tokens.expiresInMillis,
      );
      return await _remoteDatasource.me();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// Sign in at Google, then trade the ID token for our own session. Unlike
  /// /register there is no email-verification gate: Google already asserted the
  /// address, so the user is signed in when this returns.
  Future<SocialLoginOutcome> loginWithGoogle() async {
    final idToken = await _socialSignIn.googleIdToken();
    return _exchange(() => _remoteDatasource.oauthGoogle(idToken));
  }

  /// Facebook never asserts that an address is verified, so accounts created
  /// this way come back with requiresEmail: true and no email at all.
  Future<SocialLoginOutcome> loginWithFacebook() async {
    final token = await _socialSignIn.facebookAccessToken();
    return _exchange(() => _remoteDatasource.oauthFacebook(token));
  }

  Future<SocialLoginOutcome> _exchange(
    Future<SocialLoginResponse> Function() call,
  ) async {
    try {
      final social = await call();
      await _tokenStorage.saveTokens(
        accessToken: social.tokens.accessToken,
        refreshToken: social.tokens.refreshToken,
        expiresInMillis: social.tokens.expiresInMillis,
      );
      // Tokens must be stored before /me — the interceptor reads them from
      // storage to attach the Authorization header.
      final user = await _remoteDatasource.me();
      return (user: user, requiresEmail: social.requiresEmail);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// Claims an address for an account that has none. Only starts the claim; the
  /// address stays unverified until the OTP that follows is confirmed through
  /// the existing verify-email flow.
  Future<void> addEmail(String email) async {
    try {
      await _remoteDatasource.addEmail(email);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      return await _remoteDatasource.me();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> verifyEmail({required String email, required String otp}) async {
    try {
      await _remoteDatasource.verifyEmail(email: email, otp: otp);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _remoteDatasource.resendVerification(email);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _remoteDatasource.forgotPassword(email);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _remoteDatasource.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
    // A successful reset kills every session server-side, including this
    // device's still-unexpired access token (auth doc 3.9) — keeping the old
    // tokens around would only produce a confusing run of 401s.
    await _tokenStorage.clear();
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _remoteDatasource.logout(refreshToken);
      } on DioException {
        // Best-effort server-side blacklist; local tokens are cleared
        // regardless so the user is signed out either way.
      }
    }
    await _tokenStorage.clear();
    // Without this the provider SDK keeps its own session and the next
    // "Continue with Google" tap silently signs the same account back in —
    // logging out would look broken.
    await _socialSignIn.signOut();
  }
}
