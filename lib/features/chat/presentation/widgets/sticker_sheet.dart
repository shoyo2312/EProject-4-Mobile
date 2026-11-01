import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/media_url.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/chat/data/chat_model.dart';
import 'package:tiktok_mobile/features/chat/presentation/chat_provider.dart';

/// Opens the sticker picker and answers the sticker tapped, or null.
Future<StickerModel?> showStickerSheet(BuildContext context) {
  return showModalBottomSheet<StickerModel>(
    context: context,
    backgroundColor: NowaColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _StickerSheet(),
  );
}

class _StickerSheet extends ConsumerWidget {
  const _StickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(stickerPacksProvider);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.42,
        child: packs.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(stickerPacksProvider),
          ),
          data: (packs) {
            final stickers = [for (final p in packs) ...p.stickers];
            if (stickers.isEmpty) {
              return Center(
                child: Text('No stickers yet', style: work(size: 13)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text(
                    packs.length == 1 ? packs.single.name : 'Stickers',
                    style: sora(size: 14),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: stickers.length,
                    itemBuilder: (context, i) {
                      final sticker = stickers[i];
                      return GestureDetector(
                        key: Key('sticker_${sticker.stickerId}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(sticker),
                        child: Semantics(
                          label: sticker.name,
                          button: true,
                          child: StickerImage(sticker: sticker),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A sticker as drawn in the picker and in a thread. Its URL is public and
/// stable, so the disk cache keeps it across sessions.
class StickerImage extends StatelessWidget {
  const StickerImage({super.key, required this.sticker, this.size});

  final StickerModel sticker;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: reachableFromDevice(sticker.url),
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => Center(
        child: Text(sticker.name, textAlign: TextAlign.center, style: work(size: 11)),
      ),
    );
  }
}
