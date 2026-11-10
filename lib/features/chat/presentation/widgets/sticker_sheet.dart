import 'dart:async';

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

/// The server's own pack plus GIPHY (through chat-service, which keeps the
/// key). A blank search shows the pack and GIPHY's trending stickers.
class _StickerSheet extends ConsumerStatefulWidget {
  const _StickerSheet();

  @override
  ConsumerState<_StickerSheet> createState() => _StickerSheetState();
}

class _StickerSheetState extends ConsumerState<_StickerSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  // GIPHY's free key allows 100 calls an hour, so wait for typing to stop.
  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    // The pack is optional: when it fails or is empty, GIPHY alone fills it.
    final pack = _query.isEmpty
        ? <StickerModel>[
            for (final p
                in ref.watch(stickerPacksProvider).valueOrNull ??
                    const <StickerPack>[])
              ...p.stickers,
          ]
        : const <StickerModel>[];
    final giphy = ref.watch(giphyStickersProvider(_query));
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.42,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: TextField(
                key: const Key('sticker_search'),
                controller: _search,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                style: work(size: 14),
                decoration: const InputDecoration(
                  hintText: 'Search GIPHY',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: giphy.when(
                loading: () => pack.isEmpty
                    ? const LoadingView()
                    : _StickerGrid(stickers: pack),
                error: (error, _) => pack.isEmpty
                    ? ErrorView(
                        message: error.toString(),
                        onRetry: () =>
                            ref.invalidate(giphyStickersProvider(_query)),
                      )
                    : _StickerGrid(stickers: pack),
                data: (found) {
                  final stickers = [...pack, ...found];
                  if (stickers.isEmpty) {
                    return Center(
                      child: Text('No stickers found', style: work(size: 13)),
                    );
                  }
                  return _StickerGrid(stickers: stickers);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickerGrid extends StatelessWidget {
  const _StickerGrid({required this.stickers});

  final List<StickerModel> stickers;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        child: Text(
          sticker.name,
          textAlign: TextAlign.center,
          style: work(size: 11),
        ),
      ),
    );
  }
}
