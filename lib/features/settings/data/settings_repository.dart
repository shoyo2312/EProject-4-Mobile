import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';
import 'package:tiktok_mobile/features/settings/data/settings_remote_datasource.dart';

/// Error boundary for [SettingsRemoteDatasource]: nothing above this sees a
/// `DioException`.
class SettingsRepository {
  SettingsRepository(this._remoteDatasource);

  final SettingsRemoteDatasource _remoteDatasource;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<UserSettings> getSettings() => _guard(_remoteDatasource.getSettings);

  Future<UserSettings> updateSettings(Map<String, dynamic> changes) =>
      _guard(() => _remoteDatasource.updateSettings(changes));

  Future<List<KeywordFilter>> listKeywordFilters() =>
      _guard(_remoteDatasource.listKeywordFilters);

  Future<KeywordFilter> createKeywordFilter({
    required String keyword,
    required bool forYou,
    required bool following,
    required bool friends,
  }) => _guard(
    () => _remoteDatasource.createKeywordFilter({
      'keyword': keyword,
      'forYou': forYou,
      'following': following,
      'friends': friends,
    }),
  );

  Future<KeywordFilter> updateKeywordFilter(KeywordFilter filter) => _guard(
    () => _remoteDatasource.updateKeywordFilter(filter.id, {
      'keyword': filter.keyword,
      'forYou': filter.forYou,
      'following': filter.following,
      'friends': filter.friends,
    }),
  );

  Future<void> deleteKeywordFilter(String id) =>
      _guard(() => _remoteDatasource.deleteKeywordFilter(id));

  Future<void> sendScreenTimeHeartbeat(int seconds, String timeZone) => _guard(
    () => _remoteDatasource.sendScreenTimeHeartbeat(seconds, timeZone),
  );

  Future<ScreenTimeWeek> getScreenTimeWeek(String weekStart) =>
      _guard(() => _remoteDatasource.getScreenTimeWeek(weekStart));

  Future<bool> verifyScreenTimePasscode(String passcode) =>
      _guard(() => _remoteDatasource.verifyScreenTimePasscode(passcode));
}
