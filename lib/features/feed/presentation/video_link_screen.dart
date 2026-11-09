import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_sheet.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';

/// One video, opened by id — from a notification about a comment on it.
/// With [openComments] the comment sheet opens over it once the video has
/// loaded.
class VideoLinkScreen extends ConsumerStatefulWidget {
  const VideoLinkScreen({
    super.key,
    required this.videoId,
    this.openComments = false,
  });

  final String videoId;
  final bool openComments;

  @override
  ConsumerState<VideoLinkScreen> createState() => _VideoLinkScreenState();
}

class _VideoLinkScreenState extends ConsumerState<VideoLinkScreen> {
  /// Once only: closing the sheet must not bring it back on the next build.
  bool _commentsShown = false;

  void _showCommentsOnce(VideoModel video) {
    if (!widget.openComments || _commentsShown) return;
    _commentsShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCommentSheet(
        context,
        videoId: video.id,
        videoOwnerId: video.userId,
        totalCount: video.commentCount,
        commentsDisabled: video.commentsDisabled,
      );
    });
  }

  /// `VIDEO_NOT_FOUND` covers deleted, private and taken-down alike — the
  /// server will not say which (video doc 3).
  static String _messageFor(Object error) {
    if (error is ServerException && error.code == 'VIDEO_NOT_FOUND') {
      return "This video isn't available anymore";
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(videoByIdProvider(widget.videoId));
    return Scaffold(
      backgroundColor: NowaColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: video.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                key: const Key('video_link_error'),
                message: _messageFor(error),
                onRetry:
                    error is ServerException && error.code == 'VIDEO_NOT_FOUND'
                    ? null
                    : () => ref.invalidate(videoByIdProvider(widget.videoId)),
              ),
              data: (video) {
                _showCommentsOnce(video);
                return FeedVideoPanel(
                  key: Key('video_link_panel_${video.id}'),
                  video: video,
                  isActive: true,
                  onDeleted: () => Navigator.of(context).maybePop(),
                );
              },
            ),
          ),
          Positioned(
            left: 8,
            top: MediaQuery.of(context).padding.top + 6,
            child: IconButton(
              key: const Key('video_link_back_button'),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}
