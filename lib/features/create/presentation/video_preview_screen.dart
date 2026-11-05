import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/create/presentation/post_details_screen.dart';
import 'package:video_player/video_player.dart';

/// Step 2 of the create flow: trim the clip and pick its speed before
/// committing to it. Resolves `true` once the post is up, `null` if the poster
/// backed out of either step.
///
/// [edit] is what the in-app camera already made of the recording — speeds
/// and deleted clips. A single segment stays editable; several are previewed
/// as they are and sent unchanged.
Future<bool?> showVideoPreview(
  BuildContext context, {
  required File file,
  VideoEdit? edit,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => VideoPreviewScreen(file: file, initialEdit: edit),
    ),
  );
}

/// Reopens the same player from the details screen, purely to watch the clip
/// again as it will be posted — no controls, back is the only way out.
Future<void> showVideoReview(
  BuildContext context, {
  required File file,
  VideoEdit? edit,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => VideoPreviewScreen(
        file: file,
        collectDetails: false,
        initialEdit: edit,
      ),
    ),
  );
}

/// Shortest clip the trim handles can make. Anything shorter is a flicker.
const _minClip = Duration(seconds: 1);

/// Plays the local file — not [VideoPlayerWidget], which is network-only and
/// reports watch time to interaction-service. Nothing here is a watch.
///
/// The edits are only previewed: the player loops inside the trimmed range at
/// the chosen speed, and the upload stays the untouched recording. The server
/// cuts the stored video from it with the [VideoEdit] sent on publish.
class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.file,
    this.collectDetails = true,
    this.initialEdit,
  });

  final File file;

  /// False when the details screen reopens this to re-watch the clip: the
  /// details are already being filled in one route below, and the edit is
  /// already made, so the editing controls are hidden too.
  final bool collectDetails;

  /// The edit to preview with. One segment loads into the trim and speed
  /// controls; several — clips recorded at different speeds, or with one
  /// deleted — are played as they are and cannot be trimmed here.
  final VideoEdit? initialEdit;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late final VideoPlayerController _controller;
  var _ready = false;

  var _duration = Duration.zero;
  var _start = Duration.zero;
  var _end = Duration.zero;
  var _speed = 1.0;

  /// Several segments from the camera: played as recorded, not editable.
  late final bool _locked = (widget.initialEdit?.segments.length ?? 0) > 1;

  /// The rate last handed to the player, so it is only set on a change.
  double? _playingSpeed;

  /// Set while a seek is in flight, so the position updates that arrive
  /// before it lands do not ask for the same seek again.
  var _seeking = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..setLooping(true)
      ..addListener(_followEdit)
      ..initialize().then((_) {
        if (!mounted) return;
        _duration = _controller.value.duration;
        _end = _duration;
        final segment = widget.initialEdit?.segments.firstOrNull;
        if (segment != null && !_locked) {
          _start = _seconds(segment.start);
          _end = _seconds(segment.end) < _duration ? _seconds(segment.end) : _duration;
          _speed = segment.speed;
        }
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.removeListener(_followEdit);
    _controller.dispose();
    super.dispose();
  }

  static Duration _seconds(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  /// What playback follows: the camera's segments, or the trim and speed
  /// set here.
  VideoEdit get _playback => _locked
      ? widget.initialEdit!
      : VideoEdit.single(start: _start, end: _end, speed: _speed);

  /// The preview of an edit: playback jumps over what is cut — before the
  /// trim, between segments, past the end, or back at zero after the
  /// player's own loop — and each segment plays at its own speed.
  Future<void> _followEdit() async {
    if (!_ready || _seeking) return;
    final at = _playback.playbackAt(_controller.value.position);
    if (at.speed != _playingSpeed) {
      _playingSpeed = at.speed;
      await _applySpeed(at.speed);
    }
    final jumpTo = at.jumpTo;
    if (jumpTo != null) {
      _seeking = true;
      await _controller.seekTo(jumpTo);
      _seeking = false;
    }
  }

  /// Some platforms refuse rates their decoder cannot do; the preview then
  /// plays at normal speed, and the server still applies the chosen one.
  Future<void> _applySpeed(double speed) async {
    try {
      await _controller.setPlaybackSpeed(speed);
    } catch (_) {
      // Preview only — the edit sent on publish is what counts.
    }
  }

  void _onTrim(RangeValues values) {
    final start = Duration(milliseconds: values.start.round());
    final end = Duration(milliseconds: values.end.round());
    if (end - start < _minClip) return;
    final startMoved = start != _start;
    setState(() {
      _start = start;
      _end = end;
    });
    // Dragging the start handle shows the frame it lands on; dragging the end
    // handle leaves playback where it is until it reaches the new end.
    if (startMoved) _controller.seekTo(start);
  }

  void _onSpeed(double speed) => setState(() => _speed = speed);

  /// Null when nothing was changed, so an untouched clip is not re-encoded.
  VideoEdit? get _edit {
    if (_locked) return widget.initialEdit;
    final edit = _playback;
    return edit.isUnchanged(_duration) ? null : edit;
  }

  /// Playback is paused across the details screen: the clip looping under a
  /// keyboard is only noise, and its audio would keep running.
  Future<void> _continue() async {
    await _controller.pause();
    if (!mounted) return;
    final posted = await showPostDetails(context, file: widget.file, edit: _edit);
    if (!mounted) return;
    if (posted != true) {
      await _controller.play();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final editing = widget.collectDetails && _ready && !_locked;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            GestureDetector(
              key: const Key('preview_playback_toggle'),
              onTap: () => setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              }),
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const LoadingView(),
          if (_ready && !_controller.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, size: 56, color: Colors.white70),
            ),
          Positioned(
            left: 14,
            top: top + 10,
            child: GestureDetector(
              key: const Key('preview_back_button'),
              onTap: () => Navigator.of(context).pop(),
              child: Glass(
                radius: 12,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.arrow_back, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (editing) ...[
                  _SpeedPicker(speed: _speed, onChanged: _onSpeed),
                  const SizedBox(height: 14),
                  _TrimBar(
                    duration: _duration,
                    start: _start,
                    end: _end,
                    played: _edit?.playedDuration ?? _duration,
                    onChanged: _onTrim,
                  ),
                ] else if (_ready && _locked)
                  Glass(
                    radius: 14,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '${widget.initialEdit!.segments.length} clips · '
                        '${_TrimBar._clock(widget.initialEdit!.playedWithin(_duration))}',
                        key: const Key('preview_clips_summary'),
                        textAlign: TextAlign.center,
                        style: sora(size: 12.5, weight: FontWeight.w600, color: NowaColors.text),
                      ),
                    ),
                  )
                else if (_ready)
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: NowaColors.accent,
                    ),
                  ),
                if (widget.collectDetails) ...[
                  const SizedBox(height: 16),
                  NowaButton(
                    key: const Key('preview_continue_button'),
                    label: 'Continue',
                    onTap: _ready ? _continue : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedPicker extends StatelessWidget {
  const _SpeedPicker({required this.speed, required this.onChanged});

  final double speed;
  final ValueChanged<double> onChanged;

  static String _label(double speed) =>
      speed == speed.roundToDouble() ? '${speed.round()}x' : '${speed}x';

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final option in editorSpeeds) ...[
              if (option != editorSpeeds.first) const SizedBox(width: 6),
              Chip2(
                key: Key('edit_speed_$option'),
                label: _label(option),
                active: option == speed,
                expand: true,
                onTap: () => onChanged(option),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrimBar extends StatelessWidget {
  const _TrimBar({
    required this.duration,
    required this.start,
    required this.end,
    required this.played,
    required this.onChanged,
  });

  final Duration duration;
  final Duration start;
  final Duration end;

  /// How long the posted video will play, speed included.
  final Duration played;
  final ValueChanged<RangeValues> onChanged;

  static String _clock(Duration d) {
    final tenths = (d.inMilliseconds / 100).round();
    final minutes = tenths ~/ 600;
    final seconds = (tenths % 600) / 10;
    return '$minutes:${seconds.toStringAsFixed(1).padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final max = duration.inMilliseconds.toDouble();
    return Glass(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(_clock(start), style: sora(size: 11.5, color: NowaColors.dim)),
                const Spacer(),
                Text(
                  _clock(played),
                  key: const Key('edit_played_duration'),
                  style: sora(size: 12.5, weight: FontWeight.w600, color: NowaColors.text),
                ),
                const Spacer(),
                Text(_clock(end), style: sora(size: 11.5, color: NowaColors.dim)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: NowaColors.accent,
                inactiveTrackColor: NowaColors.hairline,
                thumbColor: NowaColors.text,
                overlayColor: NowaColors.accent.withValues(alpha: 0.2),
                rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: RangeSlider(
                key: const Key('edit_trim_slider'),
                min: 0,
                max: max <= 0 ? 1 : max,
                values: RangeValues(
                  start.inMilliseconds.toDouble().clamp(0, max),
                  end.inMilliseconds.toDouble().clamp(0, max),
                ),
                onChanged: max <= _minClip.inMilliseconds ? null : onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
