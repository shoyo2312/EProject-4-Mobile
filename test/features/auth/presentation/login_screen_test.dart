import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRepository authRepository;
  late MockTokenStorage tokenStorage;

  setUp(() {
    authRepository = MockAuthRepository();
    tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          tokenStorageProvider.overrideWithValue(tokenStorage),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('submitting valid credentials calls repository.login', (tester) async {
    when(() => authRepository.login(email: 'jane@test.com', password: 'secret12'))
        .thenAnswer((_) async => UserModel(
              id: '1',
              username: 'jane',
              email: 'jane@test.com',
              role: UserRole.user,
              status: UserStatus.active,
              createdAt: DateTime(2026, 1, 1),
            ));

    await pumpLogin(tester);

    await tester.enterText(find.byKey(const Key('login_email_field')), 'jane@test.com');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'secret12');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    verify(() => authRepository.login(email: 'jane@test.com', password: 'secret12')).called(1);
  });

  testWidgets('shows an error message when login fails', (tester) async {
    when(() => authRepository.login(email: 'jane@test.com', password: 'wrong'))
        .thenThrow(Exception('invalid credentials'));

    await pumpLogin(tester);

    await tester.enterText(find.byKey(const Key('login_email_field')), 'jane@test.com');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'wrong');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('invalid credentials'), findsOneWidget);
  });
}
