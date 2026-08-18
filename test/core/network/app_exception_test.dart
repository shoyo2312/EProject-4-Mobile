import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';

void main() {
  group('AppException.fromDioException', () {
    test('maps connection errors to NetworkException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/feed'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = AppException.fromDioException(dioException);

      expect(result, isA<NetworkException>());
    });

    test('maps 401 responses to UnauthorizedException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/feed'),
        response: Response(
          requestOptions: RequestOptions(path: '/feed'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      final result = AppException.fromDioException(dioException);

      expect(result, isA<UnauthorizedException>());
    });

    test('keeps a 401 with a business error code as ServerException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/oauth/facebook'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/oauth/facebook'),
          statusCode: 401,
          data: {
            'code': 'INVALID_SOCIAL_TOKEN',
            'message': 'Social login token is invalid or expired',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final result = AppException.fromDioException(dioException) as ServerException;

      expect(result.code, 'INVALID_SOCIAL_TOKEN');
      expect(result.message, 'Social login token is invalid or expired');
    });

    test('maps other bad responses to ServerException with status code', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/feed'),
        response: Response(
          requestOptions: RequestOptions(path: '/feed'),
          statusCode: 500,
          data: {'code': 'INTERNAL_ERROR', 'message': 'boom'},
        ),
        type: DioExceptionType.badResponse,
      );

      final result = AppException.fromDioException(dioException) as ServerException;

      expect(result.statusCode, 500);
      expect(result.message, 'boom');
      expect(result.code, 'INTERNAL_ERROR');
    });
  });

  test('toString() returns the human-readable message, not the type name', () {
    expect(const UnauthorizedException().toString(), 'Session expired, please log in again');
  });
}
