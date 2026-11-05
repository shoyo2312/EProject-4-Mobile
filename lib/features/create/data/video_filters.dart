/// The colour filters the editor offers. A copy of the backend's catalogue
/// (`event-schema/.../VideoFilter.java`): the server only takes these ids and
/// applies the same matrices with ffmpeg, which is how the preview here and
/// the published video come out the same colour. A change there is a change
/// here.
class VideoFilterPreset {
  const VideoFilterPreset(this.id, this.name, this.matrix);

  /// What goes over the wire as `edit.filter.id`.
  final String id;
  final String name;

  /// 3x3 over RGB, row-major: the first row is how much of the input's red,
  /// green and blue make the output's red.
  final List<double> matrix;
}

const _luma = [0.299, 0.587, 0.114];

List<double> _diagonal(double r, double g, double b) => [r, 0, 0, 0, g, 0, 0, 0, b];

/// 0 is grey, 1 the original, above 1 more saturated — each channel mixed
/// with the pixel's luma, as on the server.
List<double> _saturation(double s) => [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          (1 - s) * _luma[col] + (row == col ? s : 0),
    ];

final videoFilters = <VideoFilterPreset>[
  VideoFilterPreset('warm', 'Warm', _diagonal(1.08, 1.0, 0.86)),
  VideoFilterPreset('cool', 'Cool', _diagonal(0.9, 1.0, 1.12)),
  VideoFilterPreset('vivid', 'Vivid', _saturation(1.4)),
  VideoFilterPreset('muted', 'Muted', _saturation(0.6)),
  VideoFilterPreset('mono', 'Mono', _saturation(0)),
  const VideoFilterPreset('vintage', 'Vintage', [
    0.393, 0.769, 0.189,
    0.349, 0.686, 0.168,
    0.272, 0.534, 0.131,
  ]),
];

VideoFilterPreset? filterById(String? id) {
  for (final filter in videoFilters) {
    if (filter.id == id) return filter;
  }
  return null;
}

/// The 4x5 matrix Flutter's `ColorFilter.matrix` takes, for [filter] at
/// [intensity]: the 3x3 blended with no change, alpha untouched, no offsets —
/// the server's `colorchannelmixer` has none either.
List<double> colorFilterMatrix(VideoFilterPreset filter, double intensity) {
  final k = intensity.clamp(0.0, 1.0);
  double at(int row, int col) {
    final identity = row == col ? 1.0 : 0.0;
    return identity + (filter.matrix[row * 3 + col] - identity) * k;
  }

  return [
    for (var row = 0; row < 3; row++) ...[at(row, 0), at(row, 1), at(row, 2), 0, 0],
    0, 0, 0, 1, 0,
  ];
}
