import 'package:tiktok_mobile/features/auth/data/token_response.dart';

/// Mirrors auth-service `SocialLoginResponse`.
///
/// Hand-written rather than freezed: two fields, no copyWith or equality needed
/// anywhere, and it saves a build_runner round trip.
class SocialLoginResponse {
  const SocialLoginResponse({required this.tokens, required this.requiresEmail});

  final TokenResponse tokens;

  /// The account has no email address yet (Facebook never asserts one unless
  /// the user granted `email`). The session is fully usable, but without an
  /// address the account cannot reset a password or be recovered at all, so the
  /// client should collect one.
  final bool requiresEmail;

  factory SocialLoginResponse.fromJson(Map<String, dynamic> json) =>
      SocialLoginResponse(
        tokens: TokenResponse.fromJson(json['tokens'] as Map<String, dynamic>),
        requiresEmail: json['requiresEmail'] as bool? ?? false,
      );
}
