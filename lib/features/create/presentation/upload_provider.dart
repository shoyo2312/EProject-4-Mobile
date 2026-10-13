import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

part 'upload_provider.g.dart';

/// The only three types `POST /videos/upload-url` accepts (video doc 3.1),
/// keyed by the file extension the picker hands back.
const _contentTypes = {
  '.mp4': 'video/mp4',
  '.mov': 'video/quicktime',
  '.m4v': 'video/mp4',
  '.webm': 'video/webm',
};

String? contentTypeForPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return null;
  return _contentTypes[path.substring(dot).toLowerCase()];
}

enum UploadPhase {
  idle,

  /// Bytes going to storage. [UploadState.progress] moves in this phase only.
  uploading,

  /// Bytes are up; creating the Video record.
  publishing,

  /// Published, transcoding. Not playable and not on the feed yet.
  processing,

  /// Transcoded and playable.
  done,
  failed,
}

class UploadState {
  const UploadState({
    this.phase = UploadPhase.idle,
    this.progress = 0,
    this.video,
    this.error,
  });

  final UploadPhase phase;

  /// 0..1, or -1 when the total size is unknown.
  final double progress;
  final VideoModel? video;
  final String? error;

  bool get busy =>
      phase == UploadPhase.uploading ||
      phase == UploadPhase.publishing ||
      phase == UploadPhase.processing;
}

/// How long to wait between `GET /videos/{id}` polls, then give up.
///
/// Transcoding is asynchronous and takes seconds to minutes, so the client has
/// to ask. The gaps widen because the gateway allows 20 req/s per IP shared
/// with everything else the app does, and running out of the list is not a
/// failure — the video is still being processed, just not while the user
/// watches (video doc 3.2).
const _pollDelays = [
  Duration(seconds: 2),
  Duration(seconds: 3),
  Duration(seconds: 5),
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 10),
  Duration(seconds: 15),
  Duration(seconds: 20),
  Duration(seconds: 30),
  Duration(seconds: 30),
  Duration(seconds: 30),
  Duration(seconds: 60),
  Duration(seconds: 60),
];

/// Kept alive: an upload has to survive the user switching tabs while the
/// bytes are going up — a dropped notifier would cancel the request mid-file.
@Riverpod(keepAlive: true)
class UploadNotifier extends _$UploadNotifier {
  CancelToken? _cancelToken;
  var _disposed = false;

  @override
  UploadState build() {
    ref.onDispose(() {
      _disposed = true;
      _cancelToken?.cancel();
    });
    return const UploadState();
  }

  Future<void> start({
    required File file,
    required String title,
    String? description,
    required VideoVisibility visibility,
    List<String> tags = const [],
  }) async {
    if (state.busy) return;

    final contentType = contentTypeForPath(file.path);
    if (contentType == null) {
      state = const UploadState(
        phase: UploadPhase.failed,
        error: 'Only MP4, MOV and WebM videos can be uploaded',
      );
      return;
    }

    final cancelToken = _cancelToken = CancelToken();
    state = const UploadState(phase: UploadPhase.uploading);

    final VideoModel published;
    try {
      published = await ref.read(feedRepositoryProvider).uploadAndPublish(
            file: file,
            contentType: contentType,
            title: title,
            description: description,
            visibility: visibility,
            tags: tags,
            cancelToken: cancelToken,
            onProgress: (sent, total) {
              if (_disposed || state.phase != UploadPhase.uploading) return;
              state = UploadState(
                phase: UploadPhase.uploading,
                progress: total > 0 ? sent / total : -1,
              );
              // The last byte leaving is not the end: the record still has to
              // be created, and that request has no progress of its own.
              if (total > 0 && sent >= total) {
                state = const UploadState(phase: UploadPhase.publishing, progress: 1);
              }
            },
          );
    } on AppException catch (e) {
      if (_disposed || cancelToken.isCancelled) return;
      state = UploadState(phase: UploadPhase.failed, error: _messageFor(e));
      return;
    } finally {
      _cancelToken = null;
    }

    if (_disposed) return;
    state = UploadState(phase: UploadPhase.processing, progress: 1, video: published);
    await _awaitTranscode(published.id);
  }

  /// Polls until the video is playable, unwatchable, or the list of delays
  /// runs out. Timing out leaves the state on [UploadPhase.processing]: the
  /// video is fine, it is just not ready while this screen is open.
  Future<void> _awaitTranscode(String videoId) async {
    for (final delay in _pollDelays) {
      await Future<void>.delayed(delay);
      if (_disposed) return;

      final VideoModel video;
      try {
        video = await ref.read(feedRepositoryProvider).getVideo(videoId);
      } on AppException {
        // A dropped poll is not a failed upload — try the next one.
        continue;
      }
      if (_disposed) return;

      switch (video.status) {
        case VideoStatus.published:
          state = UploadState(phase: UploadPhase.done, progress: 1, video: video);
          // The new video belongs on its owner's profile grid straight away.
          ref.invalidate(userVideosNotifierProvider(video.userId));
          return;
        case VideoStatus.failed:
          state = UploadState(
            phase: UploadPhase.failed,
            video: video,
            error: 'The video could not be processed. Try posting it again.',
          );
          return;
        case VideoStatus.processing:
        case VideoStatus.takenDown:
        case VideoStatus.unknown:
          state = UploadState(phase: UploadPhase.processing, progress: 1, video: video);
      }
    }
  }

  void cancel() {
    _cancelToken?.cancel();
    state = const UploadState();
  }

  void reset() => state = const UploadState();

  String _messageFor(AppException e) {
    if (e is ServerException) {
      return switch (e.code) {
        // The retry-after-timeout case: the first attempt did land. Uploading
        // the same file again would only make a duplicate (video doc 3.2).
        'RAW_FILE_ALREADY_PUBLISHED' =>
          'This video was already posted — check your profile.',
        'UNSUPPORTED_UPLOAD_TYPE' =>
          'Only MP4, MOV and WebM videos can be uploaded',
        'FOREIGN_UPLOAD' => 'That upload does not belong to this account',
        _ => e.message,
      };
    }
    return e.message;
  }
}
