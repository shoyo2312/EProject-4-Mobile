import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/notification/data/notification_model.dart';

/// notification-service (`/api/v1/notifications`). Every endpoint reads the
/// recipient off the token — there is no userId anywhere in these paths, and
/// no way to ask for somebody else's inbox.
class NotificationRemoteDatasource {
  NotificationRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// The caller's whole inbox, newest first.
  ///
  /// Not paginated: the server has no cursor and no page parameter, so this
  /// grows with the account. Fine while notifications are rare; the day they
  /// are not, paging has to be added server-side first.
  Future<List<NotificationModel>> list() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/notifications');
    return (response.data!['data'] as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Just the badge number, without pulling the whole inbox down — the nav bar
  /// needs it before the Inbox tab has ever been opened.
  Future<int> unreadCount() async {
    final response =
        await _apiClient.get<Map<String, dynamic>>('/notifications/unread-count');
    return (response.data!['data'] as Map<String, dynamic>)['unreadCount'] as int;
  }

  /// 204, no body. Marking one that is already read is not an error.
  Future<void> markRead(String notificationId) {
    return _apiClient.patch<void>('/notifications/$notificationId/read');
  }

  Future<void> markAllRead() {
    return _apiClient.patch<void>('/notifications/read-all');
  }
}
