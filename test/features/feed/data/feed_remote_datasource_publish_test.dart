import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

/// Answers every request with one PROCESSING video and remembers the body.
class _StubAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final disabled =
        (options.data as Map<String, dynamic>)['commentsDisabled'] == true;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'id': 'v1',
          'userId': 1,
          'title': 'clip',
          'status': 'PROCESSING',
          'visibility': 'PUBLIC',
          'viewCount': 0,
          'likeCount': 0,
          'commentCount': disabled ? null : 0,
          'commentsDisabled': disabled,
          'createdAt': '2026-11-04T00:00:00Z',
        },
        'timestamp': '2026-11-04T00:00:00Z',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _StubAdapter adapter;
  late FeedRemoteDatasource datasource;

  setUp(() {
    final tokenStorage = MockTokenStorage();
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    adapter = _StubAdapter();
    apiClient.dio.httpClientAdapter = adapter;
    datasource = FeedRemoteDatasource(apiClient);
  });

  test('a video posted with comments off says so in the create request',
      () async {
    final created = await datasource.publish(
      title: 'clip',
      rawFileUrl: 's3://video-media/raw/1/clip.mp4',
      visibility: VideoVisibility.public,
      commentsDisabled: true,
    );

    expect(adapter.lastRequest?.path, endsWith('/videos'));
    expect(
      (adapter.lastRequest?.data as Map<String, dynamic>)['commentsDisabled'],
      isTrue,
    );
    expect(created.commentsDisabled, isTrue);
    // The server hides the total while comments are off.
    expect(created.commentCount, 0);
  });

  test("the editor's trim and speed go out as the edit recipe", () async {
    await datasource.publish(
      title: 'clip',
      rawFileUrl: 's3://video-media/raw/1/clip.mp4',
      visibility: VideoVisibility.public,
      edit: const VideoEdit(segments: [
        EditSegment(start: 1.5, end: 6, speed: 2),
      ]),
    );

    // Through JSON, as on the wire: what the server reads is the encoded body.
    final body = jsonDecode(jsonEncode(adapter.lastRequest?.data))
        as Map<String, dynamic>;
    expect(body['edit'], {
      'segments': [
        {'start': 1.5, 'end': 6.0, 'speed': 2.0},
      ],
    });
  });

  test('a colour-only edit sends the filter and no segments', () async {
    await datasource.publish(
      title: 'clip',
      rawFileUrl: 's3://video-media/raw/1/clip.mp4',
      visibility: VideoVisibility.public,
      edit: const VideoEdit(filter: EditFilter(id: 'warm', intensity: 0.6)),
    );

    final body = jsonDecode(jsonEncode(adapter.lastRequest?.data))
        as Map<String, dynamic>;
    expect(body['edit'], {
      'filter': {'id': 'warm', 'intensity': 0.6},
    });
  });

  test('the text and sticker layers go out with their URLs, timing and words',
      () async {
    await datasource.publish(
      title: 'clip',
      rawFileUrl: 's3://video-media/raw/1/clip.mp4',
      visibility: VideoVisibility.public,
      edit: const VideoEdit(overlays: [
        OverlayLayer(path: '/tmp/a.png', imageUrl: 's3://video-media/raw/1/a.png'),
        OverlayLayer(
          path: '/tmp/b.png',
          imageUrl: 's3://video-media/raw/1/b.png',
          start: 1.5,
          end: 4,
          texts: ['Xin chào'],
        ),
      ]),
    );

    final body = jsonDecode(jsonEncode(adapter.lastRequest?.data))
        as Map<String, dynamic>;
    // The local paths never leave the phone; only the uploaded files' URLs.
    expect(body['edit'], {
      'overlays': [
        {'imageUrl': 's3://video-media/raw/1/a.png'},
        {
          'imageUrl': 's3://video-media/raw/1/b.png',
          'start': 1.5,
          'end': 4.0,
          'texts': ['Xin chào'],
        },
      ],
    });
  });

  test('a song goes out as its id and levels', () async {
    await datasource.publish(
      title: 'clip',
      rawFileUrl: 's3://video-media/raw/1/clip.mp4',
      visibility: VideoVisibility.public,
      edit: const VideoEdit(music: EditMusic(trackId: '42', originalVolume: 0.2)),
    );

    final body = jsonDecode(jsonEncode(adapter.lastRequest?.data))
        as Map<String, dynamic>;
    expect(body['edit'], {
      'music': {'trackId': '42', 'start': 0.0, 'volume': 1.0, 'originalVolume': 0.2},
    });
  });

  test('the credit comes back on the video', () {
    final video = VideoModel.fromJson({
      'id': 'v1',
      'userId': 1,
      'title': 'clip',
      'status': 'PUBLISHED',
      'visibility': 'PUBLIC',
      'viewCount': 0,
      'likeCount': 0,
      'commentCount': 0,
      'createdAt': '2026-11-05T00:00:00Z',
      'music': {
        'trackId': '42',
        'title': 'Calm',
        'artist': 'Someone',
        'licenseUrl': 'http://creativecommons.org/licenses/by/3.0/',
        'shareUrl': 'https://www.jamendo.com/track/42',
      },
    });

    expect(video.music?.title, 'Calm');
    expect(video.music?.artist, 'Someone');
  });

  test('an unedited clip sends no edit at all', () async {
    await datasource.publish(
      title: 'clip',
      rawFileUrl: 's3://video-media/raw/1/clip.mp4',
      visibility: VideoVisibility.public,
    );

    expect(
      (adapter.lastRequest?.data as Map<String, dynamic>).containsKey('edit'),
      isFalse,
    );
  });

  test('comments on sends no flag at all, as before', () async {
    await datasource.publish(
      title: 'clip',
      rawFileUrl: 's3://video-media/raw/1/clip.mp4',
      visibility: VideoVisibility.public,
    );

    expect(
      (adapter.lastRequest?.data as Map<String, dynamic>)
          .containsKey('commentsDisabled'),
      isFalse,
    );
  });
}
