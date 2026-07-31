import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/constants/env.dart';

abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
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
    // Token refresh-on-401 is added in a later task once AuthRepository
    // exists; for now errors pass through unchanged.
    handler.next(err);
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
