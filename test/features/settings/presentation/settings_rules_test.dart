import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/settings/presentation/settings_rules.dart';

void main() {
  test('weekStartOf is the local Monday', () {
    expect(weekStartOf(DateTime(2026, 11, 7)), '2026-11-02'); // Saturday
    expect(weekStartOf(DateTime(2026, 11, 2)), '2026-11-02'); // Monday
    expect(weekStartOf(DateTime(2026, 11, 8)), '2026-11-02'); // Sunday
  });

  test('lastFourWeeks: oldest first, current last, web labels', () {
    final weeks = lastFourWeeks(DateTime(2026, 11, 7));
    expect(weeks.map((w) => w.start), [
      '2026-10-12',
      '2026-10-19',
      '2026-10-26',
      '2026-11-02',
    ]);
    expect(weeks[1].label, 'Oct 19, 2026-Oct 25, 2026');
  });

  test('chart axis matches the web', () {
    expect(axisTicks(0), List.filled(6, 0.0));
    expect(axisTop(0), 0);
    // 10 minutes: steps of 100s → 6 lines, top 600s.
    expect(axisTop(600), 600);
    expect(axisTicks(600), [10.0, 8.3, 6.7, 5.0, 3.3, 1.7]);
  });

  test('formatDuration and formatLimit', () {
    expect(formatDuration(0), '0m');
    expect(formatDuration(720), '12m');
    expect(formatDuration(3900), '1h 5m');
    expect(formatLimit(40), '40m');
    expect(formatLimit(60), '1h');
    expect(formatLimit(90), '1h 30m');
  });

  group('isLocked', () {
    bool locked({
      int seconds = 3600,
      int? limit = 60,
      bool passcode = true,
      String? unlocked,
      String path = '/feed',
    }) => isLocked(
      todaySeconds: seconds,
      limitMinutes: limit,
      hasPasscode: passcode,
      unlockedDate: unlocked,
      today: '2026-11-07',
      path: path,
    );

    test('at the limit with a passcode', () => expect(locked(), isTrue));
    test('under the limit', () => expect(locked(seconds: 3599), isFalse));
    test('never without a passcode', () {
      expect(locked(passcode: false), isFalse);
    });
    test('never without a limit', () => expect(locked(limit: null), isFalse));
    test('not again on a day already unlocked', () {
      expect(locked(unlocked: '2026-11-07'), isFalse);
      expect(locked(unlocked: '2026-11-06'), isTrue);
    });
    test('never on the settings pages', () {
      expect(locked(path: '/settings'), isFalse);
      expect(locked(path: '/settings/screen-time/daily'), isFalse);
      expect(locked(path: '/settingsx'), isTrue);
    });
  });

  test('clock times wrap and print in 12-hour form', () {
    expect(addHours('23:30', 8), '07:30');
    expect(formatClockTime('22:00'), '10:00 PM');
    expect(formatClockTime('06:05'), '06:05 AM');
    expect(formatClockTime('00:00'), '12:00 AM');
    expect(formatClockTime('12:00'), '12:00 PM');
  });

  test('sleepReminderDue: the ten minutes before the start', () {
    expect(
      sleepReminderDue('22:00', DateTime(2026, 11, 7, 21, 50)),
      '2026-11-07',
    );
    expect(sleepReminderDue('22:00', DateTime(2026, 11, 7, 21, 49)), isNull);
    expect(sleepReminderDue('22:00', DateTime(2026, 11, 7, 22, 0)), isNull);
    // A start just after midnight is tomorrow's night.
    expect(
      sleepReminderDue('00:05', DateTime(2026, 11, 7, 23, 58)),
      '2026-11-08',
    );
  });

  test('inSleepHours: eight hours from the start, past midnight', () {
    expect(inSleepHours('22:00', DateTime(2026, 11, 7, 22, 0)), isTrue);
    expect(inSleepHours('22:00', DateTime(2026, 11, 8, 5, 59)), isTrue);
    expect(inSleepHours('22:00', DateTime(2026, 11, 8, 6, 0)), isFalse);
    expect(inSleepHours('22:00', DateTime(2026, 11, 7, 21, 59)), isFalse);
  });

  test('ianaTimeZone from the offset', () {
    expect(ianaTimeZone(const Duration(hours: 7)), 'Etc/GMT-7');
    expect(ianaTimeZone(const Duration(hours: -5)), 'Etc/GMT+5');
    expect(ianaTimeZone(Duration.zero), 'UTC');
    expect(ianaTimeZone(const Duration(hours: 5, minutes: 30)), 'Asia/Kolkata');
  });

  test('keywordError', () {
    expect(keywordError('   ', const []), isNull);
    // A phrase is fine.
    expect(keywordError('cat videos', const []), isNull);
    expect(keywordError('nhà cái uy tín', const []), isNull);
    expect(keywordError('#cats', const []), isNull);
    expect(
      keywordError('🔥 !!', const []),
      'Include at least one letter or number',
    );
    // Spaced differently, still the same keyword.
    expect(
      keywordError('Cat   Videos', const ['cat videos']),
      "You've already added this keyword",
    );
    expect(normalizeKeyword('  cat \n  videos '), 'cat videos');
    expect(
      keywordError('x' * 201, const []),
      'Keywords can be up to 200 characters',
    );
    expect(
      keywordError(' Spoiler ', const ['spoiler']),
      "You've already added this keyword",
    );
  });

  test('settingsErrorMessage maps codes to copy', () {
    expect(
      settingsErrorMessage(
        const ServerException(
          429,
          'locked',
          code: 'TOO_MANY_PASSCODE_ATTEMPTS',
        ),
      ),
      'Too many incorrect passcodes. Try again in 15 minutes.',
    );
    expect(
      settingsErrorMessage(const ServerException(409, 'x', code: 'OTHER')),
      'Something went wrong. Please try again.',
    );
  });
}
