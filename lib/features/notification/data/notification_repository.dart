import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/notification/data/notification_model.dart';
import 'package:tiktok_mobile/features/notification/data/notification_remote_datasource.dart';

class NotificationRepository {
  NotificationRepository(this._remoteDatasource);

  final NotificationRemoteDatasource _remoteDatasource;

  Future<List<NotificationModel>> list() async {
    try {
      return await _remoteDatasource.list();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      return await _remoteDatasource.unreadCount();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _remoteDatasource.markRead(notificationId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _remoteDatasource.markAllRead();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
