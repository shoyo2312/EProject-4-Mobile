import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';

/// Where a story's photo or clip comes from.
enum StoryMediaSource { gallery, photo, video }

/// Photos are re-encoded by the picker: HEIC from an iPhone becomes JPEG
/// (story-service does not take HEIC), and a 48MP shot shrinks well under the
/// 10 MB limit without visibly losing anything on a phone screen.
const _maxImageSide = 2160.0;
const _imageQuality = 90;

/// Asks which source, then opens it. Null when the poster backed out.
Future<StoryDraft?> pickStoryDraft(
  BuildContext context, {
  ImagePicker? picker,
}) async {
  final source = await showModalBottomSheet<StoryMediaSource>(
    context: context,
    backgroundColor: NowaColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => const _SourceSheet(),
  );
  if (source == null || !context.mounted) return null;
  return pickStoryDraftFrom(context, source, picker: picker);
}

/// Opens [source] and checks the result against story-service's limits, so a
/// file it would refuse is turned away before the upload, with a reason.
Future<StoryDraft?> pickStoryDraftFrom(
  BuildContext context,
  StoryMediaSource source, {
  ImagePicker? picker,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final imagePicker = picker ?? ImagePicker();

  final XFile? picked;
  try {
    picked = switch (source) {
      StoryMediaSource.gallery => await imagePicker.pickMedia(
          maxWidth: _maxImageSide,
          maxHeight: _maxImageSide,
          imageQuality: _imageQuality,
        ),
      StoryMediaSource.photo => await imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: _maxImageSide,
          maxHeight: _maxImageSide,
          imageQuality: _imageQuality,
        ),
      StoryMediaSource.video => await imagePicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: storyVideoMaxDuration,
        ),
    };
  } on PlatformException catch (e) {
    // A refused camera/library permission arrives as an exception.
    messenger.showSnackBar(
      SnackBar(content: Text(e.message ?? 'Could not open the camera')),
    );
    return null;
  }
  if (picked == null) return null;

  final file = File(picked.path);
  final contentType = storyContentTypeForPath(picked.path) ??
      _fromMime(picked.mimeType);
  if (contentType == null) {
    messenger.showSnackBar(const SnackBar(
      content: Text(
        'Only JPEG, PNG, WebP photos and MP4, WebM videos can be posted',
      ),
    ));
    return null;
  }

  final size = await file.length();
  final isVideo = isVideoContentType(contentType);
  final limit = isVideo ? storyVideoMaxBytes : storyImageMaxBytes;
  if (size > limit) {
    messenger.showSnackBar(SnackBar(
      content: Text(isVideo
          ? 'Videos can be at most 50 MB'
          : 'Photos can be at most 10 MB'),
    ));
    return null;
  }
  return StoryDraft(file: file, contentType: contentType);
}

/// Some pickers hand back a path without a useful extension (Android content
/// URIs copied to cache); the MIME type is the fallback.
String? _fromMime(String? mime) => switch (mime) {
      'image/jpeg' || 'image/png' || 'image/webp' => mime,
      'video/mp4' || 'video/webm' => mime,
      _ => null,
    };

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    Widget option(StoryMediaSource source, IconData icon, String label,
            String hint) =>
        ListTile(
          key: Key('story_source_${source.name}'),
          leading: Icon(icon, color: NowaColors.text),
          title: Text(label, style: sora(size: 14)),
          subtitle: Text(hint, style: work(size: 12, color: NowaColors.dim)),
          onTap: () => Navigator.of(context).pop(source),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New story', style: sora(size: 15)),
            const SizedBox(height: 4),
            Text(
              'Disappears 24 hours after it is approved',
              style: work(size: 12, color: NowaColors.dim),
            ),
            const SizedBox(height: 8),
            option(StoryMediaSource.gallery, Icons.photo_library_outlined,
                'Choose from gallery', 'A photo, or a video up to 60s'),
            option(StoryMediaSource.photo, Icons.photo_camera_outlined,
                'Take a photo', 'Opens the camera'),
            option(StoryMediaSource.video, Icons.videocam_outlined,
                'Record a video', 'Up to 60 seconds'),
          ],
        ),
      ),
    );
  }
}
