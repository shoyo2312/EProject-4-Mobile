import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
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
  FutureOr<UserModel?> build() {
    // No "restore session" call to the backend yet (endpoint not defined
    // in the provisional contract) — app always starts signed out.
    return null;
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
