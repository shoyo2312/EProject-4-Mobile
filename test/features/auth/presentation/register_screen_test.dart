import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('submitting valid data calls repository.register', (tester) async {
    final authRepository = MockAuthRepository();
    when(() => authRepository.register(
          email: 'jane@test.com',
          password: 'secret12',
          username: 'jane',
        )).thenAnswer((_) async => const UserModel(
          id: '1',
          username: 'jane',
          email: 'jane@test.com',
        ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.enterText(find.byKey(const Key('register_username_field')), 'jane');
    await tester.enterText(find.byKey(const Key('register_email_field')), 'jane@test.com');
    await tester.enterText(find.byKey(const Key('register_password_field')), 'secret12');
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    verify(() => authRepository.register(
          email: 'jane@test.com',
          password: 'secret12',
          username: 'jane',
        )).called(1);
  });
}
