import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';

/// Full-screen player opened from a grid (profile, search results). Behaves
/// like the feed — vertical PageView over the same list — but starts on the
/// tapped clip and can be dismissed back to the grid.
class VideoViewerScreen extends StatefulWidget {
  const VideoViewerScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  final List<VideoModel> videos;
  final int initialIndex;

  /// Pushes the viewer with a plain [MaterialPageRoute]: the list is already in
  /// memory at the call site, so there is nothing for a route to refetch.
  static Future<void> open(
    BuildContext context, {
    required List<VideoModel> videos,
    required int initialIndex,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoViewerScreen(
          videos: videos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _activeIndex = widget.initialIndex;

  // Save only: like goes through interaction-service inside the panel.
  final _saved = <String>{};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NowaColors.bg,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            onPageChanged: (index) => setState(() => _activeIndex = index),
            itemBuilder: (context, index) {
              final video = widget.videos[index];
              return FeedVideoPanel(
                key: Key('viewer_panel_${video.id}'),
                video: video,
                isActive: index == _activeIndex,
                saved: _saved.contains(video.id),
                onSave: () => setState(() => _saved.contains(video.id)
                    ? _saved.remove(video.id)
                    : _saved.add(video.id)),
              );
            },
          ),
          Positioned(
            left: 8,
            top: MediaQuery.of(context).padding.top + 6,
            child: IconButton(
              key: const Key('viewer_back_button'),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
