import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/features/settings/data/settings_models.dart';

/// Account settings, filter keywords and screen time — all under
/// `/users/me` in user-service (settings doc 2).
class SettingsRemoteDatasource {
  SettingsRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  static const _keywordFilters = '/users/me/keyword-filters';

  /// Never 404: an account that never changed a setting gets the defaults.
  Future<UserSettings> getSettings() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/me/settings',
    );
    return _unwrap(response.data!, UserSettings.fromJson);
  }

  /// An absent key leaves the field alone; an explicit `null` on a nullable
  /// field (a screen-time limit, sleep hours) turns it off. Answers the whole
  /// settings object as it now stands.
  Future<UserSettings> updateSettings(Map<String, dynamic> changes) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/users/me/settings',
      data: changes,
    );
    return _unwrap(response.data!, UserSettings.fromJson);
  }

  /// Newest first.
  Future<List<KeywordFilter>> listKeywordFilters() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      _keywordFilters,
    );
    return (response.data!['data'] as List)
        .map((e) => KeywordFilter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KeywordFilter> createKeywordFilter(Map<String, dynamic> body) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _keywordFilters,
      data: body,
    );
    return _unwrap(response.data!, KeywordFilter.fromJson);
  }

  Future<KeywordFilter> updateKeywordFilter(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_keywordFilters/$id',
      data: body,
    );
    return _unwrap(response.data!, KeywordFilter.fromJson);
  }

  Future<void> deleteKeywordFilter(String id) {
    return _apiClient.delete<void>('$_keywordFilters/$id');
  }

  /// Time spent in the app since the last beat. The server clamps [seconds]
  /// to 120 and files them under the local day of the moment it receives
  /// them, in [timeZone].
  Future<void> sendScreenTimeHeartbeat(int seconds, String timeZone) {
    return _apiClient.post<void>(
      '/users/me/screen-time/heartbeat',
      data: {'seconds': seconds, 'timeZone': timeZone},
    );
  }

  /// [weekStart] must be a Monday, "YYYY-MM-DD".
  Future<ScreenTimeWeek> getScreenTimeWeek(String weekStart) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/me/screen-time',
      queryParameters: {'weekStart': weekStart},
    );
    return _unwrap(response.data!, ScreenTimeWeek.fromJson);
  }

  /// The fifth wrong answer in a row locks checking for 15 minutes:
  /// `TOO_MANY_PASSCODE_ATTEMPTS` (429).
  Future<bool> verifyScreenTimePasscode(String passcode) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/users/me/screen-time/passcode/verify',
      data: {'passcode': passcode},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return data['correct'] == true;
  }

  T _unwrap<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final envelope = ApiResponse<T>.fromJson(
      body,
      (json) => fromJson(json as Map<String, dynamic>),
    );
    return envelope.data!;
  }
}
