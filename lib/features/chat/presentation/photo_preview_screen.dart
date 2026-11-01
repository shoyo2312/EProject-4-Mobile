import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

/// What the person decided on the preview.
sealed class PhotoPreviewResult {
  const PhotoPreviewResult();
}

/// Send it, with [caption] (empty for none).
final class SendPhoto extends PhotoPreviewResult {
  const SendPhoto(this.caption);
  final String caption;
}

/// Back to the camera for another shot.
final class RetakePhoto extends PhotoPreviewResult {
  const RetakePhoto();
}

/// The picture full screen before it is sent: a caption, Send, and — for a
/// shot just taken — Retake. Answers null when closed without sending.
class PhotoPreviewScreen extends StatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.bytes,
    this.canRetake = false,
  });

  final Uint8List bytes;
  final bool canRetake;

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.canRetake)
            TextButton.icon(
              key: const Key('photo_preview_retake'),
              onPressed: () => Navigator.of(context).pop(const RetakePhoto()),
              icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
              label: Text('Retake', style: work(size: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.memory(widget.bytes),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('photo_preview_caption'),
                      controller: _caption,
                      minLines: 1,
                      maxLines: 3,
                      // The server's cap on a picture's caption.
                      maxLength: 1000,
                      style: work(size: 14, height: 1.3),
                      cursorColor: NowaColors.accent,
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'Add a caption',
                        hintStyle: work(
                          size: 14,
                          height: 1.3,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('photo_preview_send'),
                    style: IconButton.styleFrom(
                      backgroundColor: NowaColors.accent,
                    ),
                    onPressed: () => Navigator.of(context)
                        .pop(SendPhoto(_caption.text.trim())),
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
