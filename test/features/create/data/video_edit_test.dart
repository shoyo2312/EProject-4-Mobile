import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';

void main() {
  group('overlays', () {
    const layered = VideoEdit(overlays: [OverlayLayer(path: '/tmp/o.png')]);

    test('text or stickers alone are a change worth sending', () {
      expect(layered.isUnchanged(const Duration(seconds: 10)), isFalse);
    });

    test('the local PNG paths are not part of the JSON', () {
      expect(layered.toJson().containsKey('overlays'), isFalse);
    });
  });

  /// Overlay timings are set on the clock the viewer sees: after the cuts,
  /// with each segment's speed applied.
  group('the edited clock', () {
    const edit = VideoEdit(segments: [
      EditSegment(start: 2, end: 4, speed: 1), // plays 0–2
      EditSegment(start: 10, end: 14, speed: 2), // plays 2–4
    ]);

    test('playedAt maps the raw file onto it, and a cut onto nothing', () {
      expect(edit.playedAt(const Duration(seconds: 3)), closeTo(1, 1e-9));
      expect(edit.playedAt(const Duration(seconds: 12)), closeTo(3, 1e-9));
      expect(edit.playedAt(const Duration(seconds: 6)), isNull);
    });

    test('rawAt finds the raw position that shows a moment of it', () {
      expect(edit.rawAt(1), const Duration(seconds: 3));
      expect(edit.rawAt(3), const Duration(seconds: 12));
      expect(edit.rawAt(99), const Duration(seconds: 14));
    });

    test('without segments both clocks are the same', () {
      expect(const VideoEdit().playedAt(const Duration(milliseconds: 1500)), 1.5);
      expect(const VideoEdit().rawAt(1.5), const Duration(milliseconds: 1500));
    });
  });

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

  group('a colour-only edit', () {
    const edit = VideoEdit(filter: EditFilter(id: 'mono'));

    test('is a change, though it cuts nothing', () {
      expect(edit.isUnchanged(const Duration(seconds: 10)), isFalse);
    });

    test('plays the whole clip, at normal speed', () {
      expect(edit.playedWithin(const Duration(seconds: 10)), const Duration(seconds: 10));
      expect(edit.playbackAt(const Duration(seconds: 4)), (jumpTo: null, speed: 1.0));
    });
  });
}
