import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/social_login_response.dart';
import 'package:tiktok_mobile/features/auth/data/social_sign_in.dart';
import 'package:tiktok_mobile/features/auth/data/token_response.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockSocialSignIn extends Mock implements SocialSignIn {}

void main() {
  late MockAuthRemoteDatasource remoteDatasource;
  late MockTokenStorage tokenStorage;
  late MockSocialSignIn socialSignIn;
  late AuthRepository repository;

  setUp(() {
    remoteDatasource = MockAuthRemoteDatasource();
    tokenStorage = MockTokenStorage();
    socialSignIn = MockSocialSignIn();
    when(() => socialSignIn.signOut()).thenAnswer((_) async {});
    repository = AuthRepository(
      remoteDatasource: remoteDatasource,
      tokenStorage: tokenStorage,
      socialSignIn: socialSignIn,
    );
  });

  final user = UserModel(
    id: '1',
    username: 'jane',
    email: 'jane@test.com',
    role: UserRole.user,
    status: UserStatus.active,
    emailVerified: true,
    createdAt: DateTime(2026, 1, 1),
  );
  const tokens = TokenResponse(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresInMillis: 900000,
  );

  test('login persists tokens and returns the user fetched via /me', () async {
    when(() => remoteDatasource.login(usernameOrEmail: 'jane@test.com', password: 'pw'))
        .thenAnswer((_) async => tokens);
    when(() => tokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        )).thenAnswer((_) async {});
    when(() => remoteDatasource.me()).thenAnswer((_) async => user);

    final result = await repository.login(email: 'jane@test.com', password: 'pw');

    expect(result, user);
    verify(() => tokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        )).called(1);
    verify(() => remoteDatasource.me()).called(1);
  });

  test('login converts a DioException into an AppException', () async {
    when(() => remoteDatasource.login(usernameOrEmail: 'jane@test.com', password: 'wrong'))
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

  test('social login persists tokens and carries requiresEmail through', () async {
    // Facebook accounts arrive with no email; the flag is what routes the user
    // to the add-email screen, so losing it would strand them without one.
    when(() => socialSignIn.facebookAccessToken())
        .thenAnswer((_) async => 'fb-token');
    when(() => remoteDatasource.oauth('facebook', 'fb-token')).thenAnswer(
      (_) async =>
          const SocialLoginResponse(tokens: tokens, requiresEmail: true),
    );
    when(() => tokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        )).thenAnswer((_) async {});
    when(() => remoteDatasource.me()).thenAnswer((_) async => user);

    final result = await repository.loginWithFacebook();

    expect(result.user, user);
    expect(result.requiresEmail, isTrue);
    verify(() => tokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        )).called(1);
  });

  test('a cancelled provider sheet never reaches the backend', () async {
    when(() => socialSignIn.googleIdToken())
        .thenThrow(const SocialSignInCancelled());

    await expectLater(
      repository.loginWithGoogle(),
      throwsA(isA<SocialSignInCancelled>()),
    );
    verifyNever(() => remoteDatasource.oauth(any(), any()));
  });

  test('an address owned by another account keeps the provider token', () async {
    // The token is the half of the proof the mailed code cannot supply. Drop it
    // here and the confirm step has nothing to send, which is how this used to
    // end in a second account.
    when(() => socialSignIn.facebookAccessToken())
        .thenAnswer((_) async => 'fb-token');
    when(() => remoteDatasource.oauth('facebook', 'fb-token')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/oauth/facebook'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/oauth/facebook'),
          statusCode: 409,
          data: const {
            'success': false,
            'code': 'SOCIAL_LINK_VERIFICATION_REQUIRED',
            'message': 'Enter the code we emailed to confirm this address',
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    await expectLater(
      repository.loginWithFacebook(),
      throwsA(
        isA<SocialLinkRequired>()
            .having((e) => e.provider, 'provider', 'facebook')
            .having((e) => e.token, 'token', 'fb-token'),
      ),
    );
    verifyNever(() => tokenStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ));
  });

  test('confirming the mailed code signs in as the existing account', () async {
    when(() => remoteDatasource.linkOauth('facebook', 'fb-token', '123456'))
        .thenAnswer(
      (_) async =>
          const SocialLoginResponse(tokens: tokens, requiresEmail: false),
    );
    when(() => tokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        )).thenAnswer((_) async {});
    when(() => remoteDatasource.me()).thenAnswer((_) async => user);

    final result = await repository.confirmSocialLink(
      provider: 'facebook',
      token: 'fb-token',
      otp: '123456',
    );

    expect(result.user, user);
    expect(result.requiresEmail, isFalse);
  });

  test('register returns the new user without logging in', () async {
    // The account still has emailVerified = false, so an automatic /login
    // here would always come back 403 EMAIL_NOT_VERIFIED.
    when(() => remoteDatasource.register(
          email: 'jane@test.com',
          password: 'pw',
          username: 'jane',
        )).thenAnswer((_) async => user);

    final result = await repository.register(
      email: 'jane@test.com',
      password: 'pw',
      username: 'jane',
    );

    expect(result, user);
    verifyNever(
      () => remoteDatasource.login(
        usernameOrEmail: any(named: 'usernameOrEmail'),
        password: any(named: 'password'),
      ),
    );
    verifyNever(() => tokenStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ));
  });

  test('resetPassword clears local tokens, since the server killed them', () async {
    when(() => remoteDatasource.resetPassword(
          email: 'jane@test.com',
          otp: '123456',
          newPassword: 'newpw123',
        )).thenAnswer((_) async {});
    when(() => tokenStorage.clear()).thenAnswer((_) async {});

    await repository.resetPassword(
      email: 'jane@test.com',
      otp: '123456',
      newPassword: 'newpw123',
    );

    verify(() => tokenStorage.clear()).called(1);
  });

  test('getCurrentUser returns the /me profile', () async {
    when(() => remoteDatasource.me()).thenAnswer((_) async => user);

    final result = await repository.getCurrentUser();

    expect(result, user);
  });

  test('getCurrentUser converts a DioException into an AppException', () async {
    when(() => remoteDatasource.me()).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/auth/me'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/me'),
        statusCode: 401,
      ),
      type: DioExceptionType.badResponse,
    ));

    expect(
      () => repository.getCurrentUser(),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('logout calls the server to blacklist the token then clears storage', () async {
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh');
    when(() => remoteDatasource.logout('refresh')).thenAnswer((_) async {});
    when(() => tokenStorage.clear()).thenAnswer((_) async {});

    await repository.logout();

    verify(() => remoteDatasource.logout('refresh')).called(1);
    verify(() => tokenStorage.clear()).called(1);
  });

  test('logout still clears local storage even if the server call fails', () async {
    when(() => tokenStorage.readRefreshToken()).thenAnswer((_) async => 'refresh');
    when(() => remoteDatasource.logout('refresh')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/auth/logout'),
      type: DioExceptionType.connectionError,
    ));
    when(() => tokenStorage.clear()).thenAnswer((_) async {});

    await repository.logout();

    verify(() => tokenStorage.clear()).called(1);
  });
}
