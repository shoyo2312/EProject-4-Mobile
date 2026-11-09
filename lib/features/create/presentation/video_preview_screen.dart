import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/create/data/overlay_item.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/create/presentation/post_details_screen.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/filter_picker.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/music_panel.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/music_picker.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/overlay_editor.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/overlay_painter.dart';
import 'package:video_player/video_player.dart';

/// Step 2 of the create flow: trim the clip and pick its speed before
/// committing to it. Resolves `true` once the post is up, `null` if the poster
/// backed out of either step.
///
/// [edit] is what the in-app camera already made of the recording — speeds
/// and deleted clips. A single segment stays editable; several are previewed
/// as they are and sent unchanged.
///
/// [onNext] replaces the post details as the step after this one — a story
/// goes to its own composer — and resolves the same way: true once shared.
Future<bool?> showVideoPreview(
  BuildContext context, {
  required File file,
  VideoEdit? edit,
  EditorNext? onNext,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => VideoPreviewScreen(file: file, initialEdit: edit, onNext: onNext),
    ),
  );
}

/// The step after the editor, handed what was made of the clip; true once
/// it is shared, anything else to come back to the editor.
typedef EditorNext = Future<bool?> Function(BuildContext context, VideoEdit? edit);

/// Reopens the same player from the details screen, purely to watch the clip
/// again as it will be posted — no controls, back is the only way out.
Future<void> showVideoReview(
  BuildContext context, {
  required File file,
  VideoEdit? edit,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => VideoPreviewScreen(
        file: file,
        collectDetails: false,
        initialEdit: edit,
      ),
    ),
  );
}

/// Shortest clip the trim handles can make. Anything shorter is a flicker.
const _minClip = Duration(seconds: 1);

/// Plays the local file — not [VideoPlayerWidget], which is network-only and
/// reports watch time to interaction-service. Nothing here is a watch.
///
/// The edits are only previewed: the player loops inside the trimmed range at
/// the chosen speed, and the upload stays the untouched recording. The server
/// cuts the stored video from it with the [VideoEdit] sent on publish.
class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.file,
    this.collectDetails = true,
    this.initialEdit,
    this.onNext,
  });

  final File file;

  /// In place of the post details; see [showVideoPreview].
  final EditorNext? onNext;

  /// False when the details screen reopens this to re-watch the clip: the
  /// details are already being filled in one route below, and the edit is
  /// already made, so the editing controls are hidden too.
  final bool collectDetails;

  /// The edit to preview with. One segment loads into the trim and speed
  /// controls; several — clips recorded at different speeds, or with one
  /// deleted — are played as they are and cannot be trimmed here.
  final VideoEdit? initialEdit;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late final VideoPlayerController _controller;
  var _ready = false;

  var _duration = Duration.zero;
  var _start = Duration.zero;
  var _end = Duration.zero;
  var _speed = 1.0;

  /// The colour over the whole video, editable in every mode.
  late EditFilter? _filter = widget.initialEdit?.filter;

  /// The text and stickers laid over the video, bottom first.
  var _items = <OverlayItem>[];
  var _nextItemId = 0;
  final _stickers = StickerImages();

  /// The item whose timing and actions are showing in place of the editor's.
  int? _selectedId;

  OverlayItem? get _selected => _items.where((i) => i.id == _selectedId).firstOrNull;

  /// Where the preview is on the edited video's clock, for showing each item
  /// only over its own stretch. Only followed while there are items to time.
  double? _playedAt;

  /// The layers made earlier, re-watched from the details screen.
  List<OverlayLayer> get _reviewLayers =>
      widget.collectDetails ? const [] : widget.initialEdit?.overlays ?? const [];

  /// An item is under the fingers: the controls step aside for the bin.
  var _dragging = false;

  /// Several segments from the camera: played as recorded, not editable.
  late final bool _locked = (widget.initialEdit?.segments.length ?? 0) > 1;

  /// The rate last handed to the player, so it is only set on a change.
  double? _playingSpeed;

  /// Set while a seek is in flight, so the position updates that arrive
  /// before it lands do not ask for the same seek again.
  var _seeking = false;

  /// The song under the video, and the player previewing it in step with
  /// the picture. The song plays on the edited clock at normal speed, as the
  /// server mixes it.
  late EditMusic? _music = widget.initialEdit?.music;
  VideoPlayerController? _musicPlayer;

  /// The song's controls are showing in place of the editor's.
  var _musicOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..setLooping(true)
      ..addListener(_followEdit)
      ..initialize().then((_) {
        if (!mounted) return;
        _duration = _controller.value.duration;
        _end = _duration;
        final segment = widget.initialEdit?.segments.firstOrNull;
        if (segment != null && !_locked) {
          _start = _seconds(segment.start);
          _end = _seconds(segment.end) < _duration ? _seconds(segment.end) : _duration;
          _speed = segment.speed;
        }
        setState(() => _ready = true);
        _controller.play();
        final music = _music;
        if (music != null) _loadMusic(music);
      });
  }

  @override
  void dispose() {
    _controller.removeListener(_followEdit);
    _controller.dispose();
    _musicPlayer?.dispose();
    _stickers.dispose();
    super.dispose();
  }

  static Duration _seconds(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  /// What playback follows: the camera's segments, or the trim and speed
  /// set here.
  VideoEdit get _playback => _locked
      ? widget.initialEdit!
      : VideoEdit.single(start: _start, end: _end, speed: _speed);

  /// The preview of an edit: playback jumps over what is cut — before the
  /// trim, between segments, past the end, or back at zero after the
  /// player's own loop — and each segment plays at its own speed.
  Future<void> _followEdit() async {
    if (!_ready || _seeking) return;
    _followClock();
    _followMusic();
    final at = _playback.playbackAt(_controller.value.position);
    if (at.speed != _playingSpeed) {
      _playingSpeed = at.speed;
      await _applySpeed(at.speed);
    }
    final jumpTo = at.jumpTo;
    if (jumpTo != null) {
      _seeking = true;
      await _controller.seekTo(jumpTo);
      _seeking = false;
    }
  }

  /// Moves [_playedAt] along with playback. A position in a cut keeps the
  /// last one — the preview is about to jump out of it anyway.
  void _followClock() {
    if (_items.isEmpty && _reviewLayers.isEmpty) return;
    final played = _playback.playedAt(_controller.value.position);
    if (played == null) return;
    final last = _playedAt;
    if (last == null || (played - last).abs() >= 0.05) setState(() => _playedAt = played);
  }

  /// Starts the preview of [music]'s song, replacing any other.
  Future<void> _loadMusic(EditMusic music) async {
    final track = music.track;
    final old = _musicPlayer;
    _musicPlayer = null;
    await old?.dispose();
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
    _applyLevels();
    _followMusic();
  }

  void _applyLevels() {
    final music = _music;
    _controller.setVolume(music?.originalVolume ?? 1);
    _musicPlayer?.setVolume(music?.volume ?? 0);
  }

  /// Keeps the song where the picture is: playing while it plays, at the
  /// song's start plus the edited clock, put back when it drifts.
  void _followMusic() {
    final player = _musicPlayer;
    final music = _music;
    if (player == null || music == null || !player.value.isInitialized) return;
    final played = _playback.playedAt(_controller.value.position);
    if (played == null) return;
    final target = Duration(milliseconds: ((music.start + played) * 1000).round());
    final ended = target >= player.value.duration;
    if (_controller.value.isPlaying && !ended) {
      if ((player.value.position - target).abs() > const Duration(milliseconds: 350)) {
        player.seekTo(target);
      }
      if (!player.value.isPlaying) player.play();
    } else if (player.value.isPlaying) {
      player.pause();
    }
  }

  Future<void> _pickMusic() async {
    _controller.pause();
    final track = await showMusicPicker(context);
    if (!mounted) return;
    if (track != null) {
      final music = EditMusic(
        trackId: track.id,
        track: track,
        // Kept across a change of song: they are how the poster wants it mixed.
        volume: _music?.volume ?? 1,
        originalVolume: _music?.originalVolume ?? 1,
      );
      setState(() {
        _music = music;
        _musicOpen = true;
        _selectedId = null;
      });
      await _loadMusic(music);
    }
    if (mounted) _controller.play();
  }

  void _setMusic(EditMusic music, {bool seek = false}) {
    setState(() => _music = music);
    _applyLevels();
    if (seek) {
      // The song's new start, heard against the video's first frame.
      _controller.seekTo(_playback.rawAt(0));
      _musicPlayer?.seekTo(Duration(milliseconds: (music.start * 1000).round()));
    }
  }

  Future<void> _removeMusic() async {
    setState(() {
      _music = null;
      _musicOpen = false;
    });
    final old = _musicPlayer;
    _musicPlayer = null;
    await old?.dispose();
    _applyLevels();
  }

  /// How long the edited video plays, in seconds: the range item timings
  /// are set in.
  double get _playedSeconds => _playback.playedWithin(_duration).inMilliseconds / 1000;

  /// Some platforms refuse rates their decoder cannot do; the preview then
  /// plays at normal speed, and the server still applies the chosen one.
  Future<void> _applySpeed(double speed) async {
    try {
      await _controller.setPlaybackSpeed(speed);
    } catch (_) {
      // Preview only — the edit sent on publish is what counts.
    }
  }

  void _onTrim(RangeValues values) {
    final start = Duration(milliseconds: values.start.round());
    final end = Duration(milliseconds: values.end.round());
    if (end - start < _minClip) return;
    final startMoved = start != _start;
    setState(() {
      _start = start;
      _end = end;
    });
    // Dragging the start handle shows the frame it lands on; dragging the end
    // handle leaves playback where it is until it reaches the new end.
    if (startMoved) _controller.seekTo(start);
  }

  void _onSpeed(double speed) => setState(() => _speed = speed);

  /// Null when nothing was changed, so an untouched clip is not re-encoded.
  /// A colour alone sends no segments: the whole clip at normal speed.
  VideoEdit? get _edit {
    // The song is whatever [_music] is now, added by the caller: one picked on
    // the camera may since have been removed here.
    if (_locked) return widget.initialEdit!.copyWith(filter: _filter, music: null);
    final trim = _playback;
    final trimmed = !trim.isUnchanged(_duration);
    if (!trimmed && _filter == null) return null;
    return VideoEdit(segments: trimmed ? trim.segments : const [], filter: _filter);
  }

  void _togglePlayback() => setState(() {
        _controller.value.isPlaying ? _controller.pause() : _controller.play();
      });

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

  void _setTiming(OverlayItem item, double? start, double? end, double movedTo) {
    setState(() {
      _items = [for (final i in _items) i.id == item.id ? i.copyWith(start: start, end: end) : i];
      _playedAt = movedTo;
    });
    // Shows the frame the moved end lands on, still, as the item will appear there.
    _controller.pause();
    _controller.seekTo(_playback.rawAt(movedTo));
  }

  void _delete(OverlayItem item) => setState(() {
        _items = _items.where((i) => i.id != item.id).toList();
        _selectedId = null;
      });

  Future<void> _addSticker() async {
    final sticker = await showStickerPicker(context);
    if (sticker == null || !mounted) return;
    // Decoded before it is placed: a canvas draws only what is already decoded.
    await _stickers.load(sticker);
    if (!mounted) return;
    // Each one lands a little off the last, so a second is not hidden under the first.
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

  /// The server composites at most this many layers (video doc 3.2).
  static const _maxLayers = 10;

  /// The items drawn at the size the server caps the video at, one PNG per
  /// layer, written where the upload can pick the files up.
  Future<List<OverlayLayer>> _renderLayers() async {
    final frame = overlayFrameFor(_controller.value.aspectRatio);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final layers = <OverlayLayer>[];
    for (final (i, items) in overlayLayers(_items).indexed) {
      final bytes = await renderOverlayPng(items, _stickers, frame);
      final file = File('${Directory.systemTemp.path}/overlay_${stamp}_$i.png');
      await file.writeAsBytes(bytes, flush: true);
      layers.add(OverlayLayer(
        path: file.path,
        start: items.first.start,
        end: items.first.end,
        texts: [for (final item in items) if (item.kind == OverlayKind.text) item.text],
      ));
    }
    return layers;
  }

  /// Playback is paused across the details screen: the clip looping under a
  /// keyboard is only noise, and its audio would keep running.
  Future<void> _continue() async {
    if (overlayLayers(_items).length > _maxLayers) {
      NowaToast.of(context).info(
        'Text and stickers can appear at up to $_maxLayers different times',
      );
      return;
    }
    setState(() {
      _selectedId = null;
      _musicOpen = false;
    });
    await _controller.pause();
    await _musicPlayer?.pause();
    if (!mounted) return;
    var edit = _edit;
    final music = _music;
    if (music != null) edit = (edit ?? const VideoEdit()).copyWith(music: music);
    if (_items.isNotEmpty) {
      final layers = await _renderLayers();
      if (!mounted) return;
      edit = (edit ?? const VideoEdit()).copyWith(overlays: layers);
    }
    if (!mounted) return;
    final next = widget.onNext;
    final Future<bool?> step = next != null
        ? next(context, edit)
        : showPostDetails(context, file: widget.file, edit: edit);
    final posted = await step;
    if (!mounted) return;
    if (posted != true) {
      await _controller.play();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final editing = widget.collectDetails && _ready && !_locked;
    final selected = widget.collectDetails ? _selected : null;
    final music = _music;
    final musicOpen = widget.collectDetails && _musicOpen && music != null;
    final playedAt = _playedAt;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            GestureDetector(
              key: const Key('preview_playback_toggle'),
              onTap: _togglePlayback,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FilteredView(
                        filter: _filter,
                        child: VideoPlayer(_controller),
                      ),
                      // Over the filter, not under it: the server lays the
                      // overlay on after the colour too.
                      if (widget.collectDetails)
                        OverlayEditor(
                          items: _items,
                          stickers: _stickers,
                          selectedId: _selectedId,
                          playedAt: playedAt,
                          onChanged: (items) => setState(() => _items = items),
                          onSelect: (item) => setState(() => _selectedId = item?.id),
                          onEditText: _editText,
                          onTapEmpty: _togglePlayback,
                          onDragging: (dragging) => setState(() => _dragging = dragging),
                        )
                      else
                        for (final (i, layer) in _reviewLayers.indexed)
                          if (playedAt == null ||
                              ((layer.start == null || playedAt >= layer.start!) &&
                                  (layer.end == null || playedAt <= layer.end!)))
                            Image.file(
                              File(layer.path),
                              key: Key('preview_overlay_image_$i'),
                              fit: BoxFit.fill,
                            ),
                    ],
                  ),
                ),
              ),
            )
          else
            const LoadingView(),
          if (_ready && !_controller.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, size: 56, color: Colors.white70),
            ),
          Positioned(
            left: 14,
            top: top + 10,
            child: GestureDetector(
              key: const Key('preview_back_button'),
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
          if (widget.collectDetails && _ready && !_dragging)
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
                  key: const Key('preview_music_chip'),
                  onTap: widget.collectDetails
                      ? () => setState(() {
                            _musicOpen = !_musicOpen;
                            _selectedId = null;
                          })
                      : null,
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
                          // Always in sight once a song is on: the clip's own
                          // sound off, so only the song is heard.
                          if (widget.collectDetails) ...[
                            const SizedBox(width: 6),
                            Container(width: 1, height: 14, color: Colors.white24),
                            const SizedBox(width: 2),
                            OriginalSoundToggle(
                              key: const Key('preview_original_mute'),
                              music: music,
                              onChanged: _setMusic,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Out of the way while an item is dragged, for the bin at the bottom.
          if (!_dragging)
          Positioned(
            left: 18,
            right: 18,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: musicOpen
                ? MusicPanel(
                    key: const Key('music_panel'),
                    music: music,
                    videoSeconds: _playedSeconds,
                    onChanged: _setMusic,
                    onChange: _pickMusic,
                    onRemove: _removeMusic,
                    onDone: () => setState(() => _musicOpen = false),
                  )
                : selected != null
                ? OverlayItemPanel(
                    key: const Key('overlay_item_panel'),
                    item: selected,
                    duration: _playedSeconds,
                    onTiming: (start, end, movedTo) => _setTiming(selected, start, end, movedTo),
                    onEdit: () => _editText(selected),
                    onDelete: () => _delete(selected),
                    onDone: () => setState(() => _selectedId = null),
                  )
                : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.collectDetails && _ready) ...[
                  FilterPicker(
                    value: _filter,
                    showIntensity: true,
                    onChanged: (filter) => setState(() => _filter = filter),
                  ),
                  const SizedBox(height: 10),
                ],
                if (editing) ...[
                  _SpeedPicker(speed: _speed, onChanged: _onSpeed),
                  const SizedBox(height: 14),
                  _TrimBar(
                    duration: _duration,
                    start: _start,
                    end: _end,
                    played: _edit?.playedWithin(_duration) ?? _duration,
                    onChanged: _onTrim,
                  ),
                ] else if (_ready && _locked)
                  Glass(
                    radius: 14,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '${widget.initialEdit!.segments.length} clips · '
                        '${_TrimBar._clock(widget.initialEdit!.playedWithin(_duration))}',
                        key: const Key('preview_clips_summary'),
                        textAlign: TextAlign.center,
                        style: sora(size: 12.5, weight: FontWeight.w600, color: NowaColors.text),
                      ),
                    ),
                  )
                else if (_ready)
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: NowaColors.accent,
                    ),
                  ),
                if (widget.collectDetails) ...[
                  const SizedBox(height: 16),
                  NowaButton(
                    key: const Key('preview_continue_button'),
                    label: 'Continue',
                    onTap: _ready ? _continue : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedPicker extends StatelessWidget {
  const _SpeedPicker({required this.speed, required this.onChanged});

  final double speed;
  final ValueChanged<double> onChanged;

  static String _label(double speed) =>
      speed == speed.roundToDouble() ? '${speed.round()}x' : '${speed}x';

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final option in editorSpeeds) ...[
              if (option != editorSpeeds.first) const SizedBox(width: 6),
              Chip2(
                key: Key('edit_speed_$option'),
                label: _label(option),
                active: option == speed,
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

class _TrimBar extends StatelessWidget {
  const _TrimBar({
    required this.duration,
    required this.start,
    required this.end,
    required this.played,
    required this.onChanged,
  });

  final Duration duration;
  final Duration start;
  final Duration end;

  /// How long the posted video will play, speed included.
  final Duration played;
  final ValueChanged<RangeValues> onChanged;

  static String _clock(Duration d) {
    final tenths = (d.inMilliseconds / 100).round();
    final minutes = tenths ~/ 600;
    final seconds = (tenths % 600) / 10;
    return '$minutes:${seconds.toStringAsFixed(1).padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final max = duration.inMilliseconds.toDouble();
    return Glass(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(_clock(start), style: sora(size: 11.5, color: NowaColors.dim)),
                const Spacer(),
                Text(
                  _clock(played),
                  key: const Key('edit_played_duration'),
                  style: sora(size: 12.5, weight: FontWeight.w600, color: NowaColors.text),
                ),
                const Spacer(),
                Text(_clock(end), style: sora(size: 11.5, color: NowaColors.dim)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: NowaColors.accent,
                inactiveTrackColor: NowaColors.hairline,
                thumbColor: NowaColors.text,
                overlayColor: NowaColors.accent.withValues(alpha: 0.2),
                rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: RangeSlider(
                key: const Key('edit_trim_slider'),
                min: 0,
                max: max <= 0 ? 1 : max,
                values: RangeValues(
                  start.inMilliseconds.toDouble().clamp(0, max),
                  end.inMilliseconds.toDouble().clamp(0, max),
                ),
                onChanged: max <= _minClip.inMilliseconds ? null : onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
