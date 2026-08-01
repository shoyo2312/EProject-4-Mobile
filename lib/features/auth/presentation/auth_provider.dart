import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/secure_token_storage.dart';
import 'package:tiktok_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => SecureTokenStorage();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) =>
    ApiClient(tokenStorage: ref.watch(tokenStorageProvider));

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
      remoteDatasource: AuthRemoteDatasource(ref.watch(apiClientProvider)),
      tokenStorage: ref.watch(tokenStorageProvider),
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

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            username: username,
          ),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
