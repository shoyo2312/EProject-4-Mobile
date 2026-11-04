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
  Duration get playedDuration => Duration(
        milliseconds: segments
            .map((s) => (s.end - s.start) / s.speed * 1000)
            .fold<double>(0, (sum, ms) => sum + ms)
            .round(),
      );
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
