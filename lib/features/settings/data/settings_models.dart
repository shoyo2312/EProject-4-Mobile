import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_models.freezed.dart';
part 'settings_models.g.dart';

// Snowflake ID arrives as a JSON number; keep it as String on the Dart side
// so it never gets round-tripped through a double and loses precision.
String _idFromJson(Object? value) => value.toString();

/// Who may comment on the owner's videos, or message them (settings doc 2.2).
enum SettingsAudience {
  @JsonValue('EVERYONE')
  everyone,
  @JsonValue('FRIENDS')
  friends,
  @JsonValue('NO_ONE')
  noOne,
  unknown;

  /// The value a PATCH carries. Never called on [unknown]: the pickers only
  /// offer the three known values.
  String get wire => switch (this) {
    SettingsAudience.everyone => 'EVERYONE',
    SettingsAudience.friends => 'FRIENDS',
    SettingsAudience.noOne => 'NO_ONE',
    SettingsAudience.unknown => 'EVERYONE',
  };
}

/// The parts of `UserSettingsResponse` (settings doc 2.1) the Settings screen
/// reads. The comment filters have their own model and screen; the push and
/// in-app switches are the web's alone.
///
/// `null` on a screen-time field means "off" — there is no separate flag.
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    @Default(SettingsAudience.everyone)
    SettingsAudience commentAudience,
    @JsonKey(unknownEnumValue: SettingsAudience.unknown)
    @Default(SettingsAudience.everyone)
    SettingsAudience dmAudience,

    /// 10–480, the same limit every day. Null when off or set per day.
    int? screenTimeLimitMinutes,

    /// Seven limits of 10–480, Monday first. Null unless set per day.
    List<int>? screenTimeLimitsByDay,

    /// The passcode itself is write-only; this says whether one is set.
    @Default(false) bool hasScreenTimePasscode,

    /// "HH:mm" wall-clock, or null when sleep hours are off.
    String? sleepHoursStart,

    /// Always the start plus eight hours, worked out by the server.
    String? sleepHoursEnd,
    @Default(true) bool weeklyScreenTimeDigest,

    /// On, only approved followers see the videos; turning it off approves
    /// every request still waiting.
    @Default(false) bool privateAccount,
    String? timeZone,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}

extension UserSettingsX on UserSettings {
  bool get dailyLimitOn =>
      screenTimeLimitMinutes != null || screenTimeLimitsByDay != null;

  /// Today's limit in minutes, or null when there is none. [weekday] is
  /// Dart's 1 (Monday) … 7 (Sunday), which matches the server's Monday-first
  /// list.
  int? limitFor(int weekday) {
    final byDay = screenTimeLimitsByDay;
    if (byDay != null && byDay.length == 7) return byDay[weekday - 1];
    return screenTimeLimitMinutes;
  }
}

/// `{ id, keyword, forYou, following, friends }` (settings doc 2.4). Videos
/// matching [keyword] are left out of each feed whose switch is on.
@freezed
class KeywordFilter with _$KeywordFilter {
  const factory KeywordFilter({
    @JsonKey(fromJson: _idFromJson) required String id,
    required String keyword,
    @Default(true) bool forYou,
    @Default(true) bool following,
    @Default(true) bool friends,
  }) = _KeywordFilter;

  factory KeywordFilter.fromJson(Map<String, dynamic> json) =>
      _$KeywordFilterFromJson(json);
}

/// One day of `GET /me/screen-time`: seconds between 06:00 and 22:00, and the
/// rest, in the account's zone.
@freezed
class ScreenTimeDay with _$ScreenTimeDay {
  const factory ScreenTimeDay({
    /// "YYYY-MM-DD".
    required String date,
    @Default(0) int daySeconds,
    @Default(0) int nightSeconds,
  }) = _ScreenTimeDay;

  factory ScreenTimeDay.fromJson(Map<String, dynamic> json) =>
      _$ScreenTimeDayFromJson(json);
}

extension ScreenTimeDayX on ScreenTimeDay {
  int get totalSeconds => daySeconds + nightSeconds;
}

/// Seven days, Monday first, zero-filled.
@freezed
class ScreenTimeWeek with _$ScreenTimeWeek {
  const factory ScreenTimeWeek({
    required String weekStart,
    @Default(<ScreenTimeDay>[]) List<ScreenTimeDay> days,
  }) = _ScreenTimeWeek;

  factory ScreenTimeWeek.fromJson(Map<String, dynamic> json) =>
      _$ScreenTimeWeekFromJson(json);
}
