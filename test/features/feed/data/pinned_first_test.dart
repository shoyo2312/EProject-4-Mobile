import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

VideoModel video(String id, {required int day, int? pinnedDay}) => VideoModel(
      id: id,
      userId: 'u',
      title: id,
      status: VideoStatus.published,
      visibility: VideoVisibility.public,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime(2026, 8, day),
      pinnedAt: pinnedDay == null ? null : DateTime(2026, 9, pinnedDay),
    );

void main() {
  test('pinned videos lead, latest pin first, then the rest newest first', () {
    final sorted = pinnedFirst([
      video('old', day: 1),
      video('pinnedEarly', day: 2, pinnedDay: 1),
      video('new', day: 9),
      video('pinnedLate', day: 3, pinnedDay: 5),
    ]);

    expect(sorted.map((v) => v.id), ['pinnedLate', 'pinnedEarly', 'new', 'old']);
  });

  test('an unpinned video goes back to its place by date', () {
    final sorted = pinnedFirst([
      video('b', day: 5),
      video('c', day: 3),
      video('a', day: 7),
    ]);

    expect(sorted.map((v) => v.id), ['a', 'b', 'c']);
  });

  test('ties keep the order they came in', () {
    final ids = [for (var i = 0; i < 40; i++) 'v$i'];
    final sorted = pinnedFirst([for (final id in ids) video(id, day: 1)]);

    expect(sorted.map((v) => v.id), ids);
  });
}
