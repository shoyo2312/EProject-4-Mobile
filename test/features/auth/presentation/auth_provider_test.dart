import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late ProviderContainer container;

  const user = UserModel(id: '1', username: 'jane', email: 'jane@test.com');

  setUp(() {
    authRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    );
  });

  tearDown(() => container.dispose());

  test('build() starts as null (signed out) when no session', () async {
    final result = await container.read(authStateProvider.future);
    expect(result, isNull);
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
