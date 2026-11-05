import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/create/data/video_filters.dart';

void main() {
  /// The server accepts exactly these ids (event-schema VideoFilter); one the
  /// server does not know is a 400 at publish.
  test('the ids are the backend catalogue\'s', () {
    expect(videoFilters.map((f) => f.id), ['warm', 'cool', 'vivid', 'muted', 'mono', 'vintage']);
  });

  /// Pinned to the numbers in VideoFilter.java: the preview only matches the
  /// published video while both sides use the same matrix.
  test('the matrices are the backend catalogue\'s', () {
    expect(filterById('warm')!.matrix, [1.08, 0, 0, 0, 1.0, 0, 0, 0, 0.86]);
    expect(filterById('cool')!.matrix, [0.9, 0, 0, 0, 1.0, 0, 0, 0, 1.12]);
    expect(filterById('mono')!.matrix.take(3), [0.299, 0.587, 0.114]);
    for (final (i, v) in [1.2804, -0.2348, -0.0456].indexed) {
      expect(filterById('vivid')!.matrix[i], closeTo(v, 1e-9));
    }
    expect(filterById('vintage')!.matrix.first, 0.393);
  });

  test('every saturation filter leaves grey alone', () {
    for (final id in ['vivid', 'muted', 'mono']) {
      final m = filterById(id)!.matrix;
      for (var row = 0; row < 3; row++) {
        expect(m[row * 3] + m[row * 3 + 1] + m[row * 3 + 2], closeTo(1, 1e-9), reason: id);
      }
    }
  });

  group('colorFilterMatrix', () {
    const identity = [1.0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

    test('intensity 0 changes nothing', () {
      expect(colorFilterMatrix(filterById('vintage')!, 0), identity);
    });

    test('puts the 3x3 in the first three columns, no offsets, alpha kept', () {
      expect(colorFilterMatrix(filterById('warm')!, 1), [
        1.08, 0, 0, 0, 0,
        0, 1.0, 0, 0, 0,
        0, 0, 0.86, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    });

    test('blends towards no change at partial intensity, as the server does', () {
      final half = colorFilterMatrix(filterById('warm')!, 0.5);
      expect(half[0], closeTo(1.04, 1e-12));
      expect(half[12], closeTo(0.93, 1e-12));
    });
  });

  test('an unknown id is no filter', () {
    expect(filterById('sepia'), isNull);
    expect(filterById(null), isNull);
  });
}
