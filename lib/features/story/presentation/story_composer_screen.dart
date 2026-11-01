import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/story/data/story_model.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:video_player/video_player.dart';

/// story-service's caption limit.
const storyCaptionMaxLength = 300;

/// Preview, caption, audience, share. Pops `true` once the story exists —
/// it is then waiting for moderation, and live for 24h once approved.
class StoryComposerScreen extends ConsumerStatefulWidget {
  const StoryComposerScreen({super.key, required this.draft});

  final StoryDraft draft;

  @override
  ConsumerState<StoryComposerScreen> createState() =>
      _StoryComposerScreenState();
}

class _StoryComposerScreenState extends ConsumerState<StoryComposerScreen> {
  final _caption = TextEditingController();
  var _visibility = StoryVisibility.public;
  VideoPlayerController? _video;

  /// Set when Share is tapped, so the listener only reacts to this screen's
  /// own upload and not one left over from before.
  var _submitted = false;

  /// Known once the clip has loaded. A clip over 60s would be REJECTED after
  /// the whole upload, so it is refused here instead.
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    if (widget.draft.isVideo) {
      final controller = _video = VideoPlayerController.file(widget.draft.file);
      controller
        ..setLooping(true)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _duration = controller.value.duration);
          controller.play();
        }).catchError((_) {
          // No platform player (tests) or an unreadable file: the preview
          // stays blank and the server still has the last word on it.
        });
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    _video?.dispose();
    super.dispose();
  }

  bool get _tooLong =>
      _duration != null && _duration! > storyVideoMaxDuration + _slack;

  /// Containers round their duration up; a 60.4s clip is a 60s clip.
  static const _slack = Duration(milliseconds: 900);

  void _share() {
    if (_tooLong) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    final caption = _caption.text.trim();
    unawaited(ref.read(storyUploadProvider.notifier).start(
          draft: widget.draft,
          caption: caption.isEmpty ? null : caption,
          visibility: _visibility,
        ));
  }

  void _onUpload(StoryUploadState state) {
    if (!_submitted || !mounted) return;
    if (state.phase == StoryUploadPhase.done) {
      context.pop(true);
    } else if (state.phase == StoryUploadPhase.failed) {
      setState(() => _submitted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(storyUploadProvider, (_, next) => _onUpload(next));
    final upload = ref.watch(storyUploadProvider);
    final busy = _submitted && upload.busy;
    final top = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _Preview(draft: widget.draft, video: _video),
            // Keeps the controls readable over a bright photo.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xCC000000),
                    ],
                    stops: [0, 0.2, 0.55, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: top + 8,
              child: GestureDetector(
                key: const Key('story_composer_close'),
                onTap: busy ? null : () => context.pop(),
                child: Glass(
                  radius: 12,
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: IgnorePointer(
                ignoring: busy,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_tooLong)
                      _Notice(
                        text: 'Stories can be at most 60 seconds — this one '
                            'is ${_duration!.inSeconds}s. Trim it and try again.',
                        color: NowaColors.danger,
                      ),
                    if (upload.phase == StoryUploadPhase.failed &&
                        upload.error != null)
                      _Notice(
                        key: const Key('story_composer_error'),
                        text: upload.error!,
                        color: NowaColors.danger,
                      ),
                    Glass(
                      radius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        key: const Key('story_caption_field'),
                        controller: _caption,
                        maxLength: storyCaptionMaxLength,
                        maxLines: 3,
                        minLines: 1,
                        style: work(size: 14),
                        cursorColor: NowaColors.accent,
                        decoration: InputDecoration(
                          hintText: 'Add a caption…',
                          hintStyle: work(size: 14, color: NowaColors.dim),
                          border: InputBorder.none,
                          counterStyle: work(size: 10, color: NowaColors.dim),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final (value, label) in const [
                          (StoryVisibility.public, 'Everyone'),
                          (StoryVisibility.friends, 'Friends'),
                          (StoryVisibility.private, 'Only me'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Chip2(
                              key: Key('story_visibility_${value.name}'),
                              label: label,
                              active: _visibility == value,
                              onTap: () => setState(() => _visibility = value),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (busy) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          key: const Key('story_upload_progress'),
                          value: upload.progress < 0 ? null : upload.progress,
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          color: NowaColors.accent,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    NowaButton(
                      key: const Key('story_share_button'),
                      label: switch (upload.phase) {
                        _ when !busy => 'Share to story',
                        StoryUploadPhase.uploading => upload.progress < 0
                            ? 'Uploading…'
                            : 'Uploading · ${(upload.progress * 100).round()}%',
                        _ => 'Posting…',
                      },
                      icon: Icons.auto_awesome,
                      loading: busy,
                      onTap: _tooLong ? null : _share,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.draft, required this.video});

  final StoryDraft draft;
  final VideoPlayerController? video;

  @override
  Widget build(BuildContext context) {
    final controller = video;
    if (!draft.isVideo) {
      return Image.file(draft.file, key: const Key('story_preview_image'),
          fit: BoxFit.contain);
    }
    if (controller == null) return const SizedBox.shrink();
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: NowaColors.accent),
          );
        }
        return Center(
          child: AspectRatio(
            aspectRatio: value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(text, style: work(size: 12.5, color: color)),
      ),
    );
  }
}
