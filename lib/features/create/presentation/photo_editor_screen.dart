import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/create/data/overlay_item.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/filter_picker.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/music_panel.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/music_picker.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/overlay_editor.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/overlay_painter.dart';
import 'package:video_player/video_player.dart';

/// What the photo editor made: the picture to upload and the recipe the
/// server renders over it.
class PhotoEditResult {
  const PhotoEditResult({
    required this.file,
    required this.contentType,
    required this.aspectRatio,
    this.edit,
    this.photoSeconds,
  });

  /// The picture as picked when nothing was changed; otherwise the picture
  /// redrawn upright as a PNG, so the server's pixels are the ones the layers
  /// were placed on.
  final File file;
  final String contentType;

  /// Width over height of [file] as shown.
  final double aspectRatio;

  /// Null when nothing was changed.
  final VideoEdit? edit;

  /// How long the story plays with its song; null without one.
  final double? photoSeconds;
}

typedef PhotoEditorNext = Future<bool?> Function(BuildContext context, PhotoEditResult result);

/// Opens the editor on a photo; resolves true once [onNext] says it was shared.
Future<bool?> showPhotoEditor(
  BuildContext context, {
  required File file,
  required String contentType,
  required PhotoEditorNext onNext,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PhotoEditorScreen(file: file, contentType: contentType, onNext: onNext),
    ),
  );
}

/// The lengths a photo with a song can play for, in seconds.
const photoLengths = [3.0, 6.0, 10.0, 15.0];

/// The editor's tools on a still picture: colour, text, stickers and a song.
/// No cutting or speed — there is no timeline — and the layers show
/// throughout. A song turns the photo into a short clip on the server, as long
/// as the length chosen here.
class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({
    super.key,
    required this.file,
    required this.contentType,
    required this.onNext,
    @visibleForTesting this.decoded,
    @visibleForTesting this.encodePng = uprightPng,
  });

  final File file;
  final String contentType;
  final PhotoEditorNext onNext;

  /// The picture already decoded, in place of decoding [file].
  final ui.Image? decoded;

  /// How the picture is redrawn for upload once anything is changed.
  final Future<List<int>> Function(ui.Image picture) encodePng;

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  /// The picture decoded upright, which is what is shown and, once anything
  /// is changed, what is uploaded.
  ui.Image? _picture;
  var _failed = false;

  EditFilter? _filter;
  var _items = <OverlayItem>[];
  var _nextItemId = 0;
  final _stickers = StickerImages();
  int? _selectedId;
  var _dragging = false;

  EditMusic? _music;
  VideoPlayerController? _musicPlayer;
  var _musicOpen = false;
  var _photoSeconds = 6.0;
  var _busy = false;

  OverlayItem? get _selected => _items.where((i) => i.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    final decoded = widget.decoded;
    if (decoded != null) {
      _picture = decoded.clone();
    } else {
      _decode();
    }
  }

  Future<void> _decode() async {
    try {
      final bytes = await widget.file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _picture = frame.image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _picture?.dispose();
    _musicPlayer?.removeListener(_loopMusic);
    _musicPlayer?.dispose();
    _stickers.dispose();
    super.dispose();
  }

  double get _aspectRatio {
    final picture = _picture;
    return picture == null ? 9 / 16 : picture.width / picture.height;
  }

  // ── Song ──────────────────────────────────────────────────────────────

  Future<void> _pickMusic() async {
    final track = await showMusicPicker(context);
    if (track == null || !mounted) return;
    final music = EditMusic(trackId: track.id, track: track, volume: _music?.volume ?? 1);
    setState(() {
      _music = music;
      _musicOpen = true;
      _selectedId = null;
    });
    await _loadMusic(music);
  }

  Future<void> _loadMusic(EditMusic music) async {
    final old = _musicPlayer;
    _musicPlayer = null;
    old?.removeListener(_loopMusic);
    await old?.dispose();
    final track = music.track;
    if (track == null) return;
    final player = VideoPlayerController.networkUrl(Uri.parse(track.audioUrl));
    try {
      await player.initialize();
    } catch (_) {
      // Preview only — the server fetches the song itself.
      await player.dispose();
      return;
    }
    if (!mounted || _music?.trackId != music.trackId) {
      await player.dispose();
      return;
    }
    _musicPlayer = player;
    await player.setVolume(music.volume);
    await player.seekTo(_seconds(music.start));
    player.addListener(_loopMusic);
    await player.play();
  }

  /// Plays the stretch of the song the story will have, over and over.
  void _loopMusic() {
    final player = _musicPlayer;
    final music = _music;
    if (player == null || music == null || !player.value.isInitialized) return;
    final end = _seconds(music.start + _photoSeconds);
    final position = player.value.position;
    if (position >= end || player.value.isCompleted) {
      player.seekTo(_seconds(music.start));
      if (!player.value.isPlaying) player.play();
    }
  }

  void _setMusic(EditMusic music, {bool seek = false}) {
    setState(() => _music = music);
    _musicPlayer?.setVolume(music.volume);
    if (seek) {
      _musicPlayer?.seekTo(_seconds(music.start));
      _musicPlayer?.play();
    }
  }

  Future<void> _removeMusic() async {
    setState(() {
      _music = null;
      _musicOpen = false;
    });
    final old = _musicPlayer;
    _musicPlayer = null;
    old?.removeListener(_loopMusic);
    await old?.dispose();
  }

  static Duration _seconds(double seconds) => Duration(milliseconds: (seconds * 1000).round());

  // ── Text and stickers ─────────────────────────────────────────────────

  Future<void> _addText() async {
    final typed = await showOverlayTextEditor(context);
    if (typed == null || typed.removed || !mounted) return;
    setState(() => _items = [
          ..._items,
          OverlayItem(
            id: _nextItemId++,
            kind: OverlayKind.text,
            text: typed.text,
            colour: typed.colour,
            boxed: typed.boxed,
            font: typed.font,
            y: 0.4,
          ),
        ]);
  }

  Future<void> _editText(OverlayItem item) async {
    final typed = await showOverlayTextEditor(context, editing: item);
    if (typed == null || !mounted) return;
    setState(() {
      _items = [
        for (final i in _items)
          if (i.id != item.id)
            i
          else if (!typed.removed)
            i.copyWith(text: typed.text, colour: typed.colour, boxed: typed.boxed, font: typed.font),
      ];
      if (typed.removed) _selectedId = null;
    });
  }

  Future<void> _addSticker() async {
    final sticker = await showStickerPicker(context);
    if (sticker == null || !mounted) return;
    await _stickers.load(sticker);
    if (!mounted) return;
    final nudge = (_nextItemId % 5 - 2) * 0.06;
    setState(() => _items = [
          ..._items,
          OverlayItem(
            id: _nextItemId++,
            kind: OverlayKind.sticker,
            text: sticker,
            x: 0.5 + nudge,
            y: 0.5 + nudge,
          ),
        ]);
  }

  void _delete(OverlayItem item) => setState(() {
        _items = _items.where((i) => i.id != item.id).toList();
        _selectedId = null;
      });

  // ── Next ──────────────────────────────────────────────────────────────

  Future<void> _continue() async {
    final picture = _picture;
    if (picture == null || _busy) return;
    setState(() {
      _busy = true;
      _selectedId = null;
      _musicOpen = false;
    });
    await _musicPlayer?.pause();
    try {
      final result = await _result(picture);
      if (!mounted) return;
      final shared = await widget.onNext(context, result);
      if (!mounted) return;
      if (shared == true) {
        Navigator.of(context).pop(true);
        return;
      }
      await _musicPlayer?.play();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<PhotoEditResult> _result(ui.Image picture) async {
    final music = _music;
    final changed = _filter != null || _items.isNotEmpty || music != null;
    if (!changed) {
      return PhotoEditResult(file: widget.file, contentType: widget.contentType, aspectRatio: _aspectRatio);
    }
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final dir = Directory.systemTemp.path;
    final base = File('$dir/story_photo_$stamp.png');
    // Written in one go: a few MB at most, and nothing else runs meanwhile.
    base.writeAsBytesSync(await widget.encodePng(picture), flush: true);

    final layers = <OverlayLayer>[];
    if (_items.isNotEmpty) {
      final frame = overlayFrameFor(_aspectRatio);
      final file = File('$dir/story_overlay_${stamp}_0.png');
      file.writeAsBytesSync(await renderOverlayPng(_items, _stickers, frame), flush: true);
      layers.add(OverlayLayer(
        path: file.path,
        texts: [for (final item in _items) if (item.kind == OverlayKind.text) item.text],
      ));
    }
    return PhotoEditResult(
      file: base,
      contentType: 'image/png',
      aspectRatio: _aspectRatio,
      edit: VideoEdit(filter: _filter, overlays: layers, music: music),
      photoSeconds: music == null ? null : _photoSeconds,
    );
  }

  // ── Layout ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final picture = _picture;
    final music = _music;
    final selected = _selected;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (picture != null)
            Center(
              child: AspectRatio(
                aspectRatio: _aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FilteredView(
                      filter: _filter,
                      child: RawImage(key: const Key('photo_editor_picture'), image: picture, fit: BoxFit.fill),
                    ),
                    OverlayEditor(
                      items: _items,
                      stickers: _stickers,
                      selectedId: _selectedId,
                      onChanged: (items) => setState(() => _items = items),
                      onSelect: (item) => setState(() => _selectedId = item?.id),
                      onEditText: _editText,
                      onTapEmpty: () => setState(() => _selectedId = null),
                      onDragging: (dragging) => setState(() => _dragging = dragging),
                    ),
                  ],
                ),
              ),
            )
          else if (_failed)
            Center(
              child: Text('This photo could not be opened', style: work(size: 13, color: NowaColors.dim)),
            )
          else
            const LoadingView(),
          Positioned(
            left: 14,
            top: top + 10,
            child: GestureDetector(
              key: const Key('photo_editor_back'),
              onTap: () => Navigator.of(context).pop(),
              child: Glass(
                radius: 12,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.arrow_back, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          if (picture != null && !_dragging)
            Positioned(
              right: 14,
              top: top + 10,
              child: OverlayTools(onText: _addText, onSticker: _addSticker, onSound: _pickMusic),
            ),
          if (music?.track != null && !_dragging)
            Positioned(
              top: top + 14,
              left: 64,
              right: 64,
              child: Center(
                child: GestureDetector(
                  key: const Key('photo_music_chip'),
                  onTap: () => setState(() {
                    _musicOpen = !_musicOpen;
                    _selectedId = null;
                  }),
                  child: Glass(
                    radius: 999,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_note, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${music!.track!.title} · ${music.track!.artist}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: sora(size: 12, weight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!_dragging && picture != null)
            Positioned(
              left: 18,
              right: 18,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: _musicOpen && music != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LengthPicker(
                          seconds: _photoSeconds,
                          onChanged: (seconds) => setState(() => _photoSeconds = seconds),
                        ),
                        const SizedBox(height: 10),
                        MusicPanel(
                          key: const Key('music_panel'),
                          music: music,
                          videoSeconds: _photoSeconds,
                          hasOriginalSound: false,
                          onChanged: _setMusic,
                          onChange: _pickMusic,
                          onRemove: _removeMusic,
                          onDone: () => setState(() => _musicOpen = false),
                        ),
                      ],
                    )
                  : selected != null
                      ? _ItemPanel(
                          item: selected,
                          onEdit: () => _editText(selected),
                          onDelete: () => _delete(selected),
                          onDone: () => setState(() => _selectedId = null),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilterPicker(
                              value: _filter,
                              showIntensity: true,
                              onChanged: (filter) => setState(() => _filter = filter),
                            ),
                            const SizedBox(height: 16),
                            NowaButton(
                              key: const Key('photo_editor_continue'),
                              label: _busy ? 'Preparing…' : 'Continue',
                              onTap: _busy ? null : _continue,
                            ),
                          ],
                        ),
            ),
        ],
      ),
    );
  }
}

/// [picture] as a PNG, at most 1080 wide: decoding has already turned it
/// upright, which the server's decoder would not do from the camera's tag.
Future<List<int>> uprightPng(ui.Image picture) async {
  final scale = math.min(1.0, 1080 / picture.width);
  final width = math.max(2, (picture.width * scale).round() ~/ 2 * 2);
  final height = math.max(2, (picture.height * scale).round() ~/ 2 * 2);
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    picture,
    Rect.fromLTWH(0, 0, picture.width.toDouble(), picture.height.toDouble()),
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..filterQuality = FilterQuality.high,
  );
  final drawn = recorder.endRecording();
  final image = await drawn.toImage(width, height);
  drawn.dispose();
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

class _LengthPicker extends StatelessWidget {
  const _LengthPicker({required this.seconds, required this.onChanged});

  final double seconds;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final option in photoLengths) ...[
              if (option != photoLengths.first) const SizedBox(width: 6),
              Chip2(
                key: Key('photo_length_${option.round()}'),
                label: '${option.round()}s',
                active: option == seconds,
                expand: true,
                onTap: () => onChanged(option),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A chosen item's actions. No timing: a photo has no timeline to set it on.
class _ItemPanel extends StatelessWidget {
  const _ItemPanel({required this.item, required this.onEdit, required this.onDelete, required this.onDone});

  final OverlayItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      child: Row(
        children: [
          if (item.kind == OverlayKind.text)
            TextButton.icon(
              key: const Key('photo_item_edit'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
              label: Text('Edit', style: sora(size: 12.5, color: Colors.white)),
            ),
          TextButton.icon(
            key: const Key('photo_item_delete'),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
            label: Text('Delete', style: sora(size: 12.5, color: Colors.white)),
          ),
          const Spacer(),
          TextButton(
            key: const Key('photo_item_done'),
            onPressed: onDone,
            child: Text('Done', style: sora(size: 12.5, weight: FontWeight.w600, color: NowaColors.accent)),
          ),
        ],
      ),
    );
  }
}
