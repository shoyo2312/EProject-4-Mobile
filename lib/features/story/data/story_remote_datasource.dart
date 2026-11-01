import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/media_url.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart'
    show UploadTicket;
import 'package:tiktok_mobile/features/story/data/story_model.dart';

/// story-service (`/api/v1/stories`). Posting is three steps, like a video:
/// presign, POST the file straight to storage, then create the story with the
/// ticket's `fileUrl` (story doc §1).
class StoryRemoteDatasource {
  StoryRemoteDatasource(this._apiClient, {Dio? uploadDio})
      : _uploadDio = uploadDio ??
            Dio(BaseOptions(
              // A whole file over a phone connection: ApiClient's 10s timeouts
              // would kill all but the smallest. 0 means "no timeout".
              sendTimeout: Duration.zero,
              receiveTimeout: const Duration(seconds: 60),
            ));

  final ApiClient _apiClient;

  /// Storage is talked to directly: the presigned policy carries its own
  /// signature and S3 refuses a request with an `Authorization` header.
  final Dio _uploadDio;

  /// [contentType] is one of `image/jpeg`, `image/png`, `image/webp`,
  /// `video/mp4`, `video/webm`; anything else is `UNSUPPORTED_UPLOAD_TYPE`.
  Future<UploadTicket> createUploadUrl(String contentType) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/stories/upload-url',
      data: {'contentType': contentType},
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    return UploadTicket(
      uploadUrl: body['uploadUrl'] as String,
      formFields: (body['formFields'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
      fileUrl: body['fileUrl'] as String,
      expiresInSeconds: (body['expiresInSeconds'] as num).toInt(),
    );
  }

  /// Multipart POST of the policy fields plus the file, which S3 requires to
  /// come last. The size limit is signed into the policy, so storage itself
  /// refuses an oversize file.
  Future<void> uploadFile(
    UploadTicket ticket,
    File file, {
    required String contentType,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final form = FormData();
    ticket.formFields.forEach((name, value) {
      form.fields.add(MapEntry(name, value));
    });
    form.files.add(MapEntry(
      'file',
      await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
        contentType: DioMediaType.parse(contentType),
      ),
    ));
    await _uploadDio.post<void>(
      reachableFromDevice(ticket.uploadUrl),
      data: form,
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );
  }

  /// Comes back `PENDING_MODERATION`: only the owner sees it until
  /// media-worker approves it, and the 24 hours start then.
  Future<StoryModel> create({
    required String mediaUrl,
    String? caption,
    required StoryVisibility visibility,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/stories',
      data: {
        'mediaUrl': mediaUrl,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
        'visibility': wireStoryVisibility(visibility),
      },
    );
    return _unwrapStory(response.data!);
  }

  /// The tray. The caller's own group comes first whatever is passed;
  /// [followedUserIds] is capped at 500 server-side.
  Future<List<StoryGroup>> feed(List<String> followedUserIds) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/stories/feed',
      queryParameters: {'followedUserIds': followedUserIds.join(',')},
    );
    return (response.data!['data'] as List)
        .map((e) => StoryGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Which of these accounts have a ring — at most 100 ids per call. Ids
  /// without one are simply absent.
  Future<List<StoryRing>> rings(List<String> userIds) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/stories/rings',
      queryParameters: {'userIds': userIds.join(',')},
    );
    return (response.data!['data'] as List)
        .map((e) => StoryRing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Oldest first. Works signed out (PUBLIC stories of public accounts).
  Future<List<StoryModel>> userStories(String userId) async {
    final response =
        await _apiClient.get<Map<String, dynamic>>('/stories/users/$userId');
    return (response.data!['data'] as List)
        .map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Re-viewing or viewing your own story is not counted server-side, so
  /// calling this more than once is harmless.
  Future<void> recordView(String storyId) =>
      _apiClient.post<void>('/stories/$storyId/views');

  /// Owner-only, newest first. Pass the last row's `viewedAt` as [before] for
  /// the next page.
  Future<List<StoryViewer>> viewers(
    String storyId, {
    DateTime? before,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/stories/$storyId/viewers',
      queryParameters: {
        if (before != null) 'before': before.toUtc().toIso8601String(),
        'size': size,
      },
    );
    return (response.data!['data'] as List)
        .map((e) => StoryViewer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// One reaction per viewer; calling again replaces it.
  Future<void> setReaction(String storyId, StoryReaction reaction) =>
      _apiClient.put<void>(
        '/stories/$storyId/reaction',
        data: {'reaction': reaction.wire},
      );

  Future<void> clearReaction(String storyId) =>
      _apiClient.delete<void>('/stories/$storyId/reaction');

  Future<StoryModel> updateVisibility(
    String storyId,
    StoryVisibility visibility,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/stories/$storyId/visibility',
      data: {'visibility': wireStoryVisibility(visibility)},
    );
    return _unwrapStory(response.data!);
  }

  Future<void> delete(String storyId) =>
      _apiClient.delete<void>('/stories/$storyId');

  StoryModel _unwrapStory(Map<String, dynamic> body) =>
      StoryModel.fromJson(body['data'] as Map<String, dynamic>);
}
