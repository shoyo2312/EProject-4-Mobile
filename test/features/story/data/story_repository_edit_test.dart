import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart' show UploadTicket;
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_remote_datasource.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';

class MockStoryRemoteDatasource extends Mock implements StoryRemoteDatasource {}

UploadTicket _ticket(String fileUrl) => UploadTicket(
      uploadUrl: 'http://minio/bucket',
      formFields: const {},
      fileUrl: fileUrl,
      expiresInSeconds: 600,
    );

void main() {
  late MockStoryRemoteDatasource remote;
  late StoryRepository repository;

  setUpAll(() {
    registerFallbackValue(_ticket('s3://fallback'));
    registerFallbackValue(File('/fallback'));
    registerFallbackValue(StoryVisibility.public);
  });

  setUp(() {
    remote = MockStoryRemoteDatasource();
    repository = StoryRepository(remote);
  });

  test('the recipe goes out with the photo length and no edit means no edit field', () {
    const edit = VideoEdit(
      filter: EditFilter(id: 'mono'),
      music: EditMusic(trackId: '42', start: 3),
      overlays: [OverlayLayer(path: '/tmp/o.png', imageUrl: 's3://b/stories/1/2.png', texts: ['hi'])],
    );

    expect(storyEditJson(edit, 10), {
      'filter': {'id': 'mono', 'intensity': 1.0},
      'music': {'trackId': '42', 'start': 3.0, 'volume': 1.0, 'originalVolume': 1.0},
      'overlays': [
        {'imageUrl': 's3://b/stories/1/2.png', 'texts': ['hi']},
      ],
      'photoSeconds': 10.0,
    });
  });

  /// Each layer is uploaded as a PNG of its own before the story is created,
  /// and the create names it by that upload's file URL.
  test('layers go up first and the create names them by their upload', () async {
    final tickets = [_ticket('s3://b/stories/1/10.png'), _ticket('s3://b/stories/1/11.jpg')];
    when(() => remote.createUploadUrl(any())).thenAnswer((_) async => tickets.removeAt(0));
    when(() => remote.uploadFile(any(), any(),
        contentType: any(named: 'contentType'),
        onProgress: any(named: 'onProgress'),
        cancelToken: any(named: 'cancelToken'))).thenAnswer((_) async {});
    when(() => remote.create(
          mediaUrl: any(named: 'mediaUrl'),
          caption: any(named: 'caption'),
          visibility: any(named: 'visibility'),
          edit: any(named: 'edit'),
        )).thenAnswer((_) async => StoryModel(
          id: 's1',
          userId: '1',
          mediaUrl: 'https://signed',
          mediaType: StoryMediaType.image,
          visibility: StoryVisibility.public,
          createdAt: DateTime(2026),
          expiresAt: DateTime(2026),
        ));

    await repository.uploadAndCreate(
      file: File('/tmp/photo.png'),
      contentType: 'image/png',
      edit: const VideoEdit(overlays: [OverlayLayer(path: '/tmp/o.png', texts: ['hi'])]),
      visibility: StoryVisibility.public,
    );

    verifyInOrder([
      () => remote.createUploadUrl('image/png'),
      () => remote.createUploadUrl('image/png'),
    ]);
    final body = verify(() => remote.create(
          mediaUrl: 's3://b/stories/1/11.jpg',
          caption: null,
          visibility: StoryVisibility.public,
          edit: captureAny(named: 'edit'),
        )).captured.single as Map<String, dynamic>;
    expect(body['overlays'], [
      {'imageUrl': 's3://b/stories/1/10.png', 'texts': ['hi']},
    ]);
    expect(body.containsKey('photoSeconds'), isFalse);
  });

  test('the credit for the song comes back on the story', () {
    final story = StoryModel.fromJson({
      'id': 's1',
      'userId': 7,
      'mediaUrl': 'https://cdn.test/s.mp4',
      'mediaType': 'VIDEO',
      'visibility': 'PUBLIC',
      'createdAt': '2026-11-01T10:00:00Z',
      'expiresAt': '2026-11-02T10:00:00Z',
      'music': {'trackId': '42', 'title': 'Calm', 'artist': 'Someone'},
    });

    expect(story.music?.title, 'Calm');
    expect(story.music?.artist, 'Someone');
  });
}
