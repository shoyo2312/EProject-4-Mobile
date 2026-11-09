import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';

/// The speeds the viewer can pick from.
const playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

/// `1x`, `1.5x`, `0.75x` — no trailing zeros.
String speedLabel(double speed) {
  final text = speed.toString();
  return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}x';
}

/// Opened by holding a video someone else posted. Answers the speed picked,
/// or null when the sheet is dismissed.
Future<double?> showPlaybackSpeedSheet(
  BuildContext context, {
  required double current,
}) {
  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: NowaColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        key: const Key('playback_speed_sheet'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, size: 20, color: NowaColors.text),
                const SizedBox(width: 10),
                Text('Playback speed', style: sora(size: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final speed in playbackSpeeds)
                  Chip2(
                    key: Key('playback_speed_${speedLabel(speed)}'),
                    label: speed == 1.0 ? 'Normal' : speedLabel(speed),
                    active: speed == current,
                    onTap: () => Navigator.of(sheetContext).pop(speed),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
