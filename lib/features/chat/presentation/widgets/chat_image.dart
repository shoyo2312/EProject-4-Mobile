import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';

/// The size a picture takes in a thread: its own shape, at most [maxWidth]
/// wide and a little taller than square, so a tall photo does not fill the
/// screen. Known before the bytes arrive, so the list does not jump.
Size chatImageBox(int width, int height, double maxWidth) {
  if (width <= 0 || height <= 0) return Size(maxWidth, maxWidth);
  final maxHeight = maxWidth * 1.3;
  final scale = [maxWidth / width, maxHeight / height, 1.0]
      .reduce((a, b) => a < b ? a : b);
  final w = (width * scale).clamp(80.0, maxWidth);
  final h = (height * scale).clamp(80.0, maxHeight);
  return Size(w, h);
}

/// A picture someone sent. Its bytes need the viewer's token, so they come
/// through [chatImageBytesProvider] rather than a URL; tapping opens it full
/// screen.
class ChatImage extends ConsumerWidget {
  const ChatImage({super.key, required this.image, required this.maxWidth});

  final ChatImageModel image;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = chatImageBox(image.width, image.height, maxWidth);
    final bytes = ref.watch(chatImageBytesProvider(image));
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: box.width,
        height: box.height,
        child: bytes.when(
          loading: () => const ColoredBox(color: NowaColors.surfaceHigh),
          error: (_, _) => GestureDetector(
            onTap: () => ref.invalidate(chatImageBytesProvider(image)),
            child: ColoredBox(
              color: NowaColors.surfaceHigh,
              child: Center(
                child: Icon(
                  Icons.refresh,
                  color: NowaColors.text.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          data: (data) => GestureDetector(
            key: Key('chat_image_${image.imageId}'),
            onTap: () => openPhotoViewer(context, data),
            child: Image.memory(data, fit: BoxFit.cover, gaplessPlayback: true),
          ),
        ),
      ),
    );
  }
}

/// Full screen, pinch to zoom, tap or swipe the close button to leave.
void openPhotoViewer(BuildContext context, Uint8List bytes) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            maxScale: 5,
            child: Image.memory(bytes),
          ),
        ),
      ),
    ),
  );
}
