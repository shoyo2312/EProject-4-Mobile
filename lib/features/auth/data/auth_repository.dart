import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

class AuthRepository {
  AuthRepository({
    required AuthRemoteDatasource remoteDatasource,
    required TokenStorage tokenStorage,
  })  : _remoteDatasource = remoteDatasource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDatasource _remoteDatasource;
  final TokenStorage _tokenStorage;

  // Backend /register returns the created user only (no tokens); the app
  // then logs in right away per the documented auth flow.
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      await _remoteDatasource.register(
        email: email,
        password: password,
        username: username,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
    return login(email: email, password: password);
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

  Future<UserModel> getCurrentUser() async {
    try {
      return await _remoteDatasource.me();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
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
  }
}
