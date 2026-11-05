import 'package:tiktok_mobile/features/create/data/video_edit.dart';

/// One press of the shutter: how long the camera ran, and the speed the
/// poster picked for it.
class RecordedClip {
  const RecordedClip({
    required this.length,
    this.speed = 1.0,
    this.discarded = false,
  });

  /// Wall-clock time the recorder ran for, which is this clip's length in
  /// the recorded file.
  final Duration length;
  final double speed;

  /// Removed with "delete last clip". The footage is still in the file —
  /// one file is all the recorder makes — so it is left out of the edit.
  final bool discarded;

  Duration get played => Duration(
        microseconds: (length.inMicroseconds / speed).round(),
      );

  RecordedClip discard() =>
      RecordedClip(length: length, speed: speed, discarded: true);
}

/// The clips of one in-app recording, in the order they were shot.
///
/// The recorder pauses between clips rather than stopping, so they all land
/// back to back in one file. Speeds and deleted clips cannot be baked into
/// that file on the phone; they become the [VideoEdit] the server cuts it
/// with, the same recipe the trim editor sends.
class RecordingSession {
  const RecordingSession([this.clips = const []]);

  final List<RecordedClip> clips;

  bool get isEmpty => kept.isEmpty;

  Iterable<RecordedClip> get kept => clips.where((c) => !c.discarded);

  /// How long the posted video will play: what counts against the length
  /// limit, since a slowed-down clip comes out longer than it was shot.
  Duration get played =>
      kept.fold(Duration.zero, (sum, clip) => sum + clip.played);

  /// Where each kept clip ends on the played timeline, for the progress bar's
  /// clip markers.
  List<Duration> get playedMarks {
    var at = Duration.zero;
    return [
      for (final clip in kept) at += clip.played,
    ];
  }

  RecordingSession add(RecordedClip clip) =>
      RecordingSession([...clips, clip]);

  /// Takes the newest kept clip out of the video.
  RecordingSession discardLast() {
    final index = clips.lastIndexWhere((c) => !c.discarded);
    if (index < 0) return this;
    return RecordingSession([
      for (var i = 0; i < clips.length; i++)
        i == index ? clips[i].discard() : clips[i],
    ]);
  }

  /// The recipe for the server, or null when the recorded file already is
  /// the video: every clip kept, all at normal speed.
  ///
  /// Neighbouring kept clips at the same speed are joined into one segment,
  /// since each segment boundary is a cut the server has to make. The last
  /// segment runs a second past the measured end: the clip lengths are timed
  /// on the phone and the file can run slightly longer, and an end past the
  /// file just stops where the file does.
  VideoEdit? toEdit() {
    if (clips.every((c) => !c.discarded && c.speed == 1.0)) return null;

    final segments = <EditSegment>[];
    var cursor = 0.0;
    for (final clip in clips) {
      final start = cursor;
      cursor += clip.length.inMicroseconds / Duration.microsecondsPerSecond;
      if (clip.discarded) continue;
      final previous = segments.isEmpty ? null : segments.last;
      if (previous != null &&
          previous.speed == clip.speed &&
          (previous.end - start).abs() < 1e-9) {
        segments[segments.length - 1] = previous.copyWith(end: cursor);
      } else {
        segments.add(EditSegment(start: start, end: cursor, speed: clip.speed));
      }
    }
    if (segments.isEmpty) return null;
    if (!clips.last.discarded) {
      segments[segments.length - 1] =
          segments.last.copyWith(end: segments.last.end + 1);
    }
    return VideoEdit(segments: segments);
  }
}
