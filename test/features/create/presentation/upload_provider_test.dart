import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/create/presentation/upload_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

class FakeFile extends Fake implements File {
  @override
  String get path => '/tmp/clip.mp4';
}

VideoModel video(VideoStatus status) => VideoModel(
      id: 'v1',
      userId: '1001',
      title: 'clip',
      status: status,
      visibility: VideoVisibility.public,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime(2026, 8, 23),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(VideoVisibility.public);
  });

  late MockFeedRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockFeedRepository();
    container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  UploadState state() => container.read(uploadNotifierProvider);
  UploadNotifier notifier() => container.read(uploadNotifierProvider.notifier);

  test('maps file extensions to the three accepted content types', () {
    expect(contentTypeForPath('/a/b/clip.MP4'), 'video/mp4');
    expect(contentTypeForPath('/a/b/clip.mov'), 'video/quicktime');
    expect(contentTypeForPath('/a/b/clip.webm'), 'video/webm');
    expect(contentTypeForPath('/a/b/clip.avi'), isNull);
    expect(contentTypeForPath('/a/b/clip'), isNull);
  });

  test('publishes, then polls until the video is playable', () async {
    when(() => repository.uploadAndPublish(
          file: any(named: 'file'),
          contentType: any(named: 'contentType'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          visibility: any(named: 'visibility'),
          tags: any(named: 'tags'),
          onProgress: any(named: 'onProgress'),
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((invocation) async {
      final onProgress = invocation.namedArguments[#onProgress]
          as void Function(int, int)?;
      onProgress?.call(5, 10);
      return video(VideoStatus.processing);
    });
    // Still transcoding on the first poll, playable on the second.
    var polls = 0;
    when(() => repository.getVideo('v1')).thenAnswer((_) async =>
        video(polls++ == 0 ? VideoStatus.processing : VideoStatus.published));

    final started = notifier().start(
      file: FakeFile(),
      title: 'clip',
      visibility: VideoVisibility.public,
    );

    await started;

    expect(state().phase, UploadPhase.done);
    expect(state().video?.status, VideoStatus.published);
    expect(polls, 2);
  });

  test('a re-post of the same upload is reported, not retried', () async {
    when(() => repository.uploadAndPublish(
          file: any(named: 'file'),
          contentType: any(named: 'contentType'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          visibility: any(named: 'visibility'),
          tags: any(named: 'tags'),
          onProgress: any(named: 'onProgress'),
          cancelToken: any(named: 'cancelToken'),
        )).thenThrow(const ServerException(
      400,
      'raw file already published',
      code: 'RAW_FILE_ALREADY_PUBLISHED',
    ));

    await notifier().start(
      file: FakeFile(),
      title: 'clip',
      visibility: VideoVisibility.public,
    );

    expect(state().phase, UploadPhase.failed);
    expect(state().error, contains('already posted'));
    verifyNever(() => repository.getVideo(any()));
  });

  test('an unsupported file never reaches the network', () async {
    await notifier().start(
      file: _AviFile(),
      title: 'clip',
      visibility: VideoVisibility.public,
    );

    expect(state().phase, UploadPhase.failed);
    verifyNever(() => repository.uploadAndPublish(
          file: any(named: 'file'),
          contentType: any(named: 'contentType'),
          title: any(named: 'title'),
          visibility: any(named: 'visibility'),
        ));
  });
}

class _AviFile extends Fake implements File {
  @override
  String get path => '/tmp/clip.avi';
}

