import 'dart:math' as math;

import 'package:tiktok_mobile/core/network/app_exception.dart';

/// Pure rules behind Screen time and Filter keywords, kept identical to the
/// web client's (`lib/settings/screen-time.ts`, `sleep-hours.ts`,
/// `keyword-filters.ts`) so both apps lock, remind and validate alike.

String _two(int n) => n.toString().padLeft(2, '0');

/// [d]'s local calendar day, "YYYY-MM-DD".
String localDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// The local Monday of [d]'s week, "YYYY-MM-DD" — the key the week read takes.
String weekStartOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return localDate(day.subtract(Duration(days: d.weekday - 1)));
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// The weeks the summary offers: the last four, oldest first and the current
/// one last. Labelled "Oct 19, 2026-Oct 25, 2026".
List<({String start, String label})> lastFourWeeks(DateTime today) {
  final monday = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: today.weekday - 1));
  return [
    for (var i = 3; i >= 0; i--)
      () {
        final start = DateTime(monday.year, monday.month, monday.day - 7 * i);
        final end = DateTime(start.year, start.month, start.day + 6);
        return (
          start: localDate(start),
          label: '${_shortDate(start)}-${_shortDate(end)}',
        );
      }(),
  ];
}

/// A round step of 1, 2 or 5 × 10^k seconds near [raw].
double _niceStep(double raw) {
  final p = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final e = raw / p;
  if (e >= math.sqrt(50)) return 10 * p;
  if (e >= math.sqrt(10)) return 5 * p;
  if (e >= math.sqrt(2)) return 2 * p;
  return p;
}

/// The value of the chart's top gridline, in seconds.
double axisTop(int maxSeconds) {
  if (maxSeconds <= 0) return 0;
  final step = _niceStep(maxSeconds / 6);
  return (maxSeconds / step).ceil() * step;
}

/// The gridlines above the baseline, top first, in minutes to one decimal.
/// A week with no time still draws six lines, every one at 0.
List<double> axisTicks(int maxSeconds) {
  if (maxSeconds <= 0) return List.filled(6, 0);
  final step = _niceStep(maxSeconds / 6);
  final lines = (maxSeconds / step).ceil();
  return [
    for (var i = 0; i < lines; i++) ((lines - i) * step / 6).round() / 10,
  ];
}

/// "1h 5m", "12m", "0m": whole minutes, rounded.
String formatDuration(int seconds) {
  final m = (seconds / 60).round();
  final h = m ~/ 60;
  return h > 0 ? '${h}h ${m % 60}m' : '${m}m';
}

/// A daily limit in minutes as the row shows it: "40m", "1h", "1h 30m".
String formatLimit(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// Whether the daily limit covers the app now. Never without a passcode,
/// which is the only way past it; never on the settings pages, where the
/// limit can still be changed; and not again on a day already unlocked.
bool isLocked({
  required int todaySeconds,
  required int? limitMinutes,
  required bool hasPasscode,
  required String? unlockedDate,
  required String today,
  required String path,
}) {
  if (limitMinutes == null || !hasPasscode) return false;
  if (path == '/settings' || path.startsWith('/settings/')) return false;
  if (unlockedDate == today) return false;
  return todaySeconds >= limitMinutes * 60;
}

({int hour, int minute}) _parseTime(String time) {
  final parts = time.split(':');
  return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// "HH:mm" plus whole hours, round the clock: "23:30" + 8 is "07:30".
String addHours(String time, int hours) {
  final t = _parseTime(time);
  return '${_two((t.hour + hours) % 24)}:${_two(t.minute)}';
}

/// "HH:mm" as the time fields write it: "10:00 PM", "06:00 AM".
String formatClockTime(String time) {
  final t = _parseTime(time);
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '${_two(h12)}:${_two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// How long before sleep hours start the reminder is shown.
const sleepReminderLead = Duration(minutes: 10);

/// The night the sleep reminder is due for at [now] — the local day of the
/// start it announces — or null when it is not due. Due in the ten minutes
/// before the start.
String? sleepReminderDue(String start, DateTime now) {
  final t = _parseTime(start);
  for (final day in [0, 1]) {
    final at = DateTime(now.year, now.month, now.day + day, t.hour, t.minute);
    final until = at.difference(now);
    if (until > Duration.zero && until <= sleepReminderLead) {
      return localDate(at);
    }
  }
  return null;
}

/// Inside the eight hours from [start], wrapping past midnight.
bool inSleepHours(String start, DateTime now) {
  final t = _parseTime(start);
  final nowMin = now.hour * 60 + now.minute;
  final sinceStart = (nowMin - (t.hour * 60 + t.minute) + 1440) % 1440;
  return sinceStart < 480;
}

/// An IANA zone for the device's current offset. The heartbeat needs one,
/// and Dart only knows the offset and an abbreviation. Whole hours map to
/// `Etc/GMT∓N` (POSIX sign: UTC+7 is `Etc/GMT-7`); the few half-hour zones
/// map to a city on that offset.
String ianaTimeZone(Duration offset) {
  final minutes = offset.inMinutes;
  if (minutes == 0) return 'UTC';
  if (minutes % 60 == 0) {
    final h = minutes ~/ 60;
    return h > 0 ? 'Etc/GMT-$h' : 'Etc/GMT+${-h}';
  }
  return switch (minutes) {
    -210 => 'America/St_Johns',
    210 => 'Asia/Tehran',
    270 => 'Asia/Kabul',
    330 => 'Asia/Kolkata',
    345 => 'Asia/Kathmandu',
    390 => 'Asia/Yangon',
    525 => 'Australia/Eucla',
    570 => 'Australia/Darwin',
    630 => 'Australia/Lord_Howe',
    765 => 'Pacific/Chatham',
    _ => 'UTC',
  };
}

final _spaces = RegExp(r'\s+');
final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// The keyword as the server stores it: trimmed, runs of spaces made one.
/// A phrase is fine — it matches its words in a row.
String normalizeKeyword(String text) => text.trim().replaceAll(_spaces, ' ');

/// The keyword form's complaint, or null. [existing] is every other keyword
/// on the account — the one being edited left out.
String? keywordError(String text, Iterable<String> existing) {
  final keyword = normalizeKeyword(text);
  if (keyword.isEmpty) return null;
  if (keyword.runes.length > 200) return 'Keywords can be up to 200 characters';
  // Only emoji or punctuation would never match anything.
  if (!_letterOrDigit.hasMatch(keyword)) {
    return 'Include at least one letter or number';
  }
  final lower = keyword.toLowerCase();
  if (existing.any((o) => normalizeKeyword(o).toLowerCase() == lower)) {
    return "You've already added this keyword";
  }
  return null;
}

/// User-facing copy for the codes these screens meet; the server's own
/// message is not shown when there is a line for it.
String settingsErrorMessage(Object error) {
  if (error is ServerException) {
    final known = switch (error.code) {
      'VALIDATION_ERROR' => 'Please check the details you entered.',
      'TOO_MANY_PASSCODE_ATTEMPTS' =>
        'Too many incorrect passcodes. Try again in 15 minutes.',
      'KEYWORD_FILTER_DUPLICATE' => "You've already added this keyword",
      'TOO_MANY_KEYWORD_FILTERS' => 'You can filter up to 100 keywords.',
      'KEYWORD_FILTER_NOT_FOUND' => 'This keyword was already removed.',
      'CONCURRENT_MODIFICATION' =>
        'Something changed at the same time. Try again.',
      _ => null,
    };
    if (known != null) return known;
    if (error.statusCode == 429) return 'Too many requests. Please slow down.';
  }
  if (error is UnauthorizedException) {
    return 'Your session expired. Please log in again.';
  }
  if (error is NetworkException) {
    return "Can't connect right now. Check your connection and try again.";
  }
  return 'Something went wrong. Please try again.';
}
