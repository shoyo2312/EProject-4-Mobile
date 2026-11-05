import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/create/data/recording_session.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';

void main() {
  RecordedClip clip(int seconds, [double speed = 1]) =>
      RecordedClip(length: Duration(seconds: seconds), speed: speed);

  test('clips all kept at normal speed need no edit: the file is the video', () {
    final session = const RecordingSession().add(clip(3)).add(clip(4));

    expect(session.toEdit(), isNull);
    expect(session.played, const Duration(seconds: 7));
  });

  test('a speed per clip becomes a segment per clip, back to back in the file', () {
    final session = const RecordingSession().add(clip(4)).add(clip(6, 2));

    expect(session.toEdit()!.segments, const [
      EditSegment(start: 0, end: 4, speed: 1),
      // A second past the measured end: the file may run a little longer.
      EditSegment(start: 4, end: 11, speed: 2),
    ]);
    // Four seconds, then six at double speed.
    expect(session.played, const Duration(seconds: 7));
  });

  test('neighbouring clips at the same speed are one cut, not two', () {
    final session =
        const RecordingSession().add(clip(2, 2)).add(clip(2, 2)).add(clip(3));

    expect(session.toEdit()!.segments, const [
      EditSegment(start: 0, end: 4, speed: 2),
      EditSegment(start: 4, end: 8, speed: 1),
    ]);
  });

  test('a deleted clip is left out of the edit but keeps its place in the file', () {
    final session = const RecordingSession()
        .add(clip(3))
        .add(clip(2))
        .discardLast()
        .add(clip(4));

    expect(session.toEdit()!.segments, const [
      EditSegment(start: 0, end: 3, speed: 1),
      EditSegment(start: 5, end: 10, speed: 1),
    ]);
    expect(session.played, const Duration(seconds: 7));
    expect(session.playedMarks, const [Duration(seconds: 3), Duration(seconds: 7)]);
  });

  test('deleting the last clip leaves the end of the file out, with no slack', () {
    final session = const RecordingSession().add(clip(3)).add(clip(2)).discardLast();

    expect(session.toEdit()!.segments, const [EditSegment(start: 0, end: 3, speed: 1)]);
  });

  test('deleting every clip leaves nothing to post', () {
    final session = const RecordingSession().add(clip(3)).discardLast();

    expect(session.isEmpty, isTrue);
    expect(session.discardLast().clips, session.clips);
  });
}
