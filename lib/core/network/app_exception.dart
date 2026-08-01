import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;

  factory AppException.fromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode ?? 0;
      final data = e.response?.data;
      // Error envelope: {success, data, code, message, timestamp} — code
      // and message are top-level siblings of data, not a nested "error".
      final code = (data is Map) ? data['code'] as String? : null;
      final serverMessage =
          (data is Map) ? (data['message'] as String?) ?? 'Server error' : 'Server error';
      if (statusCode == 401) {
        return const UnauthorizedException();
      }
      return ServerException(statusCode, serverMessage, code: code);
    }

    return UnknownException(e.message ?? 'Unknown error');
  }
}

final class NetworkException extends AppException {
  const NetworkException() : super('No internet connection');
}

final class ServerException extends AppException {
  const ServerException(this.statusCode, String message, {this.code}) : super(message);
  final int statusCode;
  // Machine-readable error code (e.g. TOO_MANY_LOGIN_ATTEMPTS) for UI to
  // map to a localized string instead of showing the raw server message.
  final String? code;
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Session expired, please log in again');
}

final class UnknownException extends AppException {
  const UnknownException(super.message);
}
