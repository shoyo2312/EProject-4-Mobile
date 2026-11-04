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
}
