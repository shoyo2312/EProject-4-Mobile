import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';

void main() {
  group('StoryModel.fromJson', () {
    test('reads the owner view, numeric ids included', () {
      final story = StoryModel.fromJson({
        'id': '6721abc',
        'userId': 1234567890123456789,
        'mediaUrl': 'https://cdn.test/s.jpg?sig=1',
        'mediaType': 'IMAGE',
        'caption': 'hi',
        'visibility': 'FRIENDS',
        'status': 'PENDING_MODERATION',
        'durationSeconds': null,
        'viewCount': 4,
        'viewedByMe': false,
        'myReaction': null,
        'reactionCounts': {'LOVE': 3, 'WOW': 1},
        'createdAt': '2026-11-01T10:00:00Z',
        'expiresAt': '2026-11-02T10:00:00Z',
      });

      expect(story.userId, '1234567890123456789');
      expect(story.visibility, StoryVisibility.friends);
      expect(story.status, StoryStatus.pendingModeration);
      expect(story.viewCount, 4);
      expect(story.reactionCounts, {
        StoryReaction.love: 3,
        StoryReaction.wow: 1,
      });
    });

    test('a viewer gets nulls for the owner-only fields', () {
      final story = StoryModel.fromJson({
        'id': 's1',
        'userId': 7,
        'mediaUrl': 'https://cdn.test/s.mp4',
        'mediaType': 'VIDEO',
        'visibility': 'PUBLIC',
        'status': null,
        'durationSeconds': 12,
        'viewCount': null,
        'viewedByMe': true,
        'myReaction': 'SAD',
        'reactionCounts': null,
        'createdAt': '2026-11-01T10:00:00Z',
        'expiresAt': '2026-11-02T10:00:00Z',
      });

      expect(story.status, isNull);
      expect(story.viewCount, isNull);
      expect(story.reactionCounts, isNull);
      expect(story.mediaType, StoryMediaType.video);
      expect(story.myReaction, StoryReaction.sad);
    });

    test('values the app does not know yet do not fail the parse', () {
      final story = StoryModel.fromJson({
        'id': 's1',
        'userId': 7,
        'mediaUrl': 'u',
        'mediaType': 'AUDIO',
        'visibility': 'CLOSE_FRIENDS',
        'status': 'ARCHIVED',
        'myReaction': 'HAHA',
        'reactionCounts': {'HAHA': 2, 'LIKE': 1},
        'createdAt': '2026-11-01T10:00:00Z',
        'expiresAt': '2026-11-02T10:00:00Z',
      });

      expect(story.mediaType, StoryMediaType.unknown);
      expect(story.visibility, StoryVisibility.unknown);
      expect(story.status, StoryStatus.unknown);
      expect(story.myReaction, StoryReaction.unknown);
      expect(story.reactionCounts, {StoryReaction.like: 1});
    });
  });

  test('groups and rings read numeric user ids as strings', () {
    final group = StoryGroup.fromJson({
      'userId': 42,
      'stories': <Object>[],
      'hasUnseen': true,
    });
    final ring = StoryRing.fromJson({'userId': 42, 'hasUnseen': false});
    final viewer = StoryViewer.fromJson({
      'viewerId': 9,
      'viewedAt': '2026-11-01T10:00:00Z',
      'reaction': 'LIKE',
    });

    expect(group.userId, '42');
    expect(ring.userId, '42');
    expect(viewer.viewerId, '9');
    expect(viewer.reaction, StoryReaction.like);
  });

  group('storyContentTypeForPath', () {
    test('accepts what story-service accepts', () {
      expect(storyContentTypeForPath('/a/b.JPG'), 'image/jpeg');
      expect(storyContentTypeForPath('/a/b.png'), 'image/png');
      expect(storyContentTypeForPath('/a/b.webp'), 'image/webp');
      expect(storyContentTypeForPath('/a/b.mp4'), 'video/mp4');
      expect(storyContentTypeForPath('/a/b.webm'), 'video/webm');
    });

    test('refuses what it would refuse — QuickTime and HEIC included', () {
      expect(storyContentTypeForPath('/a/b.mov'), isNull);
      expect(storyContentTypeForPath('/a/b.heic'), isNull);
      expect(storyContentTypeForPath('/a/noextension'), isNull);
    });
  });

  test('wire names round-trip', () {
    expect(wireStoryVisibility(StoryVisibility.friends), 'FRIENDS');
    expect(wireStoryVisibility(StoryVisibility.unknown), 'PUBLIC');
    expect(StoryReaction.wow.wire, 'WOW');
  });
}
