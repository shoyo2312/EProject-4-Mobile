import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/studio/data/studio_models.dart';
import 'package:tiktok_mobile/features/studio/data/studio_remote_datasource.dart';

class StudioRepository {
  StudioRepository(this._remoteDatasource);

  final StudioRemoteDatasource _remoteDatasource;

  Future<CreatorOverview> getOverview(int days) =>
      _guard(() => _remoteDatasource.getOverview(days));

  Future<List<CreatorVideoStats>> getTopVideos(
    int days,
    CreatorVideoSort sort, {
    int limit = 10,
  }) =>
      _guard(() => _remoteDatasource.getTopVideos(days, sort, limit: limit));

  Future<CreatorVideoDetail> getVideoDetail(String videoId, int days) =>
      _guard(() => _remoteDatasource.getVideoDetail(videoId, days));

  Future<CreatorViewers> getViewers(int days) =>
      _guard(() => _remoteDatasource.getViewers(days));

  Future<PageResponse<VideoModel>> listMyVideos(
    StudioPostQuery query, {
    int page = 0,
    int size = 20,
  }) =>
      _guard(() => _remoteDatasource.listMyVideos(query, page: page, size: size));

  Future<VideoModel> updateCaption(
    String videoId, {
    required String title,
    String? description,
  }) =>
      _guard(() => _remoteDatasource.updateCaption(
            videoId,
            title: title,
            description: description,
          ));

  Future<VideoModel> setPinned(String videoId, bool pinned) =>
      _guard(() => _remoteDatasource.setPinned(videoId, pinned));

  Future<CommentPage> listInbox(
    InboxQuery query, {
    String? cursor,
    int size = 20,
  }) =>
      _guard(() => _remoteDatasource.listInbox(query, cursor: cursor, size: size));

  Future<void> approveComment(String videoId, String commentId) =>
      _guard(() => _remoteDatasource.approveComment(videoId, commentId));

  /// The error boundary: nothing above this layer sees a [DioException].
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
