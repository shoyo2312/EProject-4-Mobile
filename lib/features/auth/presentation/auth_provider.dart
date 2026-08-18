import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/secure_token_storage.dart';
import 'package:tiktok_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/social_sign_in.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => SecureTokenStorage();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) =>
    ApiClient(tokenStorage: ref.watch(tokenStorageProvider));

@Riverpod(keepAlive: true)
SocialSignIn socialSignIn(Ref ref) => SocialSignIn();

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
      remoteDatasource: AuthRemoteDatasource(ref.watch(apiClientProvider)),
      tokenStorage: ref.watch(tokenStorageProvider),
      socialSignIn: ref.watch(socialSignInProvider),
    );

@riverpod
class AuthState extends _$AuthState {
  @override
  FutureOr<UserModel?> build() async {
    final tokenStorage = ref.watch(tokenStorageProvider);
    if (await tokenStorage.readAccessToken() == null) return null;
    try {
      return await ref.read(authRepositoryProvider).getCurrentUser();
    } on UnauthorizedException {
      // Access token invalid and the interceptor's refresh attempt already
      // failed (or there's no refresh token) — sign out for real.
      await tokenStorage.clear();
      return null;
    } on AppException {
      // Network/server hiccup during restore — stay signed out for this
      // session without wiping tokens; retry on next app launch.
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
  }

  /// Returns whether the account still needs an email address, so the caller
  /// can route to the add-email screen. Throws on failure (including
  /// [SocialSignInCancelled]) rather than parking the error in [state]: the
  /// screen shows it, and an AsyncError here would make the router treat a
  /// cancelled tap as a broken session.
  Future<bool> loginWithGoogle() =>
      _social((repo) => repo.loginWithGoogle());

  Future<bool> loginWithFacebook() =>
      _social((repo) => repo.loginWithFacebook());

  /// Finishes a login that came back as [SocialLinkRequired]: the same provider
  /// token, plus the code the server mailed to the address. Signs in as the
  /// account that already held it.
  ///
  /// Deliberately not routed through [_social]: a wrong code must not touch
  /// [state]. Every write here wakes the router's refresh listenable, which
  /// re-resolves /social-link — and on a re-resolve the challenge in
  /// `state.extra` is gone, so the screen would be replaced by /login, taking
  /// with it a provider token that cannot be re-obtained without sending the
  /// user through the provider again. The screen drives its own spinner and
  /// shows its own error, so there is nothing an AsyncLoading here would feed.
  Future<bool> confirmSocialLink({
    required String provider,
    required String token,
    required String otp,
  }) async {
    final outcome = await ref.read(authRepositoryProvider).confirmSocialLink(
          provider: provider,
          token: token,
          otp: otp,
        );
    state = AsyncData(outcome.user);
    return outcome.requiresEmail;
  }

  Future<bool> _social(
    Future<SocialLoginOutcome> Function(AuthRepository repo) call,
  ) async {
    state = const AsyncLoading();
    try {
      final outcome = await call(ref.read(authRepositoryProvider));
      state = AsyncData(outcome.user);
      return outcome.requiresEmail;
    } catch (_) {
      state = const AsyncData(null);
      rethrow;
    }
  }

  // No register() on purpose: /register does not authenticate anyone (the
  // account still needs email verification), so it never yields a signed-in
  // state. RegisterScreen calls AuthRepository.register directly.

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
