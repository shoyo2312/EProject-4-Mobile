import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/data/settings_remote_datasource.dart';
import 'package:tiktok_mobile/features/settings/data/settings_repository.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(SettingsRemoteDatasource(ref.watch(apiClientProvider)));

/// One shared copy of `GET /me/settings` for the signed-in account — the
/// Settings screen and the screen-time guard read the same one. Null when
/// signed out.
@Riverpod(keepAlive: true)
class AccountSettings extends _$AccountSettings {
  /// Bumped by every save, so a read that left before a save landed cannot
  /// put the old values back.
  int _saves = 0;

  @override
  FutureOr<UserSettings?> build() async {
    final id = ref.watch(authStateProvider.select((s) => s.valueOrNull?.id));
    if (id == null) return null;
    return ref.read(settingsRepositoryProvider).getSettings();
  }

  /// Re-reads quietly — on returning to the app, say. A failure keeps what
  /// is held; the next refresh tries again.
  Future<void> refresh() async {
    final signedIn = ref.read(authStateProvider).valueOrNull != null;
    if (!signedIn) return;
    final saves = _saves;
    try {
      final fresh = await ref.read(settingsRepositoryProvider).getSettings();
      if (saves == _saves) state = AsyncData(fresh);
    } on AppException {
      // keep the last-known settings
    }
  }

  /// `PATCH /me/settings` with only the keys being changed. Not optimistic:
  /// the server's answer replaces what is held, and a failure is thrown to
  /// the caller, which shows it and keeps its own controls where they were.
  Future<UserSettings> save(Map<String, dynamic> patch) async {
    _saves++;
    final updated = await ref
        .read(settingsRepositoryProvider)
        .updateSettings(patch);
    state = AsyncData(updated);
    return updated;
  }
}

/// Filter keywords, newest first.
@riverpod
class KeywordFilters extends _$KeywordFilters {
  @override
  FutureOr<List<KeywordFilter>> build() =>
      ref.read(settingsRepositoryProvider).listKeywordFilters();

  /// Creates a filter, or replaces [editing] with the new values. The saved
  /// filter goes to the top when new, in place when edited.
  Future<void> save({
    KeywordFilter? editing,
    required String keyword,
    required bool forYou,
    required bool following,
    required bool friends,
  }) async {
    final repo = ref.read(settingsRepositoryProvider);
    final saved = editing == null
        ? await repo.createKeywordFilter(
            keyword: keyword,
            forYou: forYou,
            following: following,
            friends: friends,
          )
        : await repo.updateKeywordFilter(
            editing.copyWith(
              keyword: keyword,
              forYou: forYou,
              following: following,
              friends: friends,
            ),
          );
    final current = state.valueOrNull ?? const <KeywordFilter>[];
    state = AsyncData(
      editing == null
          ? [saved, ...current]
          : [for (final f in current) f.id == saved.id ? saved : f],
    );
  }

  /// Not optimistic: the row stays until the server agrees.
  Future<void> delete(String id) async {
    await ref.read(settingsRepositoryProvider).deleteKeywordFilter(id);
    final current = state.valueOrNull ?? const <KeywordFilter>[];
    state = AsyncData([
      for (final f in current)
        if (f.id != id) f,
    ]);
  }
}

/// One week of the summary chart. [weekStart] is a Monday, "YYYY-MM-DD".
@riverpod
Future<ScreenTimeWeek> screenTimeWeek(Ref ref, String weekStart) =>
    ref.read(settingsRepositoryProvider).getScreenTimeWeek(weekStart);

/// Device-local screen-time state: the day the limit was unlocked, the
/// nights already reminded, the sleep snooze. Per account, because two
/// people can share a phone.
class ScreenTimeLocalStore {
  ScreenTimeLocalStore(this._prefs);

  final SharedPreferences _prefs;

  String _unlockedKey(String userId) => 'nowa:screen-time-unlocked:$userId';
  String _reminderKey(String userId, String night) =>
      'nowa:sleep-reminder:$userId:$night';
  String _snoozeKey(String userId) => 'nowa:sleep-hours-snooze:$userId';

  String? unlockedDate(String userId) => _prefs.getString(_unlockedKey(userId));

  Future<void> setUnlockedDate(String userId, String date) =>
      _prefs.setString(_unlockedKey(userId), date);

  bool reminded(String userId, String night) =>
      _prefs.getBool(_reminderKey(userId, night)) ?? false;

  Future<void> setReminded(String userId, String night) =>
      _prefs.setBool(_reminderKey(userId, night), true);

  DateTime? snoozedUntil(String userId) {
    final ms = _prefs.getInt(_snoozeKey(userId));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setSnoozedUntil(String userId, DateTime until) =>
      _prefs.setInt(_snoozeKey(userId), until.millisecondsSinceEpoch);
}

@Riverpod(keepAlive: true)
Future<ScreenTimeLocalStore> screenTimeLocalStore(Ref ref) async =>
    ScreenTimeLocalStore(await SharedPreferences.getInstance());
