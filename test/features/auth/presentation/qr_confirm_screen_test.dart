import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/qr_login_scan.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/qr_confirm_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/qr_scan_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  const qrId = 'AbCdEfGhIjKlMnOpQrSt12';

  setUp(() {
    authRepository = MockAuthRepository();
    when(() => authRepository.approveQrLogin(any())).thenAnswer((_) async {});
    when(() => authRepository.rejectQrLogin(any())).thenAnswer((_) async {});
  });

  /// The confirm screen pushed over a placeholder, so Cancel/back has
  /// somewhere to go.
  Future<void> pump(WidgetTester tester, {Duration left = const Duration(seconds: 90)}) async {
    final scan = QrLoginScan(
      deviceLabel: 'Chrome on Windows',
      location: 'Hanoi, Vietnam',
      expiresAt: DateTime.now().add(left),
    );
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/confirm',
          builder: (_, _) =>
              QrConfirmScreen(args: QrLoginConfirmArgs(qrId: qrId, scan: scan)),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      child: MaterialApp.router(routerConfig: router),
    ));
    router.push('/confirm');
    await tester.pumpAndSettle();
  }

  testWidgets('names the browser and where it is before asking', (tester) async {
    await pump(tester);

    expect(find.text('Log in on this computer?'), findsOneWidget);
    expect(find.text('Chrome on Windows'), findsOneWidget);
    expect(find.text('Hanoi, Vietnam'), findsOneWidget);
  });

  testWidgets('Log in approves the code and says so', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('qr_confirm_approve')));
    await tester.pumpAndSettle();

    verify(() => authRepository.approveQrLogin(qrId)).called(1);
    verifyNever(() => authRepository.rejectQrLogin(any()));
    expect(find.byKey(const Key('qr_confirm_done')), findsOneWidget);
  });

  testWidgets('Cancel rejects the code so the web stops waiting', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('qr_confirm_cancel')));
    await tester.pumpAndSettle();

    verify(() => authRepository.rejectQrLogin(qrId)).called(1);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a failed approval explains itself and keeps the choice open', (tester) async {
    when(() => authRepository.approveQrLogin(any())).thenThrow(
        const ServerException(410, 'gone', code: 'QR_LOGIN_EXPIRED'));
    await pump(tester);

    await tester.tap(find.byKey(const Key('qr_confirm_approve')));
    await tester.pumpAndSettle();

    expect(find.textContaining('This code has expired'), findsOneWidget);
    expect(find.byKey(const Key('qr_confirm_done')), findsNothing);
  });

  testWidgets('an expired code cannot be approved', (tester) async {
    await pump(tester, left: Duration.zero);

    await tester.tap(find.byKey(const Key('qr_confirm_approve')));
    await tester.pump();

    verifyNever(() => authRepository.approveQrLogin(any()));
    expect(find.textContaining('This code has expired'), findsOneWidget);
  });
}
