import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  factory AppException.fromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 401) {
        return const UnauthorizedException();
      }
      final data = e.response?.data;
      final serverMessage = (data is Map && data['error'] is Map)
          ? (data['error']['message'] as String?) ?? 'Server error'
          : 'Server error';
      return ServerException(statusCode, serverMessage);
    }

    return UnknownException(e.message ?? 'Unknown error');
  }
}

final class NetworkException extends AppException {
  const NetworkException() : super('No internet connection');
}

final class ServerException extends AppException {
  const ServerException(this.statusCode, String message) : super(message);
  final int statusCode;
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Session expired, please log in again');
}

final class UnknownException extends AppException {
  const UnknownException(super.message);
}
