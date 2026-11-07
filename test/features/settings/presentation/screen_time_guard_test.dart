import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/data/settings_repository.dart';
import 'package:tiktok_mobile/features/settings/presentation/screen_time_guard.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_provider.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_rules.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class _SignedIn extends AuthState {
  @override
  FutureOr<UserModel?> build() => UserModel(
    id: '1',
    username: 'jane',
    role: UserRole.user,
    status: UserStatus.active,
    emailVerified: true,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockSettingsRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockSettingsRepository();
    when(
      () => repo.sendScreenTimeHeartbeat(any(), any()),
    ).thenAnswer((_) async {});
  });

  /// Today already [usedSeconds] on the server.
  void usedToday(int usedSeconds) {
    when(() => repo.getScreenTimeWeek(any())).thenAnswer((inv) async {
      return ScreenTimeWeek(
        weekStart: inv.positionalArguments.first as String,
        days: [
          ScreenTimeDay(
            date: localDate(DateTime.now()),
            daySeconds: usedSeconds,
          ),
        ],
      );
    });
  }

  Future<GoRouter> pump(WidgetTester tester, UserSettings settings) async {
    when(() => repo.getSettings()).thenAnswer((_) async => settings);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const Scaffold(body: Text('settings')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith(_SignedIn.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => ScreenTimeGuard(router: router, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// The guard's timer outlives the test otherwise.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  const limited = UserSettings(
    screenTimeLimitMinutes: 10,
    hasScreenTimePasscode: true,
  );
  final limitCover = find.byKey(const Key('screen_time_limit_cover'));

  testWidgets('covers the app at the limit; the passcode lifts it', (
    tester,
  ) async {
    usedToday(700);
    when(
      () => repo.verifyScreenTimePasscode('0000'),
    ).thenAnswer((_) async => false);
    when(
      () => repo.verifyScreenTimePasscode('1234'),
    ).thenAnswer((_) async => true);
    await pump(tester, limited);

    expect(limitCover, findsOneWidget);

    await tester.enterText(find.byKey(const Key('passcode_input')), '0000');
    await tester.pumpAndSettle();
    expect(find.text('Incorrect passcode'), findsOneWidget);
    expect(limitCover, findsOneWidget);

    await tester.enterText(find.byKey(const Key('passcode_input')), '1234');
    await tester.pumpAndSettle();
    expect(limitCover, findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('nowa:screen-time-unlocked:1'),
      localDate(DateTime.now()),
    );
    await unmount(tester);
  });

  testWidgets('under the limit, nothing covers', (tester) async {
    usedToday(300);
    await pump(tester, limited);

    expect(limitCover, findsNothing);
    await unmount(tester);
  });

  testWidgets('no passcode, no lock', (tester) async {
    usedToday(5000);
    await pump(tester, const UserSettings(screenTimeLimitMinutes: 10));

    expect(limitCover, findsNothing);
    verifyNever(() => repo.getScreenTimeWeek(any()));
    await unmount(tester);
  });

  testWidgets('the settings pages are never covered', (tester) async {
    usedToday(700);
    final router = await pump(tester, limited);
    expect(limitCover, findsOneWidget);

    router.go('/settings');
    await tester.pumpAndSettle();

    expect(limitCover, findsNothing);
    expect(find.text('settings'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('sleep hours cover the app until "Return for now"', (
    tester,
  ) async {
    final now = DateTime.now().subtract(const Duration(hours: 1));
    String two(int n) => n.toString().padLeft(2, '0');
    await pump(
      tester,
      UserSettings(sleepHoursStart: '${two(now.hour)}:${two(now.minute)}'),
    );

    expect(find.byKey(const Key('sleep_hours_cover')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sleep_hours_return')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sleep_hours_cover')), findsNothing);
    expect(
      find.text("We'll remind you again after 1 hour on Nowa"),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('a minute in the app sends one heartbeat', (tester) async {
    await pump(tester, const UserSettings());

    await tester.pump(const Duration(seconds: 60));

    verify(
      () => repo.sendScreenTimeHeartbeat(
        60,
        ianaTimeZone(DateTime.now().timeZoneOffset),
      ),
    ).called(1);
    await unmount(tester);
  });
}
