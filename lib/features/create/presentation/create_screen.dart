import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/create/presentation/post_sheet.dart';
import 'package:tiktok_mobile/features/create/presentation/upload_provider.dart';

/// The camera screen from the design, wired to video-service's three-step
/// publish: ticket, PUT to storage, create the record (video doc 3.1/3.2).
///
/// There is no in-app capture pipeline; the shutter and the gallery tile both
/// hand off to the system picker, which is what actually records or browses.
/// The overlay controls (flip, speed, filter, timer, clip length) stay
/// presentational — they belong to a capture pipeline that does not exist.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key, required this.onClose, this.picker});

  final VoidCallback onClose;

  /// Injected in tests; the real screen opens the system picker.
  final ImagePicker? picker;

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  String _len = '60s';

  late final ImagePicker _picker = widget.picker ?? ImagePicker();

  /// Pick or record a clip, collect its title, then upload. Every failure
  /// after this point shows up in [uploadNotifierProvider], not here.
  Future<void> _pick(ImageSource source) async {
    if (ref.read(uploadNotifierProvider).busy) return;

    final XFile? picked;
    try {
      picked = await _picker.pickVideo(source: source);
    } on PlatformException catch (e) {
      // A refused camera/library permission arrives as an exception, not a
      // null file, and would otherwise take the whole screen down.
      if (mounted) _toast(e.message ?? 'The video could not be opened');
      return;
    }
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    final details = await showPostSheet(context, file: file);
    if (details == null || !mounted) return;

    await ref.read(uploadNotifierProvider.notifier).start(
          file: file,
          title: details.title,
          description: details.description,
          visibility: details.visibility,
          tags: details.tags,
        );
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: work(size: 12))),
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final upload = ref.watch(uploadNotifierProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        const StripedPlaceholder(label: 'camera preview', fontSize: 12),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99060508),
                Color(0x00060508),
                Color(0x00060508),
                Color(0xD9060508),
              ],
              stops: [0, 0.3, 0.6, 1],
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          top: top + 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                key: const Key('create_close_button'),
                onTap: () {
                  // A finished upload's banner should not still be there next
                  // time the tab is opened; one in flight keeps running.
                  if (!ref.read(uploadNotifierProvider).busy) {
                    ref.read(uploadNotifierProvider.notifier).reset();
                  }
                  widget.onClose();
                },
                child: Glass(
                  radius: 12,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
              Glass(
                radius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.audiotrack,
                        size: 14,
                        color: NowaColors.supportInk,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Add sound',
                        style: sora(size: 12.5, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        Positioned(
          left: 14,
          top: top + 70,
          child: Column(
            children: [
              for (final t in const [
                ['Flip', 'w'],
                ['Speed', 's'],
                ['Filter', 'g'],
                ['Timer', 'd'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Glass(
                    radius: 15,
                    opacity: 0.45,
                    child: SizedBox(
                      width: 52,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                gradient: t[1] == 'g'
                                    ? const LinearGradient(
                                        colors: [
                                          NowaColors.accent,
                                          NowaColors.support,
                                        ],
                                      )
                                    : null,
                                color: t[1] == 'g'
                                    ? null
                                    : t[1] == 's'
                                        ? NowaColors.supportInk
                                            .withValues(alpha: 0.9)
                                        : Colors.white.withValues(
                                            alpha: t[1] == 'w' ? 0.85 : 0.55,
                                          ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t[0],
                              style: sora(
                                size: 9.5,
                                weight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 44,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final l in ['15s', '60s', '3m'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _len = l),
                        child: Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: l == _len
                                ? NowaColors.accent.withValues(alpha: 0.9)
                                : const Color(0x73141218),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l,
                            style: sora(
                              size: 12,
                              weight: l == _len ? FontWeight.w600 : FontWeight.w500,
                              color: l == _len
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    key: const Key('create_gallery_button'),
                    onTap: () => _pick(ImageSource.gallery),
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(
                        Icons.video_library_outlined,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                  GestureDetector(
                    key: const Key('create_record_button'),
                    onTap: () => _pick(ImageSource.camera),
                    child: Container(
                      width: 82,
                      height: 82,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: upload.busy
                            ? NowaColors.accent.withValues(alpha: 0.35)
                            : NowaColors.accent,
                        boxShadow: [
                          BoxShadow(
                            color: NowaColors.accent.withValues(alpha: 0.25),
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: upload.busy ? 30 : 68,
                        height: upload.busy ? 30 : 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(upload.busy ? 9 : 34),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                  Glass(
                    radius: 23,
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(Icons.center_focus_weak, size: 19),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _UploadStatus(state: upload, clipLength: _len),
            ],
          ),
        ),
      ],
    );
  }
}

/// The one line under the shutter: what the upload is doing, or the hint when
/// nothing is in flight.
class _UploadStatus extends StatelessWidget {
  const _UploadStatus({required this.state, required this.clipLength});

  final UploadState state;
  final String clipLength;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (state.phase) {
      UploadPhase.uploading => (
          state.progress < 0
              ? 'Uploading…'
              : 'Uploading · ${(state.progress * 100).round()}%',
          NowaColors.accent,
        ),
      UploadPhase.publishing => ('Posting…', NowaColors.accent),
      // PROCESSING is not a wait the user has to sit through: the video is
      // saved, it just is not playable or on the feed until transcoding ends
      // (video doc 3.2).
      UploadPhase.processing => (
          'Processing — it will appear on your profile when ready',
          NowaColors.supportInk,
        ),
      UploadPhase.done => ('Posted', NowaColors.supportInk),
      UploadPhase.failed => (state.error ?? 'Upload failed', NowaColors.danger),
      UploadPhase.idle => (
          'Tap to record · $clipLength, or pick a clip from the gallery',
          Colors.white.withValues(alpha: 0.6),
        ),
    };

    return Column(
      children: [
        if (state.phase == UploadPhase.uploading)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 40, right: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                key: const Key('upload_progress'),
                value: state.progress < 0 ? null : state.progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                color: NowaColors.accent,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            text,
            key: const Key('upload_status_text'),
            textAlign: TextAlign.center,
            style: sora(size: 12, weight: FontWeight.w500, color: color),
          ),
        ),
      ],
    );
  }
}
