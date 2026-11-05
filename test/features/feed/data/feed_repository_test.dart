import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class MockFeedRemoteDatasource extends Mock implements FeedRemoteDatasource {}

VideoModel makeVideo(String id) => VideoModel(
      id: id,
      userId: '123',
      title: 'title $id',
      hlsUrl: 'https://cdn.test/$id.m3u8',
      status: VideoStatus.published,
      visibility: VideoVisibility.public,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime(2026, 8, 12),
    );

void main() {
  late MockFeedRemoteDatasource remoteDatasource;
  late FeedRepository repository;

  setUp(() {
    remoteDatasource = MockFeedRemoteDatasource();
    repository = FeedRepository(remoteDatasource);
  });

  group('uploadAndPublish', () {
    UploadTicket ticket(String fileUrl) => UploadTicket(
          uploadUrl: 'http://localhost:9000/video-media',
          formFields: const {},
          fileUrl: fileUrl,
          expiresInSeconds: 900,
        );

    setUp(() {
      registerFallbackValue(ticket('s3://fallback'));
      registerFallbackValue(File('fallback'));
      registerFallbackValue(VideoVisibility.public);
      registerFallbackValue(const VideoEdit());
      var png = 0;
      when(() => remoteDatasource.createUploadUrl('image/png'))
          .thenAnswer((_) async => ticket('s3://video-media/raw/1/layer-${png++}.png'));
      when(() => remoteDatasource.createUploadUrl('video/mp4'))
          .thenAnswer((_) async => ticket('s3://video-media/raw/1/clip.mp4'));
      when(() => remoteDatasource.uploadFile(any(), any(),
          contentType: any(named: 'contentType'),
          onProgress: any(named: 'onProgress'),
          cancelToken: any(named: 'cancelToken'))).thenAnswer((_) async {});
      when(() => remoteDatasource.publish(
            title: any(named: 'title'),
            description: any(named: 'description'),
            rawFileUrl: any(named: 'rawFileUrl'),
            visibility: any(named: 'visibility'),
            tags: any(named: 'tags'),
            commentsDisabled: any(named: 'commentsDisabled'),
            edit: any(named: 'edit'),
          )).thenAnswer((_) async => makeVideo('v1'));
    });

    test('uploads every overlay layer before the video and publishes their URLs',
        () async {
      await repository.uploadAndPublish(
        file: File('/tmp/clip.mp4'),
        contentType: 'video/mp4',
        title: 'clip',
        visibility: VideoVisibility.public,
        edit: const VideoEdit(overlays: [
          OverlayLayer(path: '/tmp/a.png'),
          OverlayLayer(path: '/tmp/b.png', start: 1, end: 2, texts: ['Hi']),
        ]),
      );

      final uploads = verify(() => remoteDatasource.uploadFile(
            captureAny(),
            captureAny(),
            contentType: captureAny(named: 'contentType'),
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
          )).captured;
      expect(
        [for (var i = 0; i < uploads.length; i += 3) (uploads[i + 1] as File).path],
        ['/tmp/a.png', '/tmp/b.png', '/tmp/clip.mp4'],
      );
      expect([uploads[2], uploads[5], uploads[8]], ['image/png', 'image/png', 'video/mp4']);
      final published = verify(() => remoteDatasource.publish(
            title: 'clip',
            description: null,
            rawFileUrl: 's3://video-media/raw/1/clip.mp4',
            visibility: VideoVisibility.public,
            tags: const [],
            commentsDisabled: false,
            edit: captureAny(named: 'edit'),
          )).captured.single as VideoEdit;
      expect(published.overlays.map((l) => l.imageUrl),
          ['s3://video-media/raw/1/layer-0.png', 's3://video-media/raw/1/layer-1.png']);
      expect(published.overlays[1].texts, ['Hi']);
    });

    test('without text or stickers asks for no image upload', () async {
      await repository.uploadAndPublish(
        file: File('/tmp/clip.mp4'),
        contentType: 'video/mp4',
        title: 'clip',
        visibility: VideoVisibility.public,
      );

      verifyNever(() => remoteDatasource.createUploadUrl('image/png'));
      verify(() => remoteDatasource.publish(
            title: any(named: 'title'),
            description: any(named: 'description'),
            rawFileUrl: any(named: 'rawFileUrl'),
            visibility: any(named: 'visibility'),
            tags: any(named: 'tags'),
            commentsDisabled: any(named: 'commentsDisabled'),
            edit: null,
          )).called(1);
    });
  });

  test('fetchFeed passes the page through from the datasource', () async {
    final page = VideoPage(items: [makeVideo('v1')]);
    when(() => remoteDatasource.fetchFeed(cursor: null, size: 20))
        .thenAnswer((_) async => page);

    final result = await repository.fetchFeed();

    expect(result.items.map((v) => v.id), ['v1']);
    expect(result.nextCursor, isNull);
  });

  test('fetchFeed converts a DioException into an AppException', () async {
    when(() => remoteDatasource.fetchFeed(cursor: null, size: 20)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/videos/feed'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repository.fetchFeed(), throwsA(isA<NetworkException>()));
  });

  test('deleteVideo surfaces NOT_VIDEO_OWNER as a ServerException', () async {
    when(() => remoteDatasource.deleteVideo('v1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/videos/v1'),
        response: Response(
          requestOptions: RequestOptions(path: '/videos/v1'),
          statusCode: 403,
          data: {'success': false, 'code': 'NOT_VIDEO_OWNER', 'message': 'nope'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.deleteVideo('v1'),
      throwsA(
        isA<ServerException>().having((e) => e.code, 'code', 'NOT_VIDEO_OWNER'),
      ),
    );
  });
}
