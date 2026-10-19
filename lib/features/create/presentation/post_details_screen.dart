import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/create/presentation/upload_provider.dart';
import 'package:tiktok_mobile/features/create/presentation/video_preview_screen.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:video_player/video_player.dart';

/// Step 3 of the create flow (camera → preview → details). A full route rather
/// than a sheet: the keyboard plus three fields and the visibility picker do
/// not fit a bottom sheet without the sheet covering what is being typed.
///
/// Resolves `true` once the post is up — the caller's cue to leave the camera
/// and show the profile — and `null` if the poster backed out.
Future<bool?> showPostDetails(BuildContext context, {required File file}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => PostDetailsScreen(file: file)),
  );
}

class PostDetailsScreen extends ConsumerStatefulWidget {
  const PostDetailsScreen({super.key, required this.file});

  final File file;

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  var _visibility = VideoVisibility.public;

  /// Set when Post is tapped, so the phase listener only acts on this
  /// screen's own upload and not on one left over from an earlier post.
  var _submitted = false;

  /// Leaves only on DONE — the video is transcoded and actually on the profile
  /// grid by then. Stopping at PROCESSING would land the poster on a profile
  /// that does not show what they just posted yet.
  void _onPhase(UploadState state) {
    if (!_submitted || !mounted) return;
    if (state.phase == UploadPhase.done) {
      Navigator.of(context).pop(true);
    } else if (state.phase == UploadPhase.failed) {
      setState(() => _submitted = false);
    }
  }

  void _submit() {
    setState(() => _submitted = true);
    // Not awaited: start() only returns once transcoding has been polled to
    // an end, and this screen leaves as soon as the record exists.
    unawaited(ref.read(uploadNotifierProvider.notifier).start(
          file: widget.file,
          title: _title.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          visibility: _visibility,
          tags: _tagList,
        ));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  /// Splits on commas and spaces and drops the empties. The server lowercases,
  /// trims, strips a leading `#` and de-duplicates anyway (video doc 3.2), so
  /// nothing more is done here — normalising twice would only disagree.
  List<String> get _tagList => _tags.text
      .split(RegExp(r'[,\s]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .take(10)
      .toList();

  @override
  Widget build(BuildContext context) {
    ref.listen(uploadNotifierProvider, (_, next) => _onPhase(next));
    final upload = ref.watch(uploadNotifierProvider);
    final busy = _submitted && upload.busy;
    // Transcoding can outlast the poll schedule (~5 minutes), so the way out
    // stays open once the bytes are safely up — only the transfer itself is
    // uninterruptible.
    final locked = _submitted &&
        (upload.phase == UploadPhase.uploading ||
            upload.phase == UploadPhase.publishing);
    final title = _title.text.trim();
    return PopScope(
      // Leaving mid-upload would strand the poster with no progress anywhere;
      // the notifier is kept alive but nothing else shows it.
      canPop: !locked,
      child: Scaffold(
      backgroundColor: NowaColors.bg,
      appBar: AppBar(
        backgroundColor: NowaColors.bg,
        elevation: 0,
        leading: IconButton(
          key: const Key('post_back_button'),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: locked ? null : () => Navigator.of(context).pop(),
        ),
        title: Text('New post', style: sora(size: 16)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IgnorePointer(
                ignoring: busy,
                child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        key: const Key('post_thumbnail'),
                        onTap: () => showVideoReview(context, file: widget.file),
                        child: _VideoThumb(file: widget.file),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.file.uri.pathSegments.last,
                              style: work(size: 11, color: NowaColors.dim),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to watch it again',
                              style: work(size: 11, color: NowaColors.dim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Field(
                    key: const Key('post_title_field'),
                    controller: _title,
                    hint: 'Title',
                    maxLength: 150,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    key: const Key('post_description_field'),
                    controller: _description,
                    hint: 'Description (optional)',
                    maxLength: 2000,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    key: const Key('post_tags_field'),
                    controller: _tags,
                    hint: 'Tags, separated by spaces (max 10)',
                  ),
                  const SizedBox(height: 20),
                  Text('Who can watch', style: sora(size: 13)),
                  const SizedBox(height: 10),
                  for (final v in const [
                    (VideoVisibility.public, 'Public', 'Anyone on TikTok'),
                    (
                      VideoVisibility.friends,
                      'Friends',
                      'People who follow you back',
                    ),
                    (VideoVisibility.private, 'Private', 'Only you'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _VisibilityRow(
                        label: v.$2,
                        hint: v.$3,
                        selected: _visibility == v.$1,
                        onTap: () => setState(() => _visibility = v.$1),
                      ),
                    ),
                ],
              ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UploadProgress(state: upload, active: _submitted),
                  NowaButton(
                    key: const Key('post_submit_button'),
                    label: busy ? 'Posting…' : 'Post',
                    // A title of only whitespace is a 400 from the server, so
                    // the button stays off until there is one.
                    onTap: title.isEmpty || busy ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// The bar above the Post button: a real percentage while the bytes go up,
/// then an indeterminate line while the record is being created, then the
/// error if it failed.
class _UploadProgress extends StatelessWidget {
  const _UploadProgress({required this.state, required this.active});

  final UploadState state;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active && state.phase != UploadPhase.failed) {
      return const SizedBox.shrink();
    }
    final (label, color) = switch (state.phase) {
      UploadPhase.uploading => (
          state.progress < 0
              ? 'Uploading…'
              : 'Uploading · ${(state.progress * 100).round()}%',
          NowaColors.accent,
        ),
      UploadPhase.publishing => ('Posting…', NowaColors.accent),
      // No percentage to report here: media-worker does not stream progress,
      // the client only polls for the status flipping to PUBLISHED.
      UploadPhase.processing => ('Processing your video…', NowaColors.accent),
      UploadPhase.done => ('Posted', NowaColors.supportInk),
      UploadPhase.failed => (state.error ?? 'Upload failed', NowaColors.danger),
      UploadPhase.idle => ('Preparing…', NowaColors.accent),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          if (state.phase != UploadPhase.failed)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                key: const Key('post_upload_progress'),
                value: state.phase == UploadPhase.uploading && state.progress >= 0
                    ? state.progress
                    : null,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                color: NowaColors.accent,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            label,
            key: const Key('post_upload_status'),
            textAlign: TextAlign.center,
            style: sora(size: 12, weight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}

/// The clip's own first frame, held by a paused player. No thumbnailing
/// package for one still: video_player is already a dependency and decoding
/// frame zero is what it does on initialize.
class _VideoThumb extends StatefulWidget {
  const _VideoThumb({required this.file});

  final File file;

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  late final VideoPlayerController _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 54,
        height: 72,
        color: NowaColors.surfaceHigh,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            const Center(
              child: Icon(Icons.play_arrow, size: 20, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityRow extends StatelessWidget {
  const _VisibilityRow({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('post_visibility_${label.toLowerCase()}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: NowaColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? NowaColors.accent : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: sora(size: 13)),
                  const SizedBox(height: 2),
                  Text(hint, style: work(size: 11, color: NowaColors.dim)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? NowaColors.accent : NowaColors.dim,
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      onChanged: onChanged,
      style: work(size: 13),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: work(size: 13, color: NowaColors.dim),
        filled: true,
        fillColor: NowaColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
