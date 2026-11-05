import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';

void main() {
  const tenSeconds = Duration(seconds: 10);

  group('VideoEdit.single', () {
    test('turns the trim handles into seconds on the upload\'s clock', () {
      final edit = VideoEdit.single(
        start: const Duration(milliseconds: 1500),
        end: const Duration(milliseconds: 7250),
        speed: 2,
      );

      expect(edit.segments, const [EditSegment(start: 1.5, end: 7.25, speed: 2)]);
    });
  });

  group('isUnchanged', () {
    test('the whole clip at normal speed is no edit', () {
      final edit = VideoEdit.single(start: Duration.zero, end: tenSeconds);

      expect(edit.isUnchanged(tenSeconds), isTrue);
    });

    test('a trim from either end is an edit', () {
      expect(
        VideoEdit.single(start: const Duration(seconds: 1), end: tenSeconds)
            .isUnchanged(tenSeconds),
        isFalse,
      );
      expect(
        VideoEdit.single(start: Duration.zero, end: const Duration(seconds: 9))
            .isUnchanged(tenSeconds),
        isFalse,
      );
    });

    test('a speed change is an edit', () {
      final edit =
          VideoEdit.single(start: Duration.zero, end: tenSeconds, speed: 0.5);

      expect(edit.isUnchanged(tenSeconds), isFalse);
    });
  });

  test('playedDuration counts the speed', () {
    final edit = VideoEdit.single(
      start: const Duration(seconds: 2),
      end: const Duration(seconds: 8),
      speed: 2,
    );

    expect(edit.playedDuration, const Duration(seconds: 3));
  });

  test('a segment serializes to the fields video doc 3.2 names', () {
    expect(
      const EditSegment(start: 1, end: 4, speed: 3).toJson(),
      {'start': 1.0, 'end': 4.0, 'speed': 3.0},
    );
  });

  group('playbackAt', () {
    const edit = VideoEdit(segments: [
      EditSegment(start: 1, end: 3, speed: 1),
      EditSegment(start: 5, end: 8, speed: 2),
    ]);

    test('inside a segment: keep playing at its speed', () {
      expect(edit.playbackAt(const Duration(seconds: 2)), (jumpTo: null, speed: 1.0));
      expect(edit.playbackAt(const Duration(seconds: 6)), (jumpTo: null, speed: 2.0));
    });

    test('in a cut: jump to the next segment', () {
      expect(edit.playbackAt(const Duration(seconds: 4)),
          (jumpTo: const Duration(seconds: 5), speed: 2.0));
    });

    test('before the first or past the last: back to the first', () {
      expect(edit.playbackAt(Duration.zero), (jumpTo: const Duration(seconds: 1), speed: 1.0));
      expect(edit.playbackAt(const Duration(seconds: 9)),
          (jumpTo: const Duration(seconds: 1), speed: 1.0));
    });

    /// A seek lands on a key frame, often a little early; seeking again from
    /// there would never end.
    test('just before a segment after a seek counts as inside it', () {
      expect(edit.playbackAt(const Duration(milliseconds: 4800)),
          (jumpTo: null, speed: 2.0));
    });
  });

  test('playedWithin stops a segment where the file does', () {
    const edit = VideoEdit(segments: [EditSegment(start: 0, end: 11, speed: 2)]);

    expect(edit.playedWithin(const Duration(seconds: 10)), const Duration(seconds: 5));
  });
}
