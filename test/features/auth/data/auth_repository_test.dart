import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRemoteDatasource remoteDatasource;
  late MockTokenStorage tokenStorage;
  late AuthRepository repository;

  setUp(() {
    remoteDatasource = MockAuthRemoteDatasource();
    tokenStorage = MockTokenStorage();
    repository = AuthRepository(
      remoteDatasource: remoteDatasource,
      tokenStorage: tokenStorage,
    );
  });

  const user = UserModel(id: '1', username: 'jane', email: 'jane@test.com');
  const tokens = AuthTokens(
    user: user,
    accessToken: 'access',
    refreshToken: 'refresh',
  );

  test('login persists tokens and returns the user on success', () async {
    when(() => remoteDatasource.login(email: 'jane@test.com', password: 'pw'))
        .thenAnswer((_) async => tokens);
    when(() => tokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        )).thenAnswer((_) async {});

    final result = await repository.login(email: 'jane@test.com', password: 'pw');

    expect(result, user);
    verify(() => tokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        )).called(1);
  });

  test('login converts a DioException into an AppException', () async {
    when(() => remoteDatasource.login(email: 'jane@test.com', password: 'wrong'))
        .thenThrow(DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 401,
      ),
      type: DioExceptionType.badResponse,
    ));

    expect(
      () => repository.login(email: 'jane@test.com', password: 'wrong'),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('logout clears stored tokens', () async {
    when(() => tokenStorage.clear()).thenAnswer((_) async {});

    await repository.logout();

    verify(() => tokenStorage.clear()).called(1);
  });
}
