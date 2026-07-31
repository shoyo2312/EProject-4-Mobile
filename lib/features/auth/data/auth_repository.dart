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

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final tokens = await _remoteDatasource.login(email: email, password: password);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens.user;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final tokens = await _remoteDatasource.register(
        email: email,
        password: password,
        username: username,
      );
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens.user;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> logout() => _tokenStorage.clear();
}
