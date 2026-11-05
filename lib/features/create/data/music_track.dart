import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_track.freezed.dart';
part 'music_track.g.dart';

/// A song the editor can put under a video, from `GET /videos/music` (video
/// doc 3.10). Every one is Creative Commons music the server has already
/// checked may be put to a video.
@freezed
class MusicTrack with _$MusicTrack {
  const factory MusicTrack({
    required String id,
    required String title,
    required String artist,
    @Default(0) int durationSeconds,

    /// A stream to preview with. Short-lived: play it now, never keep it.
    required String audioUrl,
    String? imageUrl,

    /// The Creative Commons licence; shown with the credit.
    String? licenseUrl,
    String? shareUrl,
  }) = _MusicTrack;

  factory MusicTrack.fromJson(Map<String, dynamic> json) =>
      _$MusicTrackFromJson(json);
}
