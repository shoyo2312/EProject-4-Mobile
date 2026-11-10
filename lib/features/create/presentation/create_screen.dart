import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/core/widgets/nowa_toast.dart';
import 'package:tiktok_mobile/features/create/data/recording_session.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/create/data/video_filters.dart';
import 'package:tiktok_mobile/features/create/presentation/upload_provider.dart';
import 'package:tiktok_mobile/features/create/presentation/video_preview_screen.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/filter_picker.dart';
import 'package:tiktok_mobile/features/story/data/story_repository.dart';
import 'package:tiktok_mobile/features/story/presentation/story_flow.dart';
import 'package:tiktok_mobile/features/story/presentation/story_provider.dart';
import 'package:tiktok_mobile/features/story/presentation/story_media_picker.dart';

/// Clip-length options and the most the finished video may play for.
const _lengths = {
  '15s': Duration(seconds: 15),
  '60s': Duration(seconds: 60),
  '3m': Duration(minutes: 3),
};

/// The hands-free countdowns the timer cycles through; 0 is off.
const _timerOptions = [0, 3, 10];

/// The camera screen, wired to video-service's three-step publish: ticket,
/// PUT to storage, create the record (video doc 3.1/3.2).
///
/// In Post mode the camera runs in the app: tap or hold the shutter to record
/// a clip, again for the next one, with a speed and a countdown per clip. The
/// recorder pauses between clips rather than stopping, so every clip lands in
/// one file; speeds and deleted clips become the edit the server cuts that
/// file with ([RecordingSession.toEdit]). The gallery tile still picks an
/// existing clip, and Story mode still goes through the system picker.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({
    super.key,
    required this.onClose,
    required this.onPosted,
    this.visible = true,
    this.picker,
    this.findCameras = availableCameras,
  });

  final VoidCallback onClose;

  /// Called once a post is up. The camera is the wrong place to land after
  /// posting — the video belongs to the profile grid, so the shell switches
  /// there instead.
  final VoidCallback onPosted;

  /// The shell keeps this tab mounted behind the others, so it has to be told
  /// when it is off screen: the camera is released then, or its light stays
  /// on and no other app can open it.
  final bool visible;

  /// Injected in tests; the real screen opens the system picker.
  final ImagePicker? picker;

  /// Injected in tests, where there is no camera plugin to ask.
  final Future<List<CameraDescription>> Function() findCameras;

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen>
    with WidgetsBindingObserver {
  String _len = '60s';
  Duration get _maxLength => _lengths[_len]!;

  /// 'Post' publishes a video to the profile; 'Story' shares a photo or a
  /// clip that disappears 24 hours after it is approved.
  String _mode = 'Post';
  bool get _storyMode => _mode == 'Story';

  List<CameraDescription> _cameras = const [];
  var _cameraIndex = 0;
  CameraController? _camera;
  String? _cameraError;

  /// Whether the camera should be open at all; checked again after every
  /// await in [_openCamera], since the tab can be left while it opens.
  var _wantCamera = false;
  var _opening = false;

  var _flash = false;
  var _speed = 1.0;
  var _showSpeeds = false;

  /// The colour previewed on the camera and carried into the editor, where
  /// it can still be changed. One filter for the whole video.
  EditFilter? _filter;
  var _showFilters = false;

  var _timer = 0;
  int? _countdown;
  Timer? _countdownTicker;

  var _session = const RecordingSession();

  /// The recorder has been started and not yet stopped: the file is open,
  /// whether a clip is being shot right now or not.
  var _started = false;
  var _recording = false;

  /// A camera call is in flight; the shutter ignores taps until it lands.
  var _busy = false;
  final _clipWatch = Stopwatch();
  Timer? _clipTicker;

  late final ImagePicker _picker = widget.picker ?? ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.visible) _openCamera();
  }

  @override
  void didUpdateWidget(CreateScreen old) {
    super.didUpdateWidget(old);
    if (widget.visible == old.visible) return;
    widget.visible ? _openCamera() : _releaseCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Another app may want the camera while this one is in the background,
    // and the OS takes it away anyway. Not on `inactive`: that is also the
    // notification shade or a permission dialog, and would end a recording.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _releaseCamera();
    } else if (state == AppLifecycleState.resumed && widget.visible) {
      _openCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTicker?.cancel();
    _clipTicker?.cancel();
    _wantCamera = false;
    _camera?.dispose();
    super.dispose();
  }

  // ── Camera ────────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    _wantCamera = true;
    if (_camera != null || _opening) return;
    _opening = true;
    try {
      if (_cameras.isEmpty) _cameras = await widget.findCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'No camera on this device');
        return;
      }
      final controller = CameraController(
        _cameras[_cameraIndex % _cameras.length],
        // 720p: the server caps every video there, so more is only a bigger
        // upload for the same result.
        ResolutionPreset.high,
      );
      await controller.initialize();
      if (!mounted || !_wantCamera) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraError = null;
        _flash = false;
      });
    } on CameraException catch (e) {
      if (mounted) setState(() => _cameraError = _cameraMessage(e));
    } catch (_) {
      // No camera plugin at all — a test, or a platform without one.
      if (mounted) {
        setState(() => _cameraError = 'The camera could not be opened');
      }
    } finally {
      _opening = false;
    }
  }

  /// Leaving mid-recording throws the recording away: the file cannot be
  /// held open while another app has the camera.
  Future<void> _releaseCamera() async {
    _wantCamera = false;
    _cancelCountdown();
    final camera = _camera;
    if (camera == null) return;
    if (_started) await _discardRecording();
    if (mounted) setState(() => _camera = null);
    await camera.dispose();
  }

  String _cameraMessage(CameraException e) => switch (e.code) {
    'CameraAccessDenied' ||
    'CameraAccessDeniedWithoutPrompt' ||
    'CameraAccessRestricted' => 'Allow camera access in Settings to record',
    'AudioAccessDenied' ||
    'AudioAccessDeniedWithoutPrompt' ||
    'AudioAccessRestricted' => 'Allow microphone access in Settings to record',
    _ => 'The camera could not be opened',
  };

  Future<void> _flip() async {
    if (_cameras.length < 2 || _busy) return;
    // One file per recording, and a camera switch would need a second one.
    if (_started) {
      _toast('Flip the camera before you start recording', ToastKind.info);
      return;
    }
    _cameraIndex++;
    await _releaseCamera();
    if (widget.visible) await _openCamera();
  }

  Future<void> _toggleFlash() async {
    final camera = _camera;
    if (camera == null) return;
    final on = !_flash;
    try {
      await camera.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flash = on);
    } on CameraException {
      _toast('This camera has no flash', ToastKind.info);
    }
  }

  // ── Recording ─────────────────────────────────────────────────────────

  Duration get _played =>
      _session.played +
      (_recording
          ? Duration(
              microseconds: (_clipWatch.elapsed.inMicroseconds / _speed)
                  .round(),
            )
          : Duration.zero);

  bool get _canRecord =>
      _camera != null &&
      !_busy &&
      !ref.read(uploadNotifierProvider).busy &&
      _played < _maxLength;

  Future<void> _onShutterTap() async {
    if (_storyMode) return _storyPhoto();
    if (_countdown != null) return _cancelCountdown();
    if (_recording) return _pauseClip();
    if (_timer > 0) return _startCountdown();
    return _startClip();
  }

  void _startCountdown() {
    if (!_canRecord) return;
    setState(() => _countdown = _timer);
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (ticker) {
      final left = (_countdown ?? 1) - 1;
      if (left <= 0) {
        ticker.cancel();
        setState(() => _countdown = null);
        _startClip();
      } else {
        setState(() => _countdown = left);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTicker?.cancel();
    _countdownTicker = null;
    if (_countdown != null && mounted) setState(() => _countdown = null);
  }

  Future<void> _startClip() async {
    final camera = _camera;
    if (camera == null || !_canRecord) return;
    _busy = true;
    try {
      if (_started) {
        await camera.resumeVideoRecording();
      } else {
        await camera.startVideoRecording();
        _started = true;
      }
      _clipWatch
        ..reset()
        ..start();
      setState(() {
        _recording = true;
        _showSpeeds = false;
        _showFilters = false;
      });
      _clipTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!mounted) return;
        if (_played >= _maxLength) {
          _pauseClip(thenFinish: true);
        } else {
          setState(() {});
        }
      });
    } on CameraException catch (e) {
      _toast(e.description ?? 'Recording could not start');
    } finally {
      _busy = false;
    }
  }

  Future<void> _pauseClip({bool thenFinish = false}) async {
    final camera = _camera;
    if (camera == null || !_recording || _busy) return;
    _busy = true;
    _clipTicker?.cancel();
    try {
      await camera.pauseVideoRecording();
    } on CameraException {
      // The clip so far is still in the file; stopping below keeps it.
    }
    _clipWatch.stop();
    if (mounted) {
      setState(() {
        _session = _session.add(
          RecordedClip(length: _clipWatch.elapsed, speed: _speed),
        );
        _recording = false;
      });
    }
    _busy = false;
    if (thenFinish) await _finish();
  }

  void _discardLastClip() {
    if (_recording || _busy) return;
    setState(() => _session = _session.discardLast());
  }

  /// Stops the recorder and opens the editor with what was shot.
  Future<void> _finish() async {
    if (_recording) await _pauseClip();
    final camera = _camera;
    if (camera == null || !_started || _session.isEmpty || _busy) return;
    _busy = true;
    final XFile recorded;
    try {
      recorded = await camera.stopVideoRecording();
    } on CameraException catch (e) {
      _busy = false;
      _toast(e.description ?? 'The recording could not be saved');
      _resetRecording();
      return;
    }
    final cut = _session.toEdit();
    final edit = _withPicks(cut);
    _resetRecording();
    _busy = false;
    await _review(File(recorded.path), edit);
  }

  Future<void> _discardRecording() async {
    final camera = _camera;
    _clipTicker?.cancel();
    if (camera != null && _started) {
      try {
        final file = await camera.stopVideoRecording();
        await File(file.path).delete();
      } catch (_) {
        // Nothing to keep either way.
      }
    }
    _resetRecording();
  }

  void _resetRecording() {
    _clipTicker?.cancel();
    _clipWatch
      ..stop()
      ..reset();
    _started = false;
    _recording = false;
    if (mounted) setState(() => _session = const RecordingSession());
  }

  // ── Leaving for another screen ────────────────────────────────────────

  /// The editor, then details. The camera is closed meanwhile — the preview
  /// plays a video, and the details screen runs the upload.
  Future<void> _review(File file, VideoEdit? edit) async {
    await _releaseCamera();
    if (!mounted) return;
    final posted = await showVideoPreview(context, file: file, edit: edit);
    if (!mounted) return;
    if (widget.visible) _openCamera();
    if (posted == true) widget.onPosted();
  }

  // ── Story ─────────────────────────────────────────────────────────────

  /// A story clip being recorded with the hold, stopped on release or at 60s.
  var _storyRecording = false;

  /// In story mode the shutter takes a photo on this screen's camera, and
  /// holding it records a clip; either goes straight to the editor.
  Future<void> _storyPhoto() async {
    final camera = _camera;
    if (camera == null ||
        _busy ||
        _storyRecording ||
        ref.read(uploadNotifierProvider).busy) {
      return;
    }
    _busy = true;
    final XFile shot;
    try {
      shot = await camera.takePicture();
    } on CameraException catch (e) {
      _toast(e.description ?? 'The photo could not be taken');
      return;
    } finally {
      _busy = false;
    }
    await _storyEdit(File(shot.path), 'image/jpeg');
  }

  Future<void> _storyStartVideo() async {
    final camera = _camera;
    if (camera == null ||
        _busy ||
        _storyRecording ||
        ref.read(uploadNotifierProvider).busy) {
      return;
    }
    _busy = true;
    try {
      await camera.startVideoRecording();
      _storyRecording = true;
      _clipWatch
        ..reset()
        ..start();
      setState(() => _recording = true);
      _clipTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!mounted) return;
        if (_clipWatch.elapsed >= storyVideoMaxDuration) {
          _storyStopVideo();
        } else {
          setState(() {});
        }
      });
    } on CameraException catch (e) {
      _toast(e.description ?? 'Recording could not start');
    } finally {
      _busy = false;
    }
  }

  Future<void> _storyStopVideo() async {
    final camera = _camera;
    if (camera == null || !_storyRecording) return;
    _storyRecording = false;
    _clipTicker?.cancel();
    _clipWatch.stop();
    setState(() => _recording = false);
    final XFile clip;
    try {
      clip = await camera.stopVideoRecording();
    } on CameraException catch (e) {
      _toast(e.description ?? 'The recording could not be saved');
      return;
    }
    // A tap that was read as a hold: too short to be a story, take a photo.
    if (_clipWatch.elapsed < const Duration(milliseconds: 500)) {
      unawaited(File(clip.path).delete().catchError((_) => File(clip.path)));
      return _storyPhoto();
    }
    await _storyEdit(
      File(clip.path),
      storyContentTypeForPath(clip.path) ?? 'video/mp4',
    );
  }

  /// The editor and then the composer. The camera is closed meanwhile; back
  /// to the feed once shared.
  Future<void> _storyEdit(File file, String contentType) async {
    await _releaseCamera();
    if (!mounted) return;
    final posted = await startStoryFlowWithDraft(
      context,
      StoryDraft(file: file, contentType: contentType),
    );
    if (!mounted) return;
    if (posted) {
      widget.onClose();
    } else if (widget.visible) {
      _openCamera();
    }
  }

  /// The gallery tile in story mode: a photo or a clip, through the system
  /// picker. Back to the feed once shared.
  Future<void> _story(StoryMediaSource source) async {
    await _releaseCamera();
    if (!mounted) return;
    final posted = await startStoryFlow(
      context,
      source: source,
      picker: widget.picker,
    );
    if (!mounted) return;
    if (posted) {
      widget.onClose();
    } else if (widget.visible) {
      _openCamera();
    }
  }

  /// An existing clip from the gallery, into the same editor.
  Future<void> _pickFromGallery() async {
    if (ref.read(uploadNotifierProvider).busy || _started) return;

    final XFile? picked;
    try {
      picked = await _picker.pickVideo(source: ImageSource.gallery);
    } on PlatformException catch (e) {
      // A refused library permission arrives as an exception, not a null
      // file, and would otherwise take the whole screen down.
      if (mounted) _toast(e.message ?? 'The video could not be opened');
      return;
    }
    if (picked == null || !mounted) return;
    await _review(File(picked.path), _withPicks(null));
  }

  /// The filter chosen on the camera, added to what was shot.
  VideoEdit? _withPicks(VideoEdit? edit) {
    if (_filter == null) return edit;
    return (edit ?? const VideoEdit()).copyWith(filter: _filter);
  }

  /// How much of the length limit [d] uses, 0 to 1.
  double _fraction(Duration d) =>
      (d.inMilliseconds / _maxLength.inMilliseconds).clamp(0.0, 1.0);

  void _toast(String message, [ToastKind kind = ToastKind.error]) {
    if (!mounted) return;
    NowaToast.of(context).show(message, kind: kind);
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final upload = ref.watch(uploadNotifierProvider);
    final hasClips = !_session.isEmpty;
    final postTools = !_storyMode && !_recording;
    return Stack(
      fit: StackFit.expand,
      children: [
        _CameraView(
          camera: _camera,
          error: _cameraError,
          filter: _storyMode ? null : _filter,
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99060508),
                  Color(0x00060508),
                  Color(0x00060508),
                  Color(0xD9060508),
                ],
                stops: [0, 0.3, 0.6, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          top: top + 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                key: const Key('create_close_button'),
                onTap: () {
                  // A finished upload's banner should not still be there next
                  // time the tab is opened; one in flight keeps running.
                  if (!ref.read(uploadNotifierProvider).busy) {
                    ref.read(uploadNotifierProvider.notifier).reset();
                  }
                  widget.onClose();
                },
                child: Glass(
                  radius: 12,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        if (!_recording)
          Positioned(
            left: 14,
            top: top + 74,
            child: Column(
              children: [
                _Tool(
                  key: const Key('create_tool_flip'),
                  icon: Icons.flip_camera_ios_outlined,
                  label: 'Flip',
                  onTap: _flip,
                ),
                _Tool(
                  key: const Key('create_tool_flash'),
                  icon: _flash ? Icons.flash_on : Icons.flash_off,
                  label: 'Flash',
                  active: _flash,
                  onTap: _toggleFlash,
                ),
                if (!_storyMode) ...[
                  _Tool(
                    key: const Key('create_tool_speed'),
                    icon: Icons.speed,
                    label: _speed == 1 ? 'Speed' : _speedLabel(_speed),
                    active: _showSpeeds || _speed != 1,
                    onTap: () => setState(() {
                      _showSpeeds = !_showSpeeds;
                      _showFilters = false;
                    }),
                  ),
                  _Tool(
                    key: const Key('create_tool_filter'),
                    icon: Icons.auto_awesome_outlined,
                    label: filterById(_filter?.id)?.name ?? 'Filter',
                    active: _showFilters || _filter != null,
                    onTap: () => setState(() {
                      _showFilters = !_showFilters;
                      _showSpeeds = false;
                    }),
                  ),
                  _Tool(
                    key: const Key('create_tool_timer'),
                    icon: Icons.timer_outlined,
                    label: _timer == 0 ? 'Timer' : '${_timer}s',
                    active: _timer != 0,
                    onTap: () => setState(
                      () => _timer =
                          _timerOptions[(_timerOptions.indexOf(_timer) + 1) %
                              _timerOptions.length],
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (_countdown != null)
          Center(
            child: Text(
              '$_countdown',
              key: const Key('create_countdown'),
              style: sora(
                size: 96,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          // Clear of the shell's floating nav bar (60 tall, 12 off the bottom
          // inset), which is drawn over this tab — or the status line under
          // the shutter, where upload progress and errors show, is hidden.
          bottom: 84 + MediaQuery.of(context).padding.bottom,
          child: Column(
            children: [
              if (postTools && _showFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: FilterPicker(
                    value: _filter,
                    onChanged: (filter) => setState(() => _filter = filter),
                  ),
                ),
              if (postTools && _showSpeeds)
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
                  child: Glass(
                    radius: 14,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          for (final option in editorSpeeds) ...[
                            if (option != editorSpeeds.first)
                              const SizedBox(width: 6),
                            Chip2(
                              key: Key('create_speed_$option'),
                              label: _speedLabel(option),
                              active: option == _speed,
                              expand: true,
                              onTap: () => setState(() => _speed = option),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              // The length is fixed once recording starts: clips already shot
              // were measured against it.
              if (postTools && !_started)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final l in _lengths.keys)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _len = l),
                          child: Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: l == _len
                                  ? NowaColors.accent.withValues(alpha: 0.9)
                                  : const Color(0x73141218),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l,
                              style: sora(
                                size: 12,
                                weight: l == _len
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: l == _len
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              else
                const SizedBox(height: 30),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: _recording
                        ? null
                        : postTools && hasClips
                        ? GestureDetector(
                            key: const Key('create_discard_clip_button'),
                            onTap: _discardLastClip,
                            child: Glass(
                              radius: 14,
                              child: const Icon(
                                Icons.backspace_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : GestureDetector(
                            key: const Key('create_gallery_button'),
                            onTap: () => _storyMode
                                ? _story(StoryMediaSource.gallery)
                                : _pickFromGallery(),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.video_library_outlined,
                                size: 19,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 34),
                  GestureDetector(
                    key: const Key('create_record_button'),
                    onTap: _onShutterTap,
                    // Hold to record: the clip runs for as long as the finger
                    // stays down. In story mode holding records a story clip.
                    onLongPressStart: _storyMode
                        ? (_) => _storyStartVideo()
                        : (_) {
                            if (!_recording && _countdown == null) _startClip();
                          },
                    onLongPressEnd: _storyMode
                        ? (_) => _storyStopVideo()
                        : (_) {
                            if (_recording) _pauseClip();
                          },
                    child: _Shutter(
                      recording: _recording,
                      dimmed: upload.busy || _camera == null,
                      progress: _storyMode
                          ? (_storyRecording
                                ? (_clipWatch.elapsed.inMilliseconds /
                                          storyVideoMaxDuration.inMilliseconds)
                                      .clamp(0.0, 1.0)
                                : null)
                          : (_started || _recording)
                          ? _fraction(_played)
                          : null,
                      marks: [
                        for (final m in _session.playedMarks) _fraction(m),
                      ],
                    ),
                  ),
                  const SizedBox(width: 34),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: postTools && hasClips
                        ? GestureDetector(
                            key: const Key('create_done_button'),
                            onTap: _finish,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: NowaColors.accent,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final m in const ['Post', 'Story'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: GestureDetector(
                        key: Key('create_mode_${m.toLowerCase()}'),
                        // A recording in progress belongs to a post.
                        onTap: _started
                            ? null
                            : () => setState(() => _mode = m),
                        child: Text(
                          m,
                          style: sora(
                            size: 13.5,
                            color: m == _mode
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_storyMode)
                const SizedBox.shrink()
              else if (_started && upload.phase == UploadPhase.idle)
                Text(
                  '${_clock(_played)} / ${_clock(_maxLength)}',
                  key: const Key('create_record_time'),
                  style: sora(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                )
              else
                _UploadStatus(state: upload),
            ],
          ),
        ),
      ],
    );
  }

  static String _speedLabel(double speed) =>
      speed == speed.roundToDouble() ? '${speed.round()}x' : '${speed}x';

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// The live camera, filling the screen the way the recording will be framed;
/// the striped placeholder while it opens or when it cannot.
class _CameraView extends StatelessWidget {
  const _CameraView({required this.camera, required this.error, this.filter});

  final CameraController? camera;
  final String? error;

  /// Previewed only: the recording itself is uncoloured, and the server
  /// applies the filter from the edit.
  final EditFilter? filter;

  @override
  Widget build(BuildContext context) {
    final camera = this.camera;
    final size = camera?.value.previewSize;
    if (camera == null || !camera.value.isInitialized || size == null) {
      return StripedPlaceholder(label: error ?? 'camera preview', fontSize: 12);
    }
    // previewSize is reported in the sensor's landscape orientation; the
    // screen is portrait, so the sides swap.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: FilteredView(filter: filter, child: CameraPreview(camera)),
        ),
      ),
    );
  }
}

/// The record button. Once a recording has started, a ring round it fills
/// clockwise with how much of the length limit is used, with a tick where
/// each clip ends.
class _Shutter extends StatelessWidget {
  const _Shutter({
    required this.recording,
    required this.dimmed,
    this.progress,
    this.marks = const [],
  });

  final bool recording;
  final bool dimmed;

  /// 0 to 1 of the length limit; null before anything is recorded.
  final double? progress;

  /// Where each finished clip ends, 0 to 1.
  final List<double> marks;

  static const _size = 100.0;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (progress != null)
            Positioned.fill(
              child: CustomPaint(
                key: const Key('create_record_progress'),
                painter: _RingPainter(progress: progress, marks: marks),
              ),
            ),
          Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dimmed
                  ? NowaColors.accent.withValues(alpha: 0.35)
                  : NowaColors.accent,
              // The glow would sit under the ring; the ring says enough.
              boxShadow: progress != null
                  ? null
                  : [
                      BoxShadow(
                        color: NowaColors.accent.withValues(alpha: 0.25),
                        spreadRadius: 4,
                      ),
                    ],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: recording || dimmed ? 30 : 68,
              height: recording || dimmed ? 30 : 68,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  recording || dimmed ? 9 : 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.marks});

  final double progress;
  final List<double> marks;

  static const _stroke = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _stroke / 2;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    const top = -math.pi / 2;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    if (progress > 0) {
      canvas.drawArc(
        rect,
        top,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: 2 * math.pi,
            transform: const GradientRotation(top),
            colors: const [
              NowaColors.accent,
              NowaColors.supportInk,
              NowaColors.accent,
            ],
          ).createShader(rect),
      );
    }
    final tick = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5;
    for (final mark in marks) {
      final angle = top + 2 * math.pi * mark;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        centre + dir * (radius - _stroke / 2),
        centre + dir * (radius + _stroke / 2),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || !listEquals(old.marks, marks);
}

/// One button of the left-hand rail.
class _Tool extends StatelessWidget {
  const _Tool({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Glass(
          radius: 15,
          opacity: 0.45,
          child: SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: active ? NowaColors.supportInk : Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: sora(
                      size: 9.5,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one line under the shutter: what the upload is doing, or the hint when
/// nothing is in flight.
class _UploadStatus extends StatelessWidget {
  const _UploadStatus({required this.state});

  final UploadState state;

  @override
  Widget build(BuildContext context) {
    // Nothing in flight: no line at all.
    if (state.phase == UploadPhase.idle) return const SizedBox.shrink();
    final (text, color) = switch (state.phase) {
      UploadPhase.uploading => (
        state.progress < 0
            ? 'Uploading…'
            : 'Uploading · ${(state.progress * 100).round()}%',
        NowaColors.accent,
      ),
      UploadPhase.publishing => ('Posting…', NowaColors.accent),
      // PROCESSING is not a wait the user has to sit through: the video is
      // saved, it just is not playable or on the feed until transcoding ends
      // (video doc 3.2).
      UploadPhase.processing => (
        'Processing — it will appear on your profile when ready',
        NowaColors.supportInk,
      ),
      UploadPhase.done => ('Posted', NowaColors.supportInk),
      UploadPhase.failed => (state.error ?? 'Upload failed', NowaColors.danger),
      UploadPhase.idle => ('', Colors.transparent),
    };

    return Column(
      children: [
        if (state.phase == UploadPhase.uploading)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 40, right: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                key: const Key('upload_progress'),
                value: state.progress < 0 ? null : state.progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                color: NowaColors.accent,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            text,
            key: const Key('upload_status_text'),
            textAlign: TextAlign.center,
            style: sora(size: 12, weight: FontWeight.w500, color: color),
          ),
        ),
      ],
    );
  }
}
