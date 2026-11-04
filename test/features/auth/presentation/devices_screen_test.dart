import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/session_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/devices_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  final phone = SessionModel.fromJson({
    'id': 7340032000000000001,
    'deviceType': 'MOBILE',
    'deviceLabel': 'Nowa app on Android 14 · Samsung SM-A525F',
    'deviceModel': 'Samsung SM-A525F',
    'ipAddress': '113.161.1.1',
    'location': 'Bien Hoa, Dong Nai, Vietnam',
    'signedInAt': '2026-11-03T02:41:00Z',
    'lastActiveAt': '2026-11-03T03:00:00Z',
    'current': true,
  });
  final laptop = SessionModel.fromJson({
    'id': 7340032000000000002,
    'deviceType': 'DESKTOP',
    'deviceLabel': 'Chrome on Windows 11',
    'location': 'Hanoi, Vietnam',
    'signedInAt': '2026-11-02T08:00:00Z',
    'lastActiveAt': '2026-11-03T01:00:00Z',
    'current': false,
  });

  setUp(() {
    authRepository = MockAuthRepository();
    when(() => authRepository.sessions()).thenAnswer((_) async => [phone, laptop]);
    when(() => authRepository.signOutSession(any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      child: const MaterialApp(home: DevicesScreen()),
    ));
    await tester.pumpAndSettle();
  }

  test('a server row parses, unknown device types included', () {
    expect(phone.id, '7340032000000000001');
    expect(phone.deviceType, DeviceType.mobile);
    final odd = SessionModel.fromJson({
      'id': 1,
      'deviceType': 'TV',
      'signedInAt': '2026-11-03T02:41:00Z',
      'lastActiveAt': '2026-11-03T02:41:00Z',
    });
    expect(odd.deviceType, DeviceType.unknown);
    expect(odd.current, isFalse);
  });

  testWidgets('lists each device with its place, and marks this one', (tester) async {
    await pump(tester);

    expect(find.text('Nowa app on Android 14 · Samsung SM-A525F'), findsOneWidget);
    expect(find.text('Chrome on Windows 11'), findsOneWidget);
    expect(find.text('Bien Hoa, Dong Nai, Vietnam'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
  });

  testWidgets('another device is signed out remotely after confirming', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(Key('session_sign_out_${laptop.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('devices_confirm_sign_out')));
    await tester.pumpAndSettle();

    verify(() => authRepository.signOutSession(laptop.id)).called(1);
    expect(find.text('Chrome on Windows 11'), findsNothing);
    expect(find.text('Nowa app on Android 14 · Samsung SM-A525F'), findsOneWidget);
  });
}
