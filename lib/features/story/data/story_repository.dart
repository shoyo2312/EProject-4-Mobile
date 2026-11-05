import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_remote_datasource.dart';

/// Content types story-service accepts (story doc §3), keyed by the file
/// extension the picker hands back. No QuickTime: an iPhone camera `.mov`
/// has to be picked as MP4 instead.
const _storyContentTypes = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.mp4': 'video/mp4',
  '.m4v': 'video/mp4',
  '.webm': 'video/webm',
};

/// Null when story-service would refuse the file anyway.
String? storyContentTypeForPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return null;
  return _storyContentTypes[path.substring(dot).toLowerCase()];
}

bool isVideoContentType(String contentType) => contentType.startsWith('video/');

/// The size limits signed into the upload policy (story doc §3). Checked here
/// too so the poster hears it before spending the upload.
const storyImageMaxBytes = 10 * 1024 * 1024;
const storyVideoMaxBytes = 50 * 1024 * 1024;

/// Longer videos are REJECTED by media-worker after the upload.
const storyVideoMaxDuration = Duration(seconds: 60);

/// The `edit` of a create (story doc §3): the video recipe, plus how long a
/// photo with a song plays. Overlays must already carry their upload URLs.
Map<String, dynamic> storyEditJson(VideoEdit edit, double? photoSeconds) => {
      if (edit.segments.isNotEmpty)
        'segments': [for (final segment in edit.segments) segment.toJson()],
      if (edit.filter != null) 'filter': edit.filter!.toJson(),
      if (edit.music != null) 'music': edit.music!.toJson(),
      if (edit.overlays.isNotEmpty)
        'overlays': [
          for (final layer in edit.overlays)
            {
              'imageUrl': layer.imageUrl,
              if (layer.start != null) 'start': layer.start,
              if (layer.end != null) 'end': layer.end,
              if (layer.texts.isNotEmpty) 'texts': layer.texts,
            },
        ],
      'photoSeconds': ?photoSeconds,
    };

class StoryRepository {
  StoryRepository(this._remoteDatasource);

  final StoryRemoteDatasource _remoteDatasource;

  /// Ticket, upload, create — in one call. The story comes back
  /// PENDING_MODERATION. The editor's text and sticker layers go up first, as
  /// PNG uploads of their own, and [edit] names them by their file URLs.
  Future<StoryModel> uploadAndCreate({
    required File file,
    required String contentType,
    VideoEdit? edit,
    double? photoSeconds,
    String? caption,
    required StoryVisibility visibility,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final overlays = <OverlayLayer>[];
      for (final layer in edit?.overlays ?? const <OverlayLayer>[]) {
        const png = 'image/png';
        final overlayTicket = await _remoteDatasource.createUploadUrl(png);
        await _remoteDatasource.uploadFile(
          overlayTicket,
          File(layer.path),
          contentType: png,
          cancelToken: cancelToken,
        );
        overlays.add(layer.copyWith(imageUrl: overlayTicket.fileUrl));
      }
      final ticket = await _remoteDatasource.createUploadUrl(contentType);
      await _remoteDatasource.uploadFile(
        ticket,
        file,
        contentType: contentType,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      return await _remoteDatasource.create(
        mediaUrl: ticket.fileUrl,
        caption: caption,
        visibility: visibility,
        edit: edit == null ? null : storyEditJson(edit.copyWith(overlays: overlays), photoSeconds),
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<List<StoryGroup>> feed(List<String> followedUserIds) =>
      _guard(() => _remoteDatasource.feed(followedUserIds));

  Future<List<StoryRing>> rings(List<String> userIds) =>
      _guard(() => _remoteDatasource.rings(userIds));

  Future<List<StoryModel>> userStories(String userId) =>
      _guard(() => _remoteDatasource.userStories(userId));

  Future<void> recordView(String storyId) =>
      _guard(() => _remoteDatasource.recordView(storyId));

  Future<List<StoryViewer>> viewers(String storyId, {DateTime? before}) =>
      _guard(() => _remoteDatasource.viewers(storyId, before: before));

  Future<void> setReaction(String storyId, StoryReaction reaction) =>
      _guard(() => _remoteDatasource.setReaction(storyId, reaction));

  Future<void> clearReaction(String storyId) =>
      _guard(() => _remoteDatasource.clearReaction(storyId));

  Future<StoryModel> updateVisibility(
    String storyId,
    StoryVisibility visibility,
  ) =>
      _guard(() => _remoteDatasource.updateVisibility(storyId, visibility));

  Future<void> delete(String storyId) =>
      _guard(() => _remoteDatasource.delete(storyId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
