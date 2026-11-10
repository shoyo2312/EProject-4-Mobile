import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/create/data/music_track.dart';
import 'package:tiktok_mobile/features/create/presentation/music_provider.dart';
import 'package:tiktok_mobile/core/utils/player_audio.dart';
import 'package:video_player/video_player.dart';

/// The sound picker: the most popular songs, or a search, each with a preview
/// to listen to first. Resolves to the song picked, or null.
Future<MusicTrack?> showMusicPicker(BuildContext context) {
  return showModalBottomSheet<MusicTrack>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NowaColors.surface,
    showDragHandle: true,
    builder: (_) => const _MusicPicker(),
  );
}

String musicClock(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

class _MusicPicker extends ConsumerStatefulWidget {
  const _MusicPicker();

  @override
  ConsumerState<_MusicPicker> createState() => _MusicPickerState();
}

class _MusicPickerState extends ConsumerState<_MusicPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  var _query = '';

  /// One song plays at a time; picking another or closing the sheet stops it.
  VideoPlayerController? _preview;
  String? _previewId;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _preview?.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  Future<void> _togglePreview(MusicTrack track) async {
    final playing = _previewId == track.id;
    final old = _preview;
    setState(() {
      _preview = null;
      _previewId = playing ? null : track.id;
    });
    await old?.dispose();
    if (playing) return;
    final player = VideoPlayerController.networkUrl(
      Uri.parse(track.audioUrl),
      videoPlayerOptions: ownsAudio(),
    );
    try {
      await player.initialize();
    } catch (_) {
      await player.dispose();
      if (mounted && _previewId == track.id) setState(() => _previewId = null);
      return;
    }
    // Another song may have been tapped while this one loaded.
    if (!mounted || _previewId != track.id) {
      await player.dispose();
      return;
    }
    setState(() => _preview = player);
    await player.play();
  }

  static String _message(Object error) {
    if (error is ServerException && error.code == 'MUSIC_UNAVAILABLE') {
      return "Music isn't available right now";
    }
    return error is AppException ? error.message : 'Could not load sounds';
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(musicSearchProvider(_query));
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('music_search_field'),
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              style: sora(size: 14, color: NowaColors.text),
              decoration: InputDecoration(
                hintText: 'Search sounds',
                hintStyle: sora(size: 14, color: NowaColors.dim),
                prefixIcon: const Icon(Icons.search, color: NowaColors.dim),
                filled: true,
                fillColor: NowaColors.surfaceHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: _message(error),
                onRetry: () => ref.invalidate(musicSearchProvider(_query)),
              ),
              data: (tracks) => tracks.isEmpty
                  ? Center(child: Text('No sounds found', style: sora(size: 13, color: NowaColors.dim)))
                  : ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (context, i) => _TrackRow(
                        track: tracks[i],
                        playing: _previewId == tracks[i].id,
                        onPreview: () => _togglePreview(tracks[i]),
                        onUse: () => Navigator.of(context).pop(tracks[i]),
                      ),
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Music from Jamendo · Creative Commons',
                style: sora(size: 10.5, color: NowaColors.dim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.playing,
    required this.onPreview,
    required this.onUse,
  });

  final MusicTrack track;
  final bool playing;
  final VoidCallback onPreview;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final image = track.imageUrl;
    return ListTile(
      key: Key('music_track_${track.id}'),
      onTap: onPreview,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null && image.isNotEmpty)
                CachedNetworkImage(imageUrl: image, fit: BoxFit.cover, memCacheWidth: 120)
              else
                const ColoredBox(color: NowaColors.surfaceHigh),
              ColoredBox(
                color: Colors.black38,
                child: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: sora(size: 13.5, weight: FontWeight.w600, color: NowaColors.text),
      ),
      subtitle: Text(
        '${track.artist} · ${musicClock(track.durationSeconds)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: sora(size: 11.5, color: NowaColors.dim),
      ),
      trailing: TextButton(
        key: Key('music_use_${track.id}'),
        onPressed: onUse,
        child: Text('Use', style: sora(size: 13, weight: FontWeight.w700, color: NowaColors.accent)),
      ),
    );
  }
}
