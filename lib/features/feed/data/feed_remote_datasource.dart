import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/api_response.dart';
import 'package:tiktok_mobile/core/network/page_response.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

/// One `/feed` page. Cursor pagination: [nextCursor] is an opaque server
/// string — pass it back verbatim, never parse or display it. `null` means the
/// feed is exhausted; that is the only stop condition (video doc 3.2).
class VideoPage {
  const VideoPage({required this.items, this.nextCursor});

  final List<VideoModel> items;
  final String? nextCursor;
}

/// What `POST /videos/upload-url` hands back. [fileUrl] is the one to keep:
/// it is what `POST /videos` wants as `rawFileUrl`, and it stays valid for the
/// 7 days the bucket keeps an unpublished object. [uploadUrl] is signed and
/// dies after [expiresInSeconds] — expired means ask for a new ticket, not
/// retry the same URL.
class UploadTicket {
  const UploadTicket({
    required this.uploadUrl,
    required this.fileUrl,
    required this.expiresInSeconds,
  });

  final String uploadUrl;
  final String fileUrl;
  final int expiresInSeconds;
}

/// video-service (`/api/v1/videos`). GETs are public, but sending the token
/// anyway matters: without it the server treats the caller as a guest and
/// hides their own PRIVATE/PROCESSING videos with no error at all (video doc
/// 3.3/3.4). The ApiClient interceptor attaches it whenever one is stored.
class FeedRemoteDatasource {
  FeedRemoteDatasource(this._apiClient, {Dio? uploadDio})
      : _uploadDio = uploadDio ??
            Dio(BaseOptions(
              // The bytes of a whole video, over a phone connection: the 10s
              // timeouts ApiClient uses would kill every upload but the
              // shortest. 0 means "no timeout".
              sendTimeout: Duration.zero,
              receiveTimeout: const Duration(seconds: 60),
            ));

  final ApiClient _apiClient;

  /// Storage is talked to directly, not through [ApiClient]: the presigned URL
  /// carries its own signature in the query string and S3 rejects the request
  /// outright if an `Authorization` header rides along (video doc 3.1).
  final Dio _uploadDio;

  /// Step 1 of publishing: ask for somewhere to put the file.
  ///
  /// [contentType] must be one of `video/mp4`, `video/quicktime`,
  /// `video/webm`; anything else comes back as `UNSUPPORTED_UPLOAD_TYPE`.
  Future<UploadTicket> createUploadUrl(String contentType) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/videos/upload-url',
      data: {'contentType': contentType},
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    return UploadTicket(
      uploadUrl: body['uploadUrl'] as String,
      fileUrl: body['fileUrl'] as String,
      expiresInSeconds: body['expiresInSeconds'] as int,
    );
  }

  /// Step 2: a plain PUT of the bytes to the presigned URL. Streamed from
  /// disk rather than read into memory — a 3-minute clip does not fit in a
  /// phone's heap twice.
  Future<void> uploadFile(
    UploadTicket ticket,
    File file, {
    required String contentType,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final length = await file.length();
    await _uploadDio.put<void>(
      ticket.uploadUrl,
      data: file.openRead(),
      cancelToken: cancelToken,
      onSendProgress: onProgress,
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: length,
        },
      ),
    );
  }

  /// Step 3: create the Video record. [rawFileUrl] is the ticket's `fileUrl`
  /// — never its `uploadUrl`, which expires and fails the server's
  /// allow-list. The video comes back PROCESSING with no `hlsUrl`; it is not
  /// playable and not on the feed until transcoding finishes.
  Future<VideoModel> publish({
    required String title,
    String? description,
    required String rawFileUrl,
    required VideoVisibility visibility,
    List<String> tags = const [],
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/videos',
      data: {
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        'rawFileUrl': rawFileUrl,
        'visibility': visibility == VideoVisibility.private
            ? 'PRIVATE'
            : 'PUBLIC',
        if (tags.isNotEmpty) 'tags': tags,
      },
    );
    final envelope = ApiResponse<VideoModel>.fromJson(
      response.data!,
      (json) => VideoModel.fromJson(json as Map<String, dynamic>),
    );
    return envelope.data!;
  }

  /// PUBLISHED + PUBLIC videos only, newest first. Ordering is fixed
  /// server-side, so there is no `sort` parameter to pass. Unlike
  /// [getUserVideos] this is cursor-paginated: no `page`/`totalPages`.
  Future<VideoPage> fetchFeed({String? cursor, int size = 20}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/feed',
      queryParameters: {'cursor': ?cursor, 'size': size},
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return VideoPage(items: items, nextCursor: body['nextCursor'] as String?);
  }

  /// The Following tab. Same page shape and same cursor protocol as
  /// [fetchFeed], drawn only from the authors named in [followedUserIds] —
  /// video-service holds no follow graph, so the caller reads those from
  /// user-service and passes them in (video doc 3.2b).
  ///
  /// Naming an account the caller does not follow is not a way in: the
  /// visibility filter behind this is the public one, so it can only ever
  /// return what `/videos/users/{id}` would already hand out.
  Future<VideoPage> fetchFollowingFeed({
    required List<String> followedUserIds,
    String? cursor,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/feed/following',
      queryParameters: {
        'followedUserIds': followedUserIds.join(','),
        'cursor': ?cursor,
        'size': size,
      },
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return VideoPage(items: items, nextCursor: body['nextCursor'] as String?);
  }

  /// One ranked page from recommendation-service, as ids only: it is not
  /// allowed to read video-service's data, so it never returns anything
  /// showable (recommendation doc 4). **The order is the ranking** — keep it.
  ///
  /// There is no cursor. The server remembers what it just handed this user
  /// for 30 minutes and leaves it out of the next answer, so asking again *is*
  /// the next page. Ask for what will actually be shown: anything returned
  /// counts as spent even if the viewer never saw it (doc 7).
  ///
  /// An empty list is a normal answer — a cold system, or a user who has been
  /// served everything the window holds — not an error.
  Future<List<String>> fetchRankedIds({int limit = 10}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/recommendations/feed',
      queryParameters: {'limit': limit},
    );
    return (response.data!['data'] as List)
        .map((e) => (e as Map<String, dynamic>)['videoId'].toString())
        .toList();
  }

  /// Hydrates a whole ranked page in one request, answering in the order
  /// asked. Twenty single `/videos/{id}` calls would spend the gateway's
  /// entire 20 req/s per-IP budget on one scroll — and that budget is shared
  /// with every other call the app makes.
  ///
  /// Ids that no longer resolve are simply absent from the result: a video
  /// deleted between ranking and hydration is the normal case, so the list
  /// coming back shorter is not an error (video doc 3.4b).
  Future<List<VideoModel>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/batch',
      queryParameters: {'ids': ids.join(',')},
    );
    return (response.data!['data'] as List)
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Every non-deleted video when [userId] is the caller's own — PROCESSING,
  /// PRIVATE, FAILED and TAKEN_DOWN included; only PUBLISHED + PUBLIC for
  /// anyone else. An unknown userId yields an empty page, not a 404.
  Future<PageResponse<VideoModel>> getUserVideos(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/users/$userId',
      queryParameters: {'page': page, 'size': size},
    );
    return _unwrapPage(response.data!);
  }

  Future<VideoModel> getVideo(String videoId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/videos/$videoId');
    final envelope = ApiResponse<VideoModel>.fromJson(
      response.data!,
      (json) => VideoModel.fromJson(json as Map<String, dynamic>),
    );
    return envelope.data!;
  }

  /// Owner-only, like [deleteVideo]: anyone else gets `NOT_VIDEO_OWNER`.
  /// Answers the updated video, so the caller replaces its row from the
  /// response rather than guessing what changed.
  Future<VideoModel> updateVisibility(
    String videoId,
    VideoVisibility visibility,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/videos/$videoId/visibility',
      data: {
        'visibility': visibility == VideoVisibility.private ? 'PRIVATE' : 'PUBLIC',
      },
    );
    return _unwrapVideo(response.data!);
  }

  /// Owner-only. Turns *new* comments on or off; the ones already posted are
  /// untouched.
  Future<VideoModel> updateCommentsDisabled(
    String videoId,
    bool disabled,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '/videos/$videoId/comments-setting',
      data: {'disabled': disabled},
    );
    return _unwrapVideo(response.data!);
  }

  Future<void> deleteVideo(String videoId) {
    return _apiClient.delete<void>('/videos/$videoId');
  }

  VideoModel _unwrapVideo(Map<String, dynamic> body) {
    return ApiResponse<VideoModel>.fromJson(
      body,
      (json) => VideoModel.fromJson(json as Map<String, dynamic>),
    ).data!;
  }

  PageResponse<VideoModel> _unwrapPage(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>;
    return PageResponse.fromJson(data, VideoModel.fromJson);
  }
}
