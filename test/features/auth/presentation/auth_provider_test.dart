import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRepository authRepository;
  late MockTokenStorage tokenStorage;
  late ProviderContainer container;

  final user = UserModel(
    id: '1',
    username: 'jane',
    email: 'jane@test.com',
    role: UserRole.user,
    status: UserStatus.active,
    emailVerified: true,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    authRepository = MockAuthRepository();
    tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('build() starts as null (signed out) when no token is stored', () async {
    final result = await container.read(authStateProvider.future);
    expect(result, isNull);
  });

  test('build() restores the session via /me when an access token exists', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'stored-token');
    when(() => authRepository.getCurrentUser()).thenAnswer((_) async => user);

    final result = await container.read(authStateProvider.future);

    expect(result, user);
  });

  test('build() clears tokens and stays signed out when the token is invalid', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'stale-token');
    when(() => authRepository.getCurrentUser()).thenThrow(const UnauthorizedException());
    when(() => tokenStorage.clear()).thenAnswer((_) async {});

    final result = await container.read(authStateProvider.future);

    expect(result, isNull);
    verify(() => tokenStorage.clear()).called(1);
  });

  test('build() stays signed out without clearing tokens on a network error', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'stored-token');
    when(() => authRepository.getCurrentUser()).thenThrow(
      AppException.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    final result = await container.read(authStateProvider.future);

    expect(result, isNull);
    verifyNever(() => tokenStorage.clear());
  });

  test('login() sets state to the logged-in user', () async {
    when(() => authRepository.login(email: 'jane@test.com', password: 'pw'))
        .thenAnswer((_) async => user);
    await container.read(authStateProvider.future);

    await container.read(authStateProvider.notifier).login(
          email: 'jane@test.com',
          password: 'pw',
        );

    expect(container.read(authStateProvider).value, user);
  });

  test('logout() clears the state back to null', () async {
    when(() => authRepository.login(email: 'jane@test.com', password: 'pw'))
        .thenAnswer((_) async => user);
    when(() => authRepository.logout()).thenAnswer((_) async {});
    await container.read(authStateProvider.future);
    await container.read(authStateProvider.notifier).login(
          email: 'jane@test.com',
          password: 'pw',
        );

    await container.read(authStateProvider.notifier).logout();

    expect(container.read(authStateProvider).value, isNull);
  });
}
