import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.url,
    required this.isActive,
    this.paused = false,
    this.placeholderLabel,
    this.controllerSink,
    this.onWatchEnd,
  });

  final String url;
  final bool isActive;

  /// Tap-to-pause from the panel above. Playback needs [isActive] *and*
  /// `!paused`: leaving the tab or scrolling away always stops the clip,
  /// whatever the tap state.
  final bool paused;

  /// Shown on the striped frame while the first frame is still loading, so a
  /// slow clip looks like the design mock rather than a black rectangle.
  final String? placeholderLabel;

  /// Handed the controller once it is ready, so the panel can draw the seek
  /// bar somewhere else in its layout (above the action rail) while playback
  /// stays owned here.
  final ValueNotifier<VideoPlayerController?>? controllerSink;

  /// Called once per watch session with the time actually played and the
  /// length the player saw — the two numbers `POST /watch` wants. Fires when
  /// the clip scrolls out of view and on dispose, never on a progress tick:
  /// one session is one row, and ticking would describe the same session over
  /// and over (interaction doc 3.9).
  final void Function(Duration watched, Duration duration)? onWatchEnd;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  /// Watch time is measured on the wall clock while the player reports itself
  /// playing, not from `position`: a looping clip rewinds its position, and
  /// what the server is being told is how long this person actually watched —
  /// three loops of a 15s clip is 45s, not 15s.
  Duration _watched = Duration.zero;
  DateTime? _playingSince;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true)
      ..addListener(_onPlaybackChanged)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        widget.controllerSink?.value = _controller;
        _syncPlayback();
      }).catchError((_) {
        // Swallow initialization errors (e.g. no platform implementation in
        // widget tests, network failures) so the widget just keeps showing
        // its loading state instead of crashing.
      });
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.paused != widget.paused) {
      _syncPlayback();
    }
    // Scrolling away ends the session. Tapping pause does not: the viewer is
    // still on this clip and will likely resume it.
    if (oldWidget.isActive && !widget.isActive) _flushWatch();
  }

  void _onPlaybackChanged() {
    final playing = _controller.value.isPlaying;
    if (playing && _playingSince == null) {
      _playingSince = DateTime.now();
    } else if (!playing) {
      _bankPlayingStretch();
    }
  }

  /// Closes the stretch that is open right now, if any, and adds it to the
  /// total. Buffering counts as not playing, so a stall does not inflate it.
  void _bankPlayingStretch() {
    final since = _playingSince;
    if (since == null) return;
    _watched += DateTime.now().difference(since);
    _playingSince = null;
  }

  /// Ends the session and starts a fresh one. Coming back to the same clip is
  /// a second session by design — a re-watch is the strongest signal the
  /// recommendation feed gets.
  void _flushWatch() {
    _bankPlayingStretch();
    final watched = _watched;
    _watched = Duration.zero;
    final duration = _controller.value.duration;
    if (watched == Duration.zero || duration == Duration.zero) return;
    widget.onWatchEnd?.call(watched, duration);
  }

  void _syncPlayback() {
    if (!_initialized) return;
    if (widget.isActive && !widget.paused) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    // ponytail: an app sent to background keeps its open stretch until the
    // widget is disposed, so that session is reported long. Add an
    // AppLifecycleListener here if the training data proves it matters.
    _flushWatch();
    _controller.removeListener(_onPlaybackChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          StripedPlaceholder(label: widget.placeholderLabel, fontSize: 12),
          const LoadingView(),
        ],
      );
    }
    // The feed is edge-to-edge: fill the panel and crop, rather than
    // letterboxing a portrait clip inside a black frame.
    final size = _controller.value.size;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

/// Seek bar with elapsed on the left and remaining on the right. The fill runs
/// left to right; the knob only appears while paused or dragging, so a playing
/// clip keeps the thinnest possible chrome.
class FeedSeekBar extends StatefulWidget {
  const FeedSeekBar({
    super.key,
    required this.controller,
    this.showKnob = false,
  });

  final VideoPlayerController controller;

  /// Set while the clip is paused — dragging turns it on by itself.
  final bool showKnob;

  @override
  State<FeedSeekBar> createState() => _FeedSeekBarState();
}

class _FeedSeekBarState extends State<FeedSeekBar> {
  bool _dragging = false;
  double _dragFraction = 0;

  /// A platform seek is in flight. Drag updates only move the bar while this
  /// is set — firing one seek per drag frame floods the decoder and stutters.
  bool _seeking = false;

  /// Held from drag end until the controller's own position catches up, so the
  /// bar does not snap back to the pre-seek position for a frame or two.
  double? _pendingFraction;

  /// Moves the bar immediately; the platform seek is throttled to one in
  /// flight at a time so a fast drag stays smooth.
  void _dragTo(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    setState(() => _dragFraction = clamped);
    if (_seeking) return;
    _seek(clamped);
  }

  Future<void> _seek(double fraction) async {
    final total = widget.controller.value.duration;
    if (total == Duration.zero) return;
    _seeking = true;
    try {
      await widget.controller.seekTo(total * fraction);
    } finally {
      _seeking = false;
    }
  }

  /// Final seek: keep showing the dragged position until the controller
  /// reports it, then hand the bar back to playback.
  Future<void> _commitDrag() async {
    final target = _dragFraction;
    setState(() {
      _dragging = false;
      _pendingFraction = target;
    });
    await _seek(target);
    if (!mounted) return;
    setState(() => _pendingFraction = null);
  }

  Future<void> _tapTo(double fraction) async {
    final clamped = fraction.clamp(0.0, 1.0);
    setState(() => _pendingFraction = clamped);
    await _seek(clamped);
    if (!mounted) return;
    setState(() => _pendingFraction = null);
  }

  String _clock(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final total = value.duration;
        final played = total == Duration.zero
            ? 0.0
            : value.position.inMilliseconds / total.inMilliseconds;
        final fraction =
            (_dragging ? _dragFraction : _pendingFraction ?? played)
                .clamp(0.0, 1.0);
        final elapsed = total * fraction;
        final knob = _dragging || widget.showKnob;
        final labelStyle = sora(
          size: 11,
          weight: FontWeight.w500,
          color: NowaColors.text.withValues(alpha: 0.72),
        );

        return Row(
          children: [
            Text(_clock(elapsed), style: labelStyle),
            const SizedBox(width: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (d) {
                      setState(() => _dragging = true);
                      _dragTo(d.localPosition.dx / width);
                    },
                    onHorizontalDragUpdate: (d) =>
                        _dragTo(d.localPosition.dx / width),
                    onHorizontalDragEnd: (_) => _commitDrag(),
                    onHorizontalDragCancel: () => _commitDrag(),
                    onTapDown: (d) => _tapTo(d.localPosition.dx / width),
                    child: SizedBox(
                      // Generous hit area around a hairline bar.
                      height: 22,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Track.
                          Container(
                            height: _dragging ? 5 : 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Fill: measured off the track width so it always
                          // grows from the left edge.
                          Container(
                            height: _dragging ? 5 : 3,
                            width: width * fraction,
                            decoration: BoxDecoration(
                              color: _dragging
                                  ? Colors.white
                                  : NowaColors.accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          if (knob)
                            Positioned(
                              // Keep the whole dot on the bar at both ends.
                              left: (width * fraction - 6).clamp(0.0, width - 12),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(_clock(total - elapsed), style: labelStyle),
          ],
        );
      },
    );
  }
}
