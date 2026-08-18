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
      // Not every 401 is a dead session: the gateway sends UNAUTHORIZED for a
      // token it rejected, but auth-service also uses 401 for INVALID_CREDENTIALS
      // and INVALID_SOCIAL_TOKEN. Turning those into "Session expired" hides the
      // real reason a login failed.
      if (statusCode == 401 && (code == null || code == 'UNAUTHORIZED')) {
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

/// 409 SOCIAL_LINK_VERIFICATION_REQUIRED: the provider account's email address
/// already belongs to an account here, and the provider (Facebook) never
/// asserted that the address is verified. The server mailed a code; sending it
/// back together with the same provider token links the two accounts instead of
/// creating a second one.
///
/// Carries the provider token so the confirm step can re-send it — the server
/// verifies it again, so the mailed code alone cannot take over an account.
/// Deliberately says nothing about the account it would merge into: naming it
/// would confirm to a stranger that the address has an account here.
final class SocialLinkRequired extends AppException {
  const SocialLinkRequired({
    required this.provider,
    required this.token,
    required String message,
  }) : super(message);

  /// 'google' or 'facebook' — the path segment of the link endpoint.
  final String provider;
  final String token;
}
