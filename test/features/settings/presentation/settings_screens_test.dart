import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/data/settings_repository.dart';
import 'package:tiktok_mobile/features/settings/presentation/daily_screen_time_screen.dart';
import 'package:tiktok_mobile/features/settings/presentation/keyword_filters_screen.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_provider.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_screen.dart';
import 'package:tiktok_mobile/features/settings/presentation/sleep_hours_screen.dart';

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

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    repo = MockSettingsRepository();
    when(
      () => repo.getSettings(),
    ).thenAnswer((_) async => const UserSettings());
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(path: '/screen', builder: (_, _) => screen),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith(_SignedIn.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/screen');
    await tester.pumpAndSettle();
  }

  group('Settings and privacy', () {
    testWidgets('shows the three sections, without download or muted', (
      tester,
    ) async {
      await pump(tester, const SettingsScreen());

      expect(find.text('Privacy'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Content preferences'), 200);
      expect(find.text('Screen time'), findsOneWidget);
      expect(find.text('Content preferences'), findsOneWidget);
      expect(find.text('Download your data'), findsNothing);
      expect(find.text('Muted accounts'), findsNothing);
    });

    testWidgets('Private account is saved straight away', (tester) async {
      when(
        () => repo.updateSettings({'privateAccount': true}),
      ).thenAnswer((_) async => const UserSettings(privateAccount: true));
      await pump(tester, const SettingsScreen());

      await tester.tap(find.byKey(const Key('settings_private_account')));
      await tester.pumpAndSettle();

      verify(() => repo.updateSettings({'privateAccount': true})).called(1);
      expect(
        tester
            .widget<Switch>(find.byKey(const Key('settings_private_account')))
            .value,
        isTrue,
      );
    });

    testWidgets('a refused switch goes back', (tester) async {
      when(
        () => repo.updateSettings(any()),
      ).thenThrow(const NetworkException());
      await pump(tester, const SettingsScreen());

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_weekly_screen_time')),
        200,
      );
      await tester.tap(find.byKey(const Key('settings_weekly_screen_time')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Switch>(
              find.byKey(const Key('settings_weekly_screen_time')),
            )
            .value,
        isTrue,
      );
    });

    testWidgets('picking a comment audience sends its enum', (tester) async {
      when(
        () => repo.updateSettings({'commentAudience': 'FRIENDS'}),
      ).thenAnswer(
        (_) async =>
            const UserSettings(commentAudience: SettingsAudience.friends),
      );
      await pump(tester, const SettingsScreen());

      await tester.tap(find.byKey(const Key('settings_comment_audience')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('audience_friends')));
      await tester.pumpAndSettle();

      verify(
        () => repo.updateSettings({'commentAudience': 'FRIENDS'}),
      ).called(1);
      expect(find.text('Friends'), findsOneWidget); // the row's value
    });
  });

  group('Daily screen time', () {
    testWidgets('the first limit asks for a passcode, twice', (tester) async {
      when(() => repo.updateSettings(any())).thenAnswer(
        (_) async => const UserSettings(
          screenTimeLimitMinutes: 60,
          hasScreenTimePasscode: true,
        ),
      );
      await pump(tester, const DailyScreenTimeScreen());

      await tester.tap(find.byKey(const Key('daily_limit_switch')));
      await tester.pump();
      // Nothing chosen yet: Done stays off.
      await tester.tap(find.byKey(const Key('daily_limit_done')));
      await tester.pump();
      verifyNever(() => repo.updateSettings(any()));

      await tester.tap(find.byKey(const Key('daily_limit_preset_60')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('daily_limit_done')));
      await tester.pumpAndSettle();

      expect(find.text('Create a passcode'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('passcode_input')), '1234');
      await tester.pump();
      expect(find.text('Confirm passcode'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('passcode_input')), '1234');
      await tester.pumpAndSettle();

      verify(
        () => repo.updateSettings({
          'screenTimeLimitMinutes': 60,
          'screenTimeLimitsByDay': null,
          'screenTimePasscode': '1234',
        }),
      ).called(1);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('a mismatched confirmation starts over', (tester) async {
      await pump(tester, const DailyScreenTimeScreen());

      await tester.tap(find.byKey(const Key('daily_limit_switch')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('daily_limit_preset_40')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('daily_limit_done')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('passcode_input')), '1234');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('passcode_input')), '9999');
      await tester.pump();

      expect(find.text("Passcodes don't match"), findsOneWidget);
      expect(find.text('Create a passcode'), findsOneWidget);
      verifyNever(() => repo.updateSettings(any()));
    });

    testWidgets('turning it off clears both shapes, no passcode asked', (
      tester,
    ) async {
      when(() => repo.getSettings()).thenAnswer(
        (_) async => const UserSettings(
          screenTimeLimitsByDay: [60, 60, 60, 60, 60, 90, 90],
          hasScreenTimePasscode: true,
        ),
      );
      when(
        () => repo.updateSettings(any()),
      ).thenAnswer((_) async => const UserSettings());
      await pump(tester, const DailyScreenTimeScreen());

      await tester.tap(find.byKey(const Key('daily_limit_switch')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('daily_limit_done')));
      await tester.pumpAndSettle();

      verify(
        () => repo.updateSettings({
          'screenTimeLimitMinutes': null,
          'screenTimeLimitsByDay': null,
        }),
      ).called(1);
    });
  });

  testWidgets('Sleep hours sends only the start', (tester) async {
    when(
      () => repo.updateSettings(any()),
    ).thenAnswer((_) async => const UserSettings(sleepHoursStart: '22:00'));
    await pump(tester, const SleepHoursSettingsScreen());

    expect(find.text('06:00 AM'), findsOneWidget); // 22:00 + 8h
    await tester.tap(find.byKey(const Key('sleep_hours_switch')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sleep_hours_save')));
    await tester.pumpAndSettle();

    verify(() => repo.updateSettings({'sleepHoursStart': '22:00'})).called(1);
  });

  group('Filter keywords', () {
    const spoiler = KeywordFilter(
      id: '1',
      keyword: 'spoiler',
      following: false,
    );

    setUp(() {
      when(() => repo.listKeywordFilters()).thenAnswer((_) async => [spoiler]);
    });

    testWidgets('lists keywords with their feeds', (tester) async {
      await pump(tester, const KeywordFiltersScreen());

      expect(find.text('spoiler'), findsOneWidget);
      expect(find.text('For You, Friends'), findsOneWidget);
    });

    testWidgets('adding needs a valid word and at least one feed', (
      tester,
    ) async {
      when(
        () => repo.createKeywordFilter(
          keyword: 'cats',
          forYou: true,
          following: true,
          friends: true,
        ),
      ).thenAnswer((_) async => const KeywordFilter(id: '2', keyword: 'cats'));
      await pump(tester, const KeywordFiltersScreen());

      await tester.tap(find.byKey(const Key('keyword_filters_add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('keyword_form_field')),
        'Spoiler',
      );
      await tester.pump();
      expect(find.text("You've already added this keyword"), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('keyword_form_field')),
        'cats',
      );
      await tester.pump();
      // No feed ticked yet.
      await tester.tap(find.byKey(const Key('keyword_form_save')));
      await tester.pump();
      verifyNever(
        () => repo.createKeywordFilter(
          keyword: any(named: 'keyword'),
          forYou: any(named: 'forYou'),
          following: any(named: 'following'),
          friends: any(named: 'friends'),
        ),
      );

      await tester.tap(find.byKey(const Key('keyword_form_select_all')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('keyword_form_save')));
      await tester.pumpAndSettle();

      expect(find.text('cats'), findsOneWidget);
      expect(find.text('spoiler'), findsOneWidget);
    });

    testWidgets('a phrase can be added, its spaces tidied', (tester) async {
      when(
        () => repo.createKeywordFilter(
          keyword: 'cat videos',
          forYou: true,
          following: true,
          friends: true,
        ),
      ).thenAnswer(
        (_) async => const KeywordFilter(id: '2', keyword: 'cat videos'),
      );
      await pump(tester, const KeywordFiltersScreen());

      await tester.tap(find.byKey(const Key('keyword_filters_add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('keyword_form_field')),
        '  cat   videos ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('keyword_form_select_all')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('keyword_form_save')));
      await tester.pumpAndSettle();

      expect(find.text('cat videos'), findsOneWidget);
    });

    testWidgets('a failed delete keeps the row', (tester) async {
      when(() => repo.deleteKeywordFilter('1')).thenThrow(
        const ServerException(404, 'x', code: 'KEYWORD_FILTER_NOT_FOUND'),
      );
      await pump(tester, const KeywordFiltersScreen());

      await tester.tap(find.byKey(const Key('keyword_filter_delete_1')));
      await tester.pumpAndSettle();

      expect(find.text('spoiler'), findsOneWidget);
      expect(find.text('This keyword was already removed.'), findsOneWidget);
    });
  });
}
