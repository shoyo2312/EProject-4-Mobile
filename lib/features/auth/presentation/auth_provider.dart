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
