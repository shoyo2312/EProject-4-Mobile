import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class FeedRepository {
  FeedRepository(this._remoteDatasource);

  final FeedRemoteDatasource _remoteDatasource;

  /// The three publish steps in one call: ticket, PUT, create record. The
  /// returned video is PROCESSING — see [getVideo] for the poll that turns it
  /// into a playable one.
  Future<VideoModel> uploadAndPublish({
    required File file,
    required String contentType,
    required String title,
    String? description,
    required VideoVisibility visibility,
    List<String> tags = const [],
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final ticket = await _remoteDatasource.createUploadUrl(contentType);
      await _remoteDatasource.uploadFile(
        ticket,
        file,
        contentType: contentType,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      return await _remoteDatasource.publish(
        title: title,
        description: description,
        rawFileUrl: ticket.fileUrl,
        visibility: visibility,
        tags: tags,
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<VideoPage> fetchFeed({String? cursor, int size = 20}) async {
    try {
      return await _remoteDatasource.fetchFeed(cursor: cursor, size: size);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// The personalised feed: rank, then hydrate, in two calls.
  ///
  /// Two failure shapes matter to the caller and neither is an error here —
  /// an empty ranking (the 30-minute window is spent), and a shorter list than
  /// the ranking asked for (an id was deleted in between). Both mean "fall
  /// back to the chronological feed", which [FeedNotifier] does.
  Future<List<VideoModel>> fetchRankedFeed({int limit = 10}) async {
    try {
      final ids = await _remoteDatasource.fetchRankedIds(limit: limit);
      if (ids.isEmpty) return [];
      return await _remoteDatasource.fetchByIds(ids);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  /// Turns a list of ids into playable videos in one request, in the order
  /// asked. Used wherever another service hands back ids and nothing else —
  /// the ranked feed above, the Liked and Saved histories.
  ///
  /// Ids that no longer resolve are absent from the result rather than failing
  /// it, so the list can come back shorter than [ids] (video doc 3.4b).
  Future<List<VideoModel>> fetchByIds(List<String> ids) async {
    try {
      return await _remoteDatasource.fetchByIds(ids);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<PageResponse<VideoModel>> getUserVideos(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      return await _remoteDatasource.getUserVideos(userId, page: page, size: size);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<VideoModel> getVideo(String videoId) async {
    try {
      return await _remoteDatasource.getVideo(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<VideoModel> updateVisibility(
    String videoId,
    VideoVisibility visibility,
  ) async {
    try {
      return await _remoteDatasource.updateVisibility(videoId, visibility);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<VideoModel> updateCommentsDisabled(
    String videoId,
    bool disabled,
  ) async {
    try {
      return await _remoteDatasource.updateCommentsDisabled(videoId, disabled);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> deleteVideo(String videoId) async {
    try {
      await _remoteDatasource.deleteVideo(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
