import 'package:video_player/video_player.dart';

// On Android, video_player keeps one app-wide audio setting and stamps it on
// each player as it is created, so a player that does not say what it wants
// gets whatever the last one asked for. Every player in the app says.

/// The player that is the screen's sound. It takes audio focus: other apps
/// go quiet for it, and it pauses for a call.
VideoPlayerOptions ownsAudio() => VideoPlayerOptions();

/// A song played under a video in the editor. Two players that both take
/// audio focus pause each other: the song starting stopped the video, and
/// the stopped video then stopped the song.
VideoPlayerOptions mixesAudio() => VideoPlayerOptions(mixWithOthers: true);
