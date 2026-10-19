import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/create/presentation/post_details_screen.dart';
import 'package:video_player/video_player.dart';

/// Step 2 of the create flow: watch back what was just picked or recorded
/// before committing to it. Resolves `true` once the post is up, `null` if the
/// poster backed out of either step.
Future<bool?> showVideoPreview(BuildContext context, {required File file}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => VideoPreviewScreen(file: file)),
  );
}

/// Reopens the same player from the details screen, purely to watch the clip
/// again — no Continue button, back is the only way out.
Future<void> showVideoReview(BuildContext context, {required File file}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => VideoPreviewScreen(file: file, collectDetails: false),
    ),
  );
}

/// Plays the local file — not [VideoPlayerWidget], which is network-only and
/// reports watch time to interaction-service. Nothing here is a watch.
class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.file,
    this.collectDetails = true,
  });

  final File file;

  /// False when the details screen reopens this to re-watch the clip: the
  /// details are already being filled in one route below.
  final bool collectDetails;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late final VideoPlayerController _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Playback is paused across the details screen: the clip looping under a
  /// keyboard is only noise, and its audio would keep running.
  Future<void> _continue() async {
    await _controller.pause();
    if (!mounted) return;
    final posted = await showPostDetails(context, file: widget.file);
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
              children: [
                if (_ready)
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
