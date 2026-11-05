import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_edit.freezed.dart';
part 'video_edit.g.dart';

/// The speeds the editor offers, slowest first (video doc 3.2 accepts 0.25–4).
const editorSpeeds = [0.3, 0.5, 1.0, 2.0, 3.0];

/// The edits made in the editor, sent with `POST /videos` as `edit`. The app
/// only previews them; media-worker cuts the stored video from the raw upload
/// with this recipe (video doc 3.2, "Chỉnh sửa trong app").
@freezed
class VideoEdit with _$VideoEdit {
  const VideoEdit._();

  const factory VideoEdit({
    required List<EditSegment> segments,
  }) = _VideoEdit;

  factory VideoEdit.fromJson(Map<String, dynamic> json) =>
      _$VideoEditFromJson(json);

  /// One trimmed range at one speed — everything the editor can make today.
  factory VideoEdit.single({
    required Duration start,
    required Duration end,
    double speed = 1.0,
  }) =>
      VideoEdit(segments: [
        EditSegment(
          start: start.inMilliseconds / 1000,
          end: end.inMilliseconds / 1000,
          speed: speed,
        ),
      ]);

  /// Whether this would come out the same as the upload itself. Such an edit
  /// is not sent at all: the server would only re-encode for nothing.
  bool isUnchanged(Duration duration) {
    if (segments.length != 1) return false;
    final only = segments.single;
    const slack = 0.05;
    return only.start <= slack &&
        only.end >= duration.inMilliseconds / 1000 - slack &&
        only.speed == 1.0;
  }

  /// How long the edited video plays for, speed included.
  Duration get playedDuration => playedWithin(null);

  /// [playedDuration] for a file of [duration], counting a segment that runs
  /// past the end only up to where the file stops — as the server will.
  Duration playedWithin(Duration? duration) {
    final limit = duration == null ? double.infinity : duration.inMilliseconds / 1000;
    var ms = 0.0;
    for (final s in segments) {
      final end = s.end < limit ? s.end : limit;
      if (end > s.start) ms += (end - s.start) / s.speed * 1000;
    }
    return Duration(milliseconds: ms.round());
  }

  /// How a preview should play the raw file at [position] to show this edit:
  /// the speed of the segment being played, and where to jump when playback
  /// is outside every segment — in a cut, or past the last one, which loops
  /// back to the first.
  ///
  /// A position up to [_seekSlack] before a segment's start counts as inside
  /// it: a seek lands on the nearest key frame, often a little early, and
  /// treating that as outside would seek again forever.
  ({Duration? jumpTo, double speed}) playbackAt(Duration position) {
    final at = position.inMilliseconds / 1000;
    for (final s in segments) {
      if (at >= s.start - _seekSlack && at < s.end) {
        return (jumpTo: null, speed: s.speed);
      }
    }
    final next = segments.where((s) => s.start > at).firstOrNull ?? segments.first;
    return (jumpTo: _duration(next.start), speed: next.speed);
  }

  static const _seekSlack = 0.3;

  static Duration _duration(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());
}

/// Seconds on the raw upload's own clock, before the speed change.
@freezed
class EditSegment with _$EditSegment {
  const factory EditSegment({
    required double start,
    required double end,
    @Default(1.0) double speed,
  }) = _EditSegment;

  factory EditSegment.fromJson(Map<String, dynamic> json) =>
      _$EditSegmentFromJson(json);
}
