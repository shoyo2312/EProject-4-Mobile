import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/media_url.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';

/// Opens the sticker picker over the comment sheet and answers the sticker
/// tapped, or null. Same catalog as chat.
Future<StickerModel?> showCommentStickerSheet(BuildContext context) {
  return showModalBottomSheet<StickerModel>(
    context: context,
    backgroundColor: NowaColors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _CommentStickerSheet(),
  );
}

class _CommentStickerSheet extends ConsumerWidget {
  const _CommentStickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(commentStickerPacksProvider);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.42,
        child: packs.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(commentStickerPacksProvider),
          ),
          data: (packs) {
            final stickers = [for (final p in packs) ...p.stickers];
            if (stickers.isEmpty) {
              return Center(
                child: Text('No stickers yet', style: work(size: 13)),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: stickers.length,
              itemBuilder: (context, i) {
                final sticker = stickers[i];
                return GestureDetector(
                  key: Key('comment_sticker_${sticker.stickerId}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(sticker),
                  child: Semantics(
                    label: sticker.name,
                    button: true,
                    child: CachedNetworkImage(
                      imageUrl: reachableFromDevice(sticker.url),
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const SizedBox.shrink(),
                      errorWidget: (_, _, _) => Center(
                        child: Text(
                          sticker.name,
                          textAlign: TextAlign.center,
                          style: work(size: 11),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
