import 'dart:io' show Platform;

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tiktok_mobile/core/constants/env.dart';

/// The user backed out of the provider's sheet. Not an error: callers show
/// nothing and leave the screen as it was.
class SocialSignInCancelled implements Exception {
  const SocialSignInCancelled();
}

class SocialSignInException implements Exception {
  const SocialSignInException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Everything that talks to a provider SDK, kept in one place so
/// AuthRepository stays mockable in tests without a platform channel.
///
/// Both methods return a raw provider token; trading it for a session of ours
/// is auth-service's job (`POST /auth/oauth/{google,facebook}`). Nothing here
/// is trusted — the backend re-verifies the token with Google/Facebook.
class SocialSignIn {
  bool _googleReady = false;
  bool _facebookReady = false;

  /// macOS/Windows/Linux ship no native manifest, so both SDKs need the app
  /// identifiers handed to them at runtime instead.
  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<String> googleIdToken() async {
    try {
      if (!_googleReady) {
        // iOS also reads GIDClientID/GIDServerClientID from Info.plist; passing
        // serverClientId here is what makes Android emit an idToken at all.
        await GoogleSignIn.instance.initialize(
          clientId: Env.googleClientId.isEmpty ? null : Env.googleClientId,
          serverClientId: Env.googleServerClientId,
        );
        _googleReady = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const SocialSignInException(
          'Google returned no ID token. Check that the Web client ID is set '
          'and that this build is signed with a registered SHA-1.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialSignInCancelled();
      }
      throw SocialSignInException('Google sign-in failed: ${e.code.name}');
    }
  }

  Future<String> facebookAccessToken() async {
    if (_isDesktop && !_facebookReady) {
      // Without this the desktop plugin asserts on an empty app id before it
      // ever opens the login window.
      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: Env.facebookAppId,
        cookie: true,
        xfbml: true,
        version: 'v18.0',
      );
      _facebookReady = true;
    }
    // Facebook grants `email` only if asked, and even then the user can decline
    // it — the account then arrives with requiresEmail: true, which is a
    // supported outcome rather than a failure.
    // loginTracking defaults to `limited`, which on iOS hands back an OIDC
    // token instead of a Graph access token — /debug_token rejects it and the
    // backend answers "Social login token is invalid or expired".
    final result = await FacebookAuth.instance.login(
      permissions: const ['public_profile', 'email'],
      loginTracking: LoginTracking.enabled,
    );
    switch (result.status) {
      case LoginStatus.success:
        return result.accessToken!.tokenString;
      case LoginStatus.cancelled:
        throw const SocialSignInCancelled();
      case LoginStatus.failed:
      case LoginStatus.operationInProgress:
        throw SocialSignInException(
          result.message ?? 'Facebook sign-in failed',
        );
    }
  }

  /// Clears the provider-side session too, otherwise the next tap silently
  /// re-uses the same account and "log out" looks broken.
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await FacebookAuth.instance.logOut();
  }
}
