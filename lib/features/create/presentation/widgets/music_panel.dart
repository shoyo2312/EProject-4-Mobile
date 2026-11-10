import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/create/data/video_edit.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/music_picker.dart';

/// The chosen song's controls in place of the editor's: which part of it
/// plays, and how loud it and the video's own sound are.
class MusicPanel extends StatelessWidget {
  const MusicPanel({
    super.key,
    required this.music,
    required this.videoSeconds,
    required this.onChanged,
    required this.onChange,
    required this.onRemove,
    required this.onDone,
    this.hasOriginalSound = true,
  });

  final EditMusic music;

  /// False over a photo: there is no sound of its own to turn down.
  final bool hasOriginalSound;

  /// How long the edited video plays: the most of the song it can use.
  final double videoSeconds;

  /// A level or the start moved; [seek] is true once the start is let go of,
  /// so the preview can jump to it and play.
  final void Function(EditMusic music, {bool seek}) onChanged;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final track = music.track;
    final songSeconds = (track?.durationSeconds ?? 0).toDouble();
    final latestStart = songSeconds - videoSeconds;
    return Glass(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, size: 16, color: NowaColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    track == null ? 'Sound' : '${track.title} · ${track.artist}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sora(size: 12.5, weight: FontWeight.w600, color: NowaColors.text),
                  ),
                ),
              ],
            ),
            // Only when the song is longer than the video: otherwise all of it plays anyway.
            if (latestStart > 1)
              _Row(
                label: 'Start ${musicClock(music.start.round())}',
                child: Slider(
                  key: const Key('music_start_slider'),
                  min: 0,
                  max: latestStart,
                  value: music.start.clamp(0, latestStart),
                  activeColor: NowaColors.accent,
                  inactiveColor: NowaColors.hairline,
                  // The label follows the finger; the preview jumps there and
                  // plays once it lets go, so the new start can be heard.
                  onChanged: (v) => onChanged(music.copyWith(start: v)),
                  onChangeEnd: (v) => onChanged(music.copyWith(start: v), seek: true),
                ),
              ),
            if (hasOriginalSound)
              _Row(
                label: 'Original',
                trailing: OriginalSoundToggle(
                  key: const Key('music_original_mute'),
                  music: music,
                  onChanged: onChanged,
                ),
                child: Slider(
                  key: const Key('music_original_volume_slider'),
                  value: music.originalVolume,
                  activeColor: NowaColors.accent,
                  inactiveColor: NowaColors.hairline,
                  onChanged: (v) => onChanged(music.copyWith(originalVolume: v)),
                ),
              ),
            _Row(
              label: 'Sound',
              child: Slider(
                key: const Key('music_volume_slider'),
                value: music.volume,
                activeColor: NowaColors.accent,
                inactiveColor: NowaColors.hairline,
                onChanged: (v) => onChanged(music.copyWith(volume: v)),
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  key: const Key('music_change'),
                  onPressed: onChange,
                  icon: const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                  label: Text('Change', style: sora(size: 12.5, color: Colors.white)),
                ),
                TextButton.icon(
                  key: const Key('music_remove'),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 16, color: NowaColors.danger),
                  label: Text('Remove', style: sora(size: 12.5, color: NowaColors.danger)),
                ),
                const Spacer(),
                TextButton(
                  key: const Key('music_done'),
                  onPressed: onDone,
                  child: Text('Done', style: sora(size: 13, weight: FontWeight.w700, color: NowaColors.accent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The video's own sound off, or back on at full: what a slider dragged
/// all the way down does, in one tap. The server then mixes only the song.
EditMusic toggleOriginalSound(EditMusic music) =>
    music.copyWith(originalVolume: music.originalVolume > 0 ? 0 : 1);

/// A speaker that mutes or restores the video's own sound under the song.
class OriginalSoundToggle extends StatelessWidget {
  const OriginalSoundToggle({
    super.key,
    required this.music,
    required this.onChanged,
    this.size = 18,
  });

  final EditMusic music;
  final void Function(EditMusic music, {bool seek}) onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = music.originalVolume == 0;
    return Tooltip(
      message: muted ? 'Turn original sound on' : 'Turn original sound off',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(toggleOriginalSound(music)),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            muted ? Icons.volume_off : Icons.volume_up,
            size: size,
            color: muted ? NowaColors.danger : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child, this.trailing});

  final String label;
  final Widget child;
  final Widget? trailing;

  /// Kept on every row, filled or not, so all the sliders end at the same
  /// place — the speaker's width ([OriginalSoundToggle] at its default size).
  static const _trailingWidth = 26.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 74, child: Text(label, style: sora(size: 11, color: NowaColors.dim))),
        Expanded(child: child),
        SizedBox(width: _trailingWidth, child: Center(child: trailing)),
      ],
    );
  }
}
