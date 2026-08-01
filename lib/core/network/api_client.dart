import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/constants/env.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';

const _refreshPath = '/auth/refresh';
const _retriedAfterRefreshKey = 'retriedAfterRefresh';

abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInMillis,
  });
  Future<void> clear();
}

class ApiClient {
  ApiClient({required this.tokenStorage, Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )) {
    this.dio.interceptors.add(
          InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
        );
  }

  final Dio dio;
  final TokenStorage tokenStorage;

  // Shared across concurrent 401s so only one /auth/refresh call is made.
  Future<String?>? _refreshing;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isRefreshCall = err.requestOptions.path == _refreshPath;
    final alreadyRetried = err.requestOptions.extra[_retriedAfterRefreshKey] == true;
    if (err.response?.statusCode != 401 || isRefreshCall || alreadyRetried) {
      handler.next(err);
      return;
    }

    final newAccessToken = await (_refreshing ??= _refreshAccessToken());
    _refreshing = null;
    if (newAccessToken == null) {
      await tokenStorage.clear();
      handler.next(err);
      return;
    }

    try {
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken'
        ..extra[_retriedAfterRefreshKey] = true;
      final response = await dio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  // Calls /auth/refresh directly (not via AuthRemoteDatasource) to avoid a
  // core -> features import; only the access/refresh token strings matter
  // here, not the full UserModel/TokenResponse shape.
  Future<String?> _refreshAccessToken() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await dio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data!,
        (json) => json as Map<String, dynamic>,
      );
      final body = envelope.data!;
      await tokenStorage.saveTokens(
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String,
        expiresInMillis: body['expiresInMillis'] as int,
      );
      return body['accessToken'] as String;
    } on DioException {
      return null;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return dio.post<T>(path, data: data);
  }
}
